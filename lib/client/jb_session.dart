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
import 'package:path/path.dart' as p;

import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';
import 'package:jackbox_client/model/socketio.dart' as mt;

import 'package:jackbox_client/client/jb_game_handler.dart';
import 'package:jackbox_client/client/jb_drawful.dart';

Future<void> main() async {
  JackboxSession js = new JackboxSession();

  try {
    await js.joinRoom("TCDH", "name2");
  } catch (e) {
    print(e);
    return;
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

  SessionData meta;

  IOWebSocketChannel ws;
  StreamSubscription<dynamic> wsSub;
  GameHandler gameHandler;
  IsolateChannel<IntMsg> gameChannel;
  StreamSubscription<dynamic> gameChannelSub;

  JackboxSession() {
    this.meta = SessionData();

    this.meta.userID = _genUserID();
  }

  String _genUserID() {
    Uuid uuidg = Uuid();

    return uuidg.v4();
  }

  Future<void> joinRoom(String roomID, String name) async {
    try {
      this.meta.roomInfo = await _getRoomInfo(roomID);
    } catch (e) {
      // Failed to retrieve room information
      throw e;
    }

    this.meta.userName = name;

    // Map containing arguments to join a jackbox room
    Map<String, dynamic> msg = {
      'name': 'msg',
      'args': [
        {
          'type': 'Action',
          'action': 'JoinRoom',
          'appId': this.meta.roomInfo.appID,
          'roomId': this.meta.roomInfo.roomID,
          'userId': this.meta.userID,
          'joinType': this.meta.roomInfo.joinAs,
          'name': this.meta.userName,
          'options': {
            'roomcode': this.meta.roomInfo.roomID,
            'name': this.meta.userName,
          }
        }
      ]
    };

    String smsg = jsonEncode(msg);

    try {
      await _connectWS();
    } catch (e) {
      // Failed to initialize websocket
      throw e;
    }

    _sendWSMessage(mt.PrepareMessageOfType(mt.MSG, smsg));
  }

  Future<RoomInfo> _getRoomInfo(String roomID) async {
    var uri = new Uri.https(
        _roomBase, p.join(_roomPath, roomID), {"userId": this.meta.userID});

    var resp = await http.get(uri);

    if (resp.statusCode == 404) {
      return throw ("Failed to retrieve room information for code: " + roomID);
    }

    Map rmMap = jsonDecode(resp.body);
    RoomInfo rmInfo = RoomInfo.fromJson(rmMap);

    return Future.value(rmInfo);
  }

  void _setGameHandler(String appID) {
    Map<String, GameHandlerDef> handlerMap = {
      // Drawful 2
      '8511cbe0-dfff-4ea9-94e0-424daad072c3': (p, r) => DrawfulHandler(p, r),
    };

    if (!handlerMap.containsKey(appID)) {
      return;
    }

    ReceivePort port = new ReceivePort();
    this.gameHandler = handlerMap[appID](port.sendPort, this.meta);
    this.gameChannel = new IsolateChannel.connectReceive(port);

    this.gameChannelSub =
        this.gameChannel.stream.listen(_handleWSMessage, onDone: () {
      resetState();
    });
  }

  Future<void> _connectWS() async {
    _disconnectWS();

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
    this.wsSub = this.ws.stream.listen(_handleWSMessage, onDone: () {
      resetState();
    });
  }

  void _disconnectWS() {
    if (this.ws != null) {
      this.ws.sink.close(status.goingAway);
      this.ws = null;
    }
  }

  // Send the socket.io data type, Jackbox doesn't use any of the extra fields so the prefix is just 5:::
  void _sendWSMessage(String msg) {
    if (this.ws == null) {
      return;
    }

    this.ws.sink.add(mt.PrepareMessageOfType(mt.MSG, msg));
  }

  void _sendIntMessage(IntMsg msg) {
    gameChannel.sink.add(msg);
  }

  void _handlePing() {
    if (this.ws == null) {
      return;
    }

    this.ws.sink.add(mt.PrepareMessageOfType(mt.PONG, ''));
  }

  // handleWSMessage handles different kinds of Socket.io messages and forward relevant ones
  void _handleWSMessage(dynamic msg) {
    switch (mt.GetMessageType(msg)) {
      case mt.OPEN:
        break;
      case mt.PING:
        _handlePing();
        break;
      case mt.PONG:
        break;
      case mt.MSG:
        _sendIntMessage(IntJackboxMsg(msg: mt.GetMSGBody(msg)));
        //this.sc.add(mt.GetMSGBody(msg));
        break;
    }
  }

  // handleLobbyMessage updates our state for lobby related messages
  /*
  5:::{"name":"msg","args":
  [{"type":"Event","event":"RoomBlobChanged","roomId":"CWHA",
  "blob":{"isLocal":true,"lobbyState":"WaitingForMore","state":"Lobby","formattedActiveContentId":null,"activeContentId":null,"platformId":"FLASH","allPlayersHavePortraits":false,"analytics":
  [{"appversion":"0.0.0","screen":"drawful2-lobby","appid":"drawful2-flash","appname":"Drawful2"}]}}]}
  */
  bool _handleLobbyMessage(dynamic msg) {
    Map<String, dynamic> msgMap = jsonDecode(msg);

    if (!msgMap.containsKey("name") || msgMap["name"] != "msg" 
      || !msgMap.containsKey("args") || !msgMap["args"] is List) {
      // This message isn't formed how we expect, just throw it away and say we succeeded
      return true;
    }

    
  }

  // handleIntMessage handles incoming messages from the GameHandler
  void _handleIntMessage(IntMsg msg) {
    switch (msg.type) {
      case IntMsgType.SESSION:
        break;
      case IntMsgType.JACKBOX:
        _sendWSMessage((msg as IntJackboxMsg).msg);
        break;
      case IntMsgType.UI:
        break;
    }
  }

  void resetState() {
    if (this.wsSub != null) {
      this.wsSub.cancel();
      this.wsSub = null;
    }

    _disconnectWS();

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

    this.meta.clear();
    this.meta.userID = _genUserID();
  }
}
