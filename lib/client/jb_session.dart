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

void main() {
  ReceivePort port = new ReceivePort();
  IsolateChannel channel = new IsolateChannel.connectReceive(port);

  StreamSubscription sub = channel.stream.listen((event) {
    print(event);
  });

  JackboxSession jb = new JackboxSession(port.sendPort);

  channel.sink.add(SessionLoginState(name: 'test', roomCode: 'KHAS'));
}

/*
  Jackbox uses a version of socket.io from 2014 (0.9.17) so rather than try to
  interop with it using a modern library, I just pull out the bits I need by
  talking standard websockets and parsing their message format
*/
class JackboxSession {
  static final String _roomBase = 'ecast.jackboxgames.com';
  static final String _roomPath = '/room';

  static final String _wsBase = 'ecast.jackboxgames.com';
  static final int _wsBasePort = 38203;
  static final String _wsInfoPath = '/socket.io/1/';
  static final String _wsSocketPath = '/socket.io/1/websocket/';
  static final String _wsInfoRegex =
      r'([a-z0-9]{28}):60:60:websocket,flashsocket';

  SessionData meta;

  JackboxState currentState;

  IOWebSocketChannel _ws;
  StreamSubscription<dynamic> _wsSub;

  IsolateChannel<JackboxState> _blocChannel;
  StreamSubscription<JackboxState> _blocChannelSub;

  GameHandler _gameHandler;
  IsolateChannel<IntMsg> _gameChannel;
  StreamSubscription<IntMsg> _gameChannelSub;

  static Map<String, GameHandlerDef> _handlerMap = {
    // Drawful 2
    '8511cbe0-dfff-4ea9-94e0-424daad072c3': (p, r, s) =>
        DrawfulHandler(p, r, s),
  };

  JackboxSession(SendPort port) {
    currentState = SessionLoginState(name: '', roomCode: '');
    meta = SessionData();
    meta.userId = _genUserId();

    _blocChannel = new IsolateChannel.connectSend(port);
    _blocChannelSub = _blocChannel.stream.listen(_handleUIMessage, onDone: () {
      resetState();
    });

    _sendUIMessage(currentState);
  }

  String _genUserId() {
    Uuid uuidg = Uuid();

    return uuidg.v4();
  }

  Future<void> joinRoom(String roomId, String name) async {
    try {
      meta.roomInfo = await _getRoomInfo(roomId);
    } catch (e) {
      // Failed to retrieve room information
      throw e;
    }

    _setGameHandler(meta.roomInfo.appId);

    meta.userName = name;

    Outer msg = Outer(
      args: [
        ArgActionJoinRoom(
          appId: meta.roomInfo.appId,
          roomId: meta.roomInfo.roomId,
          userId: meta.userId,
          joinType: meta.roomInfo.joinAs,
          name: meta.userName,
          options: {
            'roomcode': meta.roomInfo.roomId,
            'name': meta.userName,
          }
        )
      ]
      );

    String smsg = jsonEncode(msg);

    try {
      await _connectWS();
    } catch (e) {
      // Failed to initialize websocket
      throw e;
    }

    _sendWSMessage(smsg);
  }

  Future<RoomInfo> _getRoomInfo(String roomId) async {
    var uri = new Uri.https(
        _roomBase, p.join(_roomPath, roomId), {'userId': meta.userId});

    var resp = await http.get(uri);

    if (resp.statusCode == 404) {
      return throw ('Failed to retrieve room information for code: ' + roomId);
    }

    Map rmMap = jsonDecode(resp.body);
    RoomInfo rmInfo = RoomInfo.fromJson(rmMap);

    return Future.value(rmInfo);
  }

  void _setGameHandler(String appId) {
    if (!_handlerMap.containsKey(appId)) {
      return;
    }

    ReceivePort port = new ReceivePort();
    _gameHandler = _handlerMap[appId](port.sendPort, meta, currentState);
    _gameChannel = new IsolateChannel.connectReceive(port);

    _gameChannelSub = _gameChannel.stream.listen(_handleIntMessage, onDone: () {
      resetState();
    });
  }

  Future<void> _connectWS() async {
    _disconnectWS();

    if (_gameHandler == null) {
      throw Exception(
          'No game handler found, game may not be implemented, refusing to connect');
    }

    var uri = new Uri(
        scheme: 'https', host: _wsBase, port: _wsBasePort, path: _wsInfoPath);

    var resp = await http.get(uri);

    if (resp.statusCode == 404) {
      throw Exception('Failed to retrieve websocket information');
    }

    RegExp exp = new RegExp(_wsInfoRegex);
    Match match = exp.firstMatch(resp.body);

    if (match == null || match.groupCount != 1) {
      throw Exception('Invalid response body');
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

    if (currentState is SessionLoginState) {
      // Check if this is a successful join room message
      Map<String, dynamic> jmsg = jsonDecode(msg);

      Outer msgp = Outer.fromJson(jmsg);

      for (ArgMsg argm in msgp.args) {
        if (argm is ArgResult) {
          if (argm.action == 'JoinRoom' && argm.success) {
            // Successfully joined room
            currentState = SessionLobbyState(allowedToStart: false, enoughPlayers: false);

            _sendIntMessage(IntSessionMsg(action: IntSessionAction.UPDATESTATE, 
              data: {'process': false, 'state': currentState}));
            _sendUIMessage(currentState);
          }
        }
      }
    } else {
      _sendIntMessage(IntJackboxMsg(msg: msg));
    }

    return;
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
      default:
      break;
    }
  }

  void _handleIntSessMessage(IntSessionMsg msg) {}

  void _handleIntJbMessage(IntJackboxMsg msg) {
    _sendWSMessage(msg.msg);
  }

  void _sendUIMessage(JackboxState state) {
    _blocChannel.sink.add(state);
  }

  // handleUIMessage handles IntUIMsg types from the UI frontend and BLoC modules
  void _handleUIMessage(JackboxState state) {
    bool process = false;
    currentState = state;

    if (state is SessionLoginState) {
      _handleSessionLoginMessage(state);
    } else if (_gameHandler.canHandleStateType(state)) {
      process = true;
    }

    _sendIntMessage(IntSessionMsg(action: IntSessionAction.UPDATESTATE, 
      data: {'process': process, 'state': state}));

    // Ignore everything we can't handle
  }

  void _handleSessionLoginMessage(SessionState state) {
    if (state is SessionLoginState) {
      // Malformed LoginState, just send it back as is
      if (state.roomCode == '' || state.name == '') {
        _sendUIMessage(state);
        return;
      }

      joinRoom(state.roomCode, state.name);
    }
  }

  void resetState() {
    _wsSub?.cancel();

    _disconnectWS();

    _gameChannelSub?.cancel();
    _gameChannel?.sink?.close();
    _gameHandler?.resetState();

    meta.clear();
    meta.userId = _genUserId();
  }
}
