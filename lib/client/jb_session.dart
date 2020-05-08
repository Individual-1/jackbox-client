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

  IOWebSocketChannel _ws;
  StreamSubscription<dynamic> _wsSub;

  IsolateChannel<JackboxState> _blocChannel;
  StreamSubscription<JackboxState> _blocChannelSub;

  GameHandler _gameHandler;
  IsolateChannel<IntMsg> _gameChannel;
  StreamSubscription<IntMsg> _gameChannelSub;

  JackboxSession(SendPort port) {
    _blocChannel = new IsolateChannel.connectSend(port);
    _blocChannelSub = _blocChannel.stream.listen(_handleUIMessage, onDone: () {
      resetState();
    });

    meta = SessionData();

    meta.userID = _genUserID();
  }

  String _genUserID() {
    Uuid uuidg = Uuid();

    return uuidg.v4();
  }

  Future<void> joinRoom(String roomID, String name) async {
    try {
      meta.roomInfo = await _getRoomInfo(roomID);
    } catch (e) {
      // Failed to retrieve room information
      throw e;
    }

    meta.userName = name;

    // Map containing arguments to join a jackbox room
    Map<String, dynamic> msg = {
      'name': 'msg',
      'args': [
        {
          'type': 'Action',
          'action': 'JoinRoom',
          'appId': meta.roomInfo.appID,
          'roomId': meta.roomInfo.roomID,
          'userId': meta.userID,
          'joinType': meta.roomInfo.joinAs,
          'name': meta.userName,
          'options': {
            'roomcode': meta.roomInfo.roomID,
            'name': meta.userName,
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
        _roomBase, p.join(_roomPath, roomID), {"userId": meta.userID});

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
    _gameHandler = handlerMap[appID](port.sendPort, meta);
    _gameChannel = new IsolateChannel.connectReceive(port);

    _gameChannelSub = _gameChannel.stream.listen(_handleIntMessage, onDone: () {
      resetState();
    });
  }

  Future<void> _connectWS() async {
    _disconnectWS();

    if (_gameHandler == null) {
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
      _ws = IOWebSocketChannel.connect(wssURI);
    } catch (e) {
      throw e;
    }

    // Set up message handler
    _wsSub = _ws.stream.listen(_handleWSMessage, onDone: () {
      resetState();
    });
  }

  void _disconnectWS() {
    if (_ws != null) {
      _ws.sink.close(status.goingAway);
      _ws = null;
    }
  }

  // Send the socket.io data type, Jackbox doesn't use any of the extra fields so the prefix is just 5:::
  void _sendWSMessage(String msg) {
    if (_ws == null) {
      return;
    }

    _ws.sink.add(mt.PrepareMessageOfType(mt.MSG, msg));
  }

  void _sendIntMessage(IntMsg msg) {
    _gameChannel.sink.add(msg);
  }

  void _handlePing() {
    if (_ws == null) {
      return;
    }

    _ws.sink.add(mt.PrepareMessageOfType(mt.PONG, ''));
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
        _handleWSJbMessage(mt.GetMSGBody(msg));
        //sc.add(mt.GetMSGBody(msg));
        break;
    }
  }

  void _handleWSJbMessage(dynamic msg) {
    // Here we need to handle messages relating to the lobby or joining a room

    // TODO: Actually handle messages
    _sendIntMessage(IntJackboxMsg(msg: msg));
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

    if (!msgMap.containsKey("name") ||
        msgMap["name"] != "msg" ||
        !msgMap.containsKey("args") ||
        !msgMap["args"] is List) {
      // This message isn't formed how we expect, just throw it away and say we succeeded
      return true;
    }
  }

  // handleIntMessage and its offshoots handle incoming messages from the GameHandler only
  void _handleIntMessage(IntMsg msg) {
    switch (msg.type) {
      case IntMsgType.SESSION:
        if (msg is IntSessionMsg) {
          _handleIntSessMessage(msg);
        }
        break;
      case IntMsgType.JACKBOX:
        if (msg is IntJackboxMsg) {
          _handleIntJbMessage(msg);
        }
        break;
      case IntMsgType.UI:
        if (msg is IntUIMsg) {
          _handleIntUIMessage(msg);
        }
        break;
    }
  }

  void _handleIntSessMessage(IntSessionMsg msg) {}

  void _handleIntJbMessage(IntJackboxMsg msg) {
    _sendWSMessage(msg.msg);
  }

  void _handleIntUIMessage(IntUIMsg msg) {}

  void _sendUIMessage(JackboxState state) {
    _blocChannel.sink.add(state);
  }

  // handleUIMessage handles IntUIMsg types from the UI frontend and BLoC modules
  void _handleUIMessage(JackboxState state) {
    if (state is SessionState) {
      _handleSessionUIMessage(state);
    } else if (_gameHandler.canHandleStateType(state)) {
      _sendIntMessage(IntUIMsg(state: state));
    }

    // Ignore everything we can't handle
  }

  void _handleSessionUIMessage(SessionState state) {
    if (state is SessionLoginState) {
      // Malformed LoginState, just send it back as is
      if (state.roomCode == "" || state.name == "") {
        _sendUIMessage(state);
        return;
      }

      joinRoom(state.roomCode, state.name);
    }
  }

  void resetState() {
    if (_wsSub != null) {
      _wsSub.cancel();
      _wsSub = null;
    }

    _disconnectWS();

    if (_gameChannelSub != null) {
      _gameChannelSub.cancel();
      _gameChannelSub = null;
    }

    if (_gameChannel != null) {
      _gameChannel.sink.close();
      _gameChannel = null;
    }

    if (_gameHandler != null) {
      _gameHandler.resetState();
      _gameHandler = null;
    }

    meta.clear();
    meta.userID = _genUserID();
  }
}
