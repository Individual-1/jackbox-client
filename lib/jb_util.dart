import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:path/path.dart' as p;

import 'package:json_annotation/json_annotation.dart';

import 'sio_msg_type.dart' as mt;

part 'jb_util.g.dart';

Future<void> main() async {
  JackboxSession js = new JackboxSession();

  try {
    await js.JoinRoom("AGII", "name");
  } catch (e) {
    print(e);
    return;
  }

  if (js.BroadcastAvailable()) {
    js.sc.stream.listen((msg) {
      print(msg);
    });
  }
}

/*
  Jackbox uses a version of socket.io from 2014 (0.9.17) so rather than try to
  interop with it using a modern library, I just pull out the bits I need by
  talking standard websockets and parsing their message format
*/
class JackboxSession {
  static final String _roomBase = "ecast.jackboxgames.com";
  static final String _roomPath = "/room";

  static final String _wsBase = "ecast.jackboxgames.com";
  static final int _wsBasePort = 38203;
  static final String _wsInfoPath = "/socket.io/1/";
  static final String _wsSocketPath = "/socket.io/1/websocket/";
  static final String _wsInfoRegex =
      r"([a-z0-9]{28}):60:60:websocket,flashsocket";

  String userID;

  IOWebSocketChannel ws = null;
  StreamController<dynamic> sc;
  StreamSubscription<dynamic> wsToSc = null;

  JackboxSession() {
    var uuidg = Uuid();

    this.userID = uuidg.v4();
    this.sc = StreamController<dynamic>();
  }

  Future<void> JoinRoom(String roomID, String name) async {
    RoomInfo rmInfo;

    try {
      rmInfo = await getRoomInfo(roomID);
    } catch (e) {
      // Failed to retrieve room information
      throw e;
    }

    // Map containing arguments to join a jackbox room
    Map<String, dynamic> msg = {
      'name': 'msg',
      'args': [
        {
          'type': 'Action',
          'action': 'JoinRoom',
          'appId': rmInfo.appID,
          'roomId': roomID,
          'userId': this.userID,
          'joinType': rmInfo.joinAs,
          'name': name,
          'options': {
            'roomcode': roomID,
            'name': name,
          }
        }
      ]
    };

    String smsg = jsonEncode(msg);

    try {
      await connectWS();
    } catch (e) {
      // Failed to initialize websocket
      throw e;
    }

    sendMessage(smsg);
  }

  Future<RoomInfo> getRoomInfo(String roomID) async {
    var uri = new Uri.https(
        _roomBase, p.join(_roomPath, roomID), {"userId": this.userID});

    var resp = await http.get(uri);

    if (resp.statusCode == 404) {
      return throw ("Failed to retrieve room information for code: " + roomID);
    }

    Map rmMap = jsonDecode(resp.body);
    RoomInfo rmInfo = RoomInfo.fromJson(rmMap);

    return Future.value(rmInfo);
  }

  Future<void> connectWS() async {
    disconnectWS();

    var uri = new Uri(
        scheme: 'https', host: _wsBase, port: _wsBasePort, path: _wsInfoPath);

    var resp = await http.get(uri);

    if (resp.statusCode == 404) {
      return throw ("Failed to retrieve websocket information");
    }

    RegExp exp = new RegExp(_wsInfoRegex);
    Match match = exp.firstMatch(resp.body);

    if (match == null || match.groupCount != 1) {
      return throw ("Invalid response body");
    }

    String sessionName = match.group(1);

    var wssURI = new Uri(
        scheme: 'wss',
        host: _wsBase,
        port: _wsBasePort,
        path: p.join(_wsSocketPath, sessionName));
    
    try {
      this.ws = IOWebSocketChannel.connect(wssURI);
    } catch (e) {
      throw e;
    }

    // Set up rebroadcast handler
    // TODO: clean exit by tearing down stream
    this.wsToSc = this.ws.stream.listen(handleMessages, onDone: () {
      this.wsToSc = null;
    });
  }

  void disconnectWS() {
    if (this.ws != null) {
      this.ws.sink.close(status.goingAway);
      this.ws = null;
    }
  }

  // Send the socket.io data type, Jackbox doesn't use any of the extra fields so the prefix is just 5:::
  void sendMessage(String msg) {
    if (this.ws == null) {
      return;
    }

    print('sending: ' + msg);
    this.ws.sink.add(mt.PrepareMessageOfType(mt.MSG, msg));
  }

  void handlePing() {
    if (this.ws == null) {
      return;
    }

    this.ws.sink.add(mt.PrepareMessageOfType(mt.PONG, ''));
  }

  // handleMessages subscribes to our sole websocket listener and broadcasts MSG types
  void handleMessages(dynamic msg) {
    switch (mt.GetMessageType(msg)) {
      case mt.OPEN:
        break;
      case mt.PING:
        handlePing();
        break;
      case mt.PONG:
        break;
      case mt.MSG:
        this.sc.add(mt.GetMSGBody(msg));
        break;
    }
  }

  bool BroadcastAvailable() {
    return this.wsToSc != null;
  }
  
}

@JsonSerializable()
class RoomInfo {
  @JsonKey(name: 'roomid', nullable: false)
  final String roomID;

  @JsonKey(name: 'server', nullable: false)
  final String server;

  @JsonKey(name: 'apptag', nullable: false)
  final String appTag;

  @JsonKey(name: 'appid', nullable: false)
  final String appID;

  @JsonKey(name: 'numAudience', nullable: false)
  final int numAudience;

  @JsonKey(name: 'joinAs', nullable: false)
  final String joinAs;

  @JsonKey(name: 'requiresPassword', nullable: false)
  final bool requiresPassword;

  RoomInfo(this.roomID, this.server, this.appTag, this.appID, this.numAudience,
      this.joinAs, this.requiresPassword);

  factory RoomInfo.fromJson(Map<String, dynamic> json) =>
      _$RoomInfoFromJson(json);

  Map<String, dynamic> toJson() => _$RoomInfoToJson(this);
}
