import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:stream_channel/isolate_channel.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:stream_channel/stream_channel.dart';
import 'package:path/path.dart' as p;

import 'jb_data.dart';
import 'sio_msg_type.dart' as mt;

import 'jb_game_handler.dart';
import 'jb_drawful.dart';

Future<void> main() async {
  JackboxSession js = new JackboxSession();

  try {
    await js.JoinRoom("TCDH", "name2");
  } catch (e) {
    print(e);
    return;
  }

  if (js.BroadcastAvailable()) {
    js.sc.stream.listen((msg) {
      print(msg);
    });
  }

  sleep(Duration(seconds: 5));
  String plJson = await new File('test.json').readAsString();
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
  String userName = "";
  RoomInfo roomInfo = null;

  IOWebSocketChannel ws = null;
  StreamController<dynamic> sc;
  StreamSubscription<dynamic> wsSub = null;
  GameHandler gameHandler = null;
  IsolateChannel<IntraMsg> gameChannel = null;
  StreamSubscription<dynamic> gameChannelSub = null;

  JackboxSession() {
    var uuidg = Uuid();

    this.userID = uuidg.v4();
    this.sc = StreamController<dynamic>();
  }

  Future<void> JoinRoom(String roomID, String name) async {
    try {
      this.roomInfo = await getRoomInfo(roomID);
    } catch (e) {
      // Failed to retrieve room information
      throw e;
    }

    this.userName = name;

    // Map containing arguments to join a jackbox room
    Map<String, dynamic> msg = {
      'name': 'msg',
      'args': [
        {
          'type': 'Action',
          'action': 'JoinRoom',
          'appId': this.roomInfo.appID,
          'roomId': this.roomInfo.roomID,
          'userId': this.userID,
          'joinType': this.roomInfo.joinAs,
          'name': this.userName,
          'options': {
            'roomcode': this.roomInfo.roomID,
            'name': this.userName,
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

    sendWSMessage(mt.PrepareMessageOfType(mt.MSG, smsg));
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

  void setGameHandler(String appID) {
    Map<String, GameHandlerDef> handlerMap = {
      'test': (p, r) => DrawfulHandler(p, r),
    };

    if (!handlerMap.containsKey(appID)) {
      return;
    }

    ReceivePort port = new ReceivePort();
    this.gameHandler = handlerMap[appID](port.sendPort, this.roomInfo);
    this.gameChannel = new IsolateChannel.connectReceive(port);

    this.gameChannelSub =
        this.gameChannel.stream.listen(handleWSMessage, onDone: () {
      resetState();
    });
  }

  Future<void> connectWS() async {
    disconnectWS();

    if (this.gameHandler == null) {
      throw Exception(
          "No game handler found, game may not be implemented, refusing to connect");
    }

    var uri = new Uri(
        scheme: 'https', host: _wsBase, port: _wsBasePort, path: _wsInfoPath);

    var resp = await http.get(uri);

    if (resp.statusCode == 404) {
      throw Exception("Failed to retrieve websocket information");
    }

    RegExp exp = new RegExp(_wsInfoRegex);
    Match match = exp.firstMatch(resp.body);

    if (match == null || match.groupCount != 1) {
      throw Exception("Invalid response body");
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

    // Set up message handler
    this.wsSub = this.ws.stream.listen(handleWSMessage, onDone: () {
      resetState();
    });
  }

  void disconnectWS() {
    if (this.ws != null) {
      this.ws.sink.close(status.goingAway);
      this.ws = null;
    }
  }

  // Send the socket.io data type, Jackbox doesn't use any of the extra fields so the prefix is just 5:::
  void sendWSMessage(String msg) {
    if (this.ws == null) {
      return;
    }

    print('sending: ' + msg);
    this.ws.sink.add(mt.PrepareMessageOfType(mt.MSG, msg));
  }

  void sendIntraMessage(IntraMsgType type, dynamic msg) {
    gameChannel.sink.add(IntraMsg(type: type, msg: msg));
  }

  void handlePing() {
    if (this.ws == null) {
      return;
    }

    this.ws.sink.add(mt.PrepareMessageOfType(mt.PONG, ''));
  }

  // handleWSMessage handles different kinds of Socket.io messages and forward relevant ones
  void handleWSMessage(dynamic msg) {
    switch (mt.GetMessageType(msg)) {
      case mt.OPEN:
        break;
      case mt.PING:
        handlePing();
        break;
      case mt.PONG:
        break;
      case mt.MSG:
        //this.sc.add(mt.GetMSGBody(msg));
        break;
    }
  }

  // handleIntraMessage handles incoming messages from the GameHandler
  void handleIntraMessage(IntraMsg msg) {
    switch (msg.type) {
      case IntraMsgType.SESSION:
      break;
      case IntraMsgType.JACKBOX:
      sendWSMessage(msg.msg);
      break;
      case IntraMsgType.UI:
      break;
    }
  }

  void resetState() {
    if (this.wsSub != null) {
      this.wsSub.cancel();
      this.wsSub = null;
    }

    if (this.ws != null) {
      this.ws.sink.close();
      this.ws = null;
    }

    if (this.gameChannelSub != null) {
      this.gameChannelSub.cancel();
      this.gameChannelSub = null;
    }

    if (this.gameChannel != null) {
      this.gameChannel.sink.close();
      this.gameChannel = null;
    }

    if (this.gameHandler != null) {
      this.gameHandler.resetState();
      this.gameHandler = null;
    }

    this.roomInfo = null;
    this.userName = "";
  }

  bool BroadcastAvailable() {
    return this.wsSub != null;
  }
}
