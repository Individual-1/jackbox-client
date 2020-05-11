import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:path/path.dart' as p;

import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';
import 'package:jackbox_client/model/socketio.dart' as mt;

import 'package:jackbox_client/client/jb_game_handler.dart';
import 'package:jackbox_client/client/jb_drawful.dart';

void main() {}

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

  // StreamController used to receive events from acting parties
  StreamController<JackboxEvent> _eventStream;
  StreamSubscription<JackboxEvent> _eventStreamSub;

  // StreamController used to send state information to listeners
  StreamController<JackboxState> _stateStream;

  GameHandler _gameHandler;

  static final Map<String, GameHandlerDef> _handledGames = {
    // Drawful 2
    '8511cbe0-dfff-4ea9-94e0-424daad072c3': () => DrawfulHandler(),
  };

  Map<Type, JackboxEventHandler> _handledEvents;
  Map<Type, JackboxStateHandler> _handledStates;

  JackboxSession() {
    _initHandlerMaps();
    _init();
  }

  void _init() {
    currentState = SessionLoginState();
    meta = SessionData();
    meta.userId = _genUserId();

    _eventStream = StreamController<JackboxEvent>();

    _eventStreamSub = _eventStream.stream.listen(_handleEvent, onDone: () {
      resetState();
    });

    _stateStream = StreamController<JackboxState>();

    // Buffer first event
    _sendState(currentState);
  }

  void _initHandlerMaps() {
    _handledEvents = {
      JackboxLoginEvent: (e, m) => _handleLogin(e),
    };

    _handledStates = {
      SessionLoginState: (m, s) => _handleSessionLoginState(m, s),
    };
  }

  void sendEvent(JackboxEvent event) {
    _eventStream?.sink?.add(event);
  }

  Stream stateStream() {
    return _stateStream.stream;
  }

  void _sendState(JackboxState state) {
    _stateStream?.sink?.add(state);
  }

  bool canHandleEvent(JackboxEvent event) {
    if (_handledEvents.containsKey(event.runtimeType)) {
      return true;
    } else {
      return false;
    }
  }

  void _handleEvent(JackboxEvent event) {

  }

  String _handleLogin(JackboxEvent event) {
    if (event is JackboxLoginEvent) {
      joinRoom(event.roomCode, event.name);
    }

    return '';
  }

  bool canHandleState(JackboxState state) {
    if (_handledStates.containsKey(state.runtimeType)) {
      return true;
    } else {
      return false;
    }
  }

  JackboxState _handleSessionLoginState(ArgMsg msg, JackboxState state) {
    if (state is SessionLoginState) {
      if (msg is ArgResult) {
        if (msg.action == 'JoinRoom' && msg.success) {
          // Successfully joined room
          return SessionLobbyState(allowedToStart: false, enoughPlayers: false);
        }
      }
    }

    return null;
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

    Outer msg = Outer(args: [
      ArgActionJoinRoom(
          appId: meta.roomInfo.appId,
          roomId: meta.roomInfo.roomId,
          userId: meta.userId,
          joinType: meta.roomInfo.joinAs,
          name: meta.userName,
          options: {
            'roomcode': meta.roomInfo.roomId,
            'name': meta.userName,
          })
    ]);

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
    if (!_handledGames.containsKey(appId)) {
      return;
    }

    _gameHandler = _handledGames[appId]();
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
    Map<String, dynamic> jmsg = jsonDecode(msg);
    Outer msgp = Outer.fromJson(jmsg);
    JackboxState finalState = currentState;

    for (ArgMsg argm in msgp.args) {
      JackboxState nextState;
      if (canHandleState(finalState)) {
        nextState = _handledStates[finalState.runtimeType](argm, finalState);
      } else if (_gameHandler.canHandleState(finalState)) {
        nextState = _gameHandler.handleState(msg, finalState);
      } else {
        // ?
      }

      if (nextState != null) {
        finalState = nextState;
      }
    }

    return;
  }

  void resetState() {
    _wsSub?.cancel();
    _wsSub = null;

    _disconnectWS();

    _eventStream?.sink?.close();
    _eventStream?.close();
    _eventStream = null;

    // Once we close this stream out we can't re-use it, so create a new one
    _stateStream?.sink?.close();
    _stateStream?.close();
    _stateStream = null;

    _gameHandler = null;

    _init();
  }
}
