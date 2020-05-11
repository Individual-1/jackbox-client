library jb_drawful;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';
import 'package:jackbox_client/model/drawful.dart';

import 'package:jackbox_client/client/jb_game_handler.dart';

class DrawfulHandler extends GameHandler {
  Map<Type, JackboxEventHandler> _handledEvents;
  Map<Type, JackboxStateHandler> _handledStates;

  DrawfulHandler() {
    _initHandlerMaps();
  }

  void _initHandlerMaps() {
    _handledEvents = {
      DrawfulStartGameEvent: (e, m) => _handleDrawfulStartGameEvent(e, m),
      DrawfulSubmitDrawingEvent: (e, m) => _handleDrawfulSubmitDrawingEvent(e, m),
      DrawfulSubmitLieEvent: (e, m) => _handleDrawfulSubmitLieEvent(e, m),
      DrawfulChooseLieEvent: (e, m) => _handleDrawfulChooseLieEvent(e, m),
      DrawfulLikeChoiceEvent: (e, m) => _handleDrawfulLikeChoiceEvent(e, m),
    };

    _handledStates = {
      SessionLobbyState: (m, s) => _handleSessionLobbyState(m, s),
      DrawfulDrawingState: (m, s) => _handleDrawfulDrawingState(m, s),
      DrawfulWaitState: (m, s) => _handleDrawfulWaitState(m, s),
      DrawfulEnterLieState: (m, s) => _handleDrawfulEnterLieState(m, s),
      DrawfulChooseLieState: (m, s) => _handleDrawfulChooseLieState(m, s),
    };
  }

  @override
  bool canHandleEvent(JackboxEvent event) {
    if (_handledEvents.containsKey(event.runtimeType)) {
      return true;
    } else {
      return false;
    }
  }

  @override
  String handleEvent(JackboxEvent event, SessionData meta) {
    if (canHandleEvent(event)) {
      return _handledEvents[event.runtimeType](event, meta);
    }

    return '';
  }

  String _handleDrawfulStartGameEvent(JackboxEvent event, SessionData meta) {
    if (event is DrawfulStartGameEvent) {
      return _formatActionMessage({'startGame': true}, meta);
    }

    return '';
  }

  String _handleDrawfulSubmitDrawingEvent(JackboxEvent event, SessionData meta) {
    if (event is DrawfulSubmitDrawingEvent) {
      return _formatActionMessage({
        'setPlayerPicture': true,
        'pictureLines': event.lines,
      }, meta);
    }

    return '';
  }

  String _handleDrawfulSubmitLieEvent(JackboxEvent event, SessionData meta) {
    if (event is DrawfulSubmitLieEvent) {
          return _formatActionMessage(
        {'lieEntered': event.lie, 'usedSuggestion': event.usedSuggestion}, meta);
    }

    return '';
  }

  String _handleDrawfulChooseLieEvent(JackboxEvent event, SessionData meta) {
    if (event is DrawfulChooseLieEvent) {
      return _formatActionMessage({'choice': event.choice}, meta);
    }

    return '';
  }

  String _handleDrawfulLikeChoiceEvent(JackboxEvent event, SessionData meta) {
    if (event is DrawfulLikeChoiceEvent) {
      return _formatActionMessage({'like': event.choice}, meta);
    }

    return '';
  }

  @override
  bool canHandleState(JackboxState state) {
    if (_handledStates.containsKey(state.runtimeType)) {
      return true;
    } else {
      return false;
    }
  }

  @override
  JackboxState handleState(ArgMsg msg, JackboxState state) {
    if (canHandleState(state)) {
      return _handledStates[state.runtimeType](msg, state);
    }

    return null;
  }

  /*
    Processor for Jackbox messages while in a Lobby state
    There are 4 directions we can go from this state
    1. Continue to wait for players/for leader to start
    2. Go to drawing canvas because we don't have a picture
    3. Start the game
    4. Game ends
  */
  JackboxState _handleSessionLobbyState(ArgMsg msg, JackboxState state) {
    JackboxState nextState;

    if (state is SessionLobbyState && msg is ArgEvent) {
      ArgEventBlob blob = getSpecificBlobType(msg);
      bool changed = false;

      SessionLobbyState lobbyState = SessionLobbyState.From(state);
      JackboxState defaultState = lobbyState;

      if (!lobbyState.postGame) {
        if (msg.event == 'RoomBlobChanged') {
          if (blob is AEBRLobby) {
            // Case 1
            // We have enough people to start now
            if (blob.lobbyState == 'CanStart' && !lobbyState.enoughPlayers) {
              lobbyState.enoughPlayers = true;
              changed = true;
              // Case 3
            } else if (blob.lobbyState == 'Countdown') {
              // Transitioning to a starting-game state regardless of what we were doing
              nextState = DrawfulWaitState();
              changed = true;
            }
          } else if (blob is ArgEventBlobRoom) {
            // Case 3
            if (blob.state == DrawfulState.GAMEPLAY_LOGO) {
              nextState = DrawfulWaitState();
              changed = true;
            }
          }
        } else if (msg.event == 'CustomerBlobChanged') {
          if (blob is AEBCLobby) {
            // Case 1
            // We are the host
            if (blob.isAllowedToStartGame != lobbyState.allowedToStart) {
              lobbyState.allowedToStart = blob.isAllowedToStartGame;
              changed = true;
            }

            // Case 2
            // We need to draw a picture for the lobby
            if (!blob.hasPicture) {
              nextState = DrawfulDrawingState(
                  prompt: 'Draw something', lobbyState: lobbyState);
              changed = true;
            }
          }
        }
      } else {
        // What do we do postlobby?
      }

      if (changed && nextState == null) {
        nextState = defaultState;
      }
    }

    return nextState;
  }

  /*
    Processor for Jackbox messages while in the Drawing state
    There are 2 cases in which we would be in this state and X potential transitions
    1. We need to draw a picture for ourselves for the lobby
      a. We continue drawing our picture and updating lobby status as we go
      b. We finish drawing picture and move back to lobby state
      c. We are forced out of draw state by game start and don't have a picture
    2. We are drawing a picture for a prompt
      a. We continue drawing our picture while status updates occur
      b. We finish drawing picture and move to wait state
      c. We run out of time to draw our picture and move to wait state

    Functionally 2b and 2c are the same result as we don't really care if we have submitted a picture or not
  */
  JackboxState _handleDrawfulDrawingState(ArgMsg msg, JackboxState state) {
    JackboxState nextState;

    if (state is DrawfulDrawingState && msg is ArgEvent) {
      JackboxState defaultState;
      ArgEventBlob blob = getSpecificBlobType(msg);
      bool changed = false;

      DrawfulDrawingState drawState = DrawfulDrawingState.From(state);
      defaultState = drawState;

      if (msg.event == 'RoomBlobChanged') {
        // Case 1a
        if (blob is AEBRLobby) {
          // We have enough people to start now
          if (blob.lobbyState == 'CanStart' &&
              !drawState.lobbyState.enoughPlayers) {
            drawState.lobbyState.enoughPlayers = true;
            changed = true;

            // Case 1c
          } else if (blob.lobbyState == 'Countdown') {
            // Transitioning to a starting-game state regardless of what we were doing
            nextState = DrawfulWaitState();
            changed = true;
          }
        } else if (blob is ArgEventBlobRoom) {
          // Case 1c
          if (blob.state == DrawfulState.GAMEPLAY_LOGO) {
            nextState = DrawfulWaitState();
            changed = true;
          }
        }
      } else if (msg.event == 'CustomerBlobChanged') {
        if (blob is AEBCLobby) {
          // Case 1a
          // We are the host
          if (blob.isAllowedToStartGame !=
              drawState.lobbyState.allowedToStart) {
            drawState.lobbyState.allowedToStart = blob.isAllowedToStartGame;
            changed = true;
          }

          // Case 1b
          // We have submitted our picture and it was received, we can navigate back
          if (blob.hasPicture) {
            nextState = drawState.lobbyState;
            changed = true;
          }
        } else if (blob is ArgEventBlobRoom) {
          // case 1c
          if (blob.state == DrawfulState.GAMEPLAY_LOGO) {
            nextState = DrawfulWaitState();
            changed = true;
          }
        }
      }

      if (changed && nextState == null) {
        nextState = defaultState;
      }
    }

    return nextState;
  }

  /*
    Processor for any Jackbox messages while we are waiting for something to happen
    This state isn't a real Jackbox state and can represent:
    * Gameplay_Logo
    * Gameplay_DrawingDone
    * Gameplay_LieReceived
    * Gameplay_LyingDone

    As such, we don't necessarily validate transitions based on previous state to next state.
    If the Jackbox service sends up badly ordered messages we'll just do whatever it says.

    Here is a list of potential transitions:
    1. Move to drawing phase with a new prompt
    2. Move to lying phase for a given picture
      a. We are the author, so we just sit there
      b. We are not author and can do stuff
    3. Move to choosing a label for a given picture
      a. We are the author so we just sit there
      b. We are not the author and can do stuff
    4. Move to end of game
    5. Do nothing because we received another useless message
  */
  JackboxState _handleDrawfulWaitState(ArgMsg msg, JackboxState state) {
    JackboxState nextState;

    if (state is DrawfulWaitState && msg is ArgEvent) {
      ArgEventBlob blob = getSpecificBlobType(msg);

      if (msg.event == 'RoomBlobChanged') {
        /*
              // This may seem like case 1, but if we transition off of this then we lose the prompt, so ignore it
              if (blob.state == DrawfulState.GAMEPLAY_DRAWINGTIME) {}
              // Same as the prior case where we want to ignore this so customer blob can handle it
              else if (blob.state == DrawfulState.GAMEPLAY_ENTERLIE) {}
              */

        // Case 3, need to keep an eye out for the correspondning customerblob message as it has additional context
        if (blob is AEBRChooseLie) {
          HashSet<String> choices = new HashSet<String>();

          for (AEBLieChoice choice in blob.choices) {
            choices.add(choice.text);
          }
          nextState = DrawfulChooseLieState(
              choices: choices,
              myEntry: '',
              likes: HashSet<String>(),
              chosen: '',
              isAuthor: false);
        }
      } else if (msg.event == 'CustomerBlobChanged') {
        // Case 1
        if (blob is AEBCDrawingTime) {
          nextState =
              DrawfulDrawingState(prompt: blob.prompt, lobbyState: null);

          // Case 2
        } else if (blob is AEBCEnterLie) {
          nextState = DrawfulEnterLieState(lie: '', isAuthor: blob.isAuthor);

          // Case 3a/b
        } else if (blob is AEBCChooseLie) {
          nextState = DrawfulChooseLieState(
              choices: HashSet<String>(),
              myEntry: blob.entry.text,
              likes: HashSet<String>(),
              chosen: '',
              isAuthor: blob.isAuthor);
        }
      }
    }

    return nextState;
  }

  /*
    Processor for Jackbox messages while in the Enter Lie phase
    Not a lot of places we can go from here:
    1. Enter lie and wait (or choose lie for me)
    2. Run out of time
  */
  JackboxState _handleDrawfulEnterLieState(ArgMsg msg, JackboxState state) {
    JackboxState nextState;

    if (state is DrawfulEnterLieState && msg is ArgEvent) {
      ArgEventBlob blob = getSpecificBlobType(msg);

      if (msg.event == 'RoomBlobChanged') {
        // Case 1 or 2
        if (blob.state == DrawfulState.GAMEPLAY_LYINGDONE) {
          nextState = DrawfulWaitState();
        }
      } else if (msg.event == 'CustomerBlobChanged') {
        // Case 1 or 2
        if (blob.state == DrawfulState.GAMEPLAY_LIERECEIVED ||
            blob.state == DrawfulState.GAMEPLAY_LYINGDONE) {
          nextState = DrawfulWaitState();
        }
      }
    }

    return nextState;
  }

  /*
    Processor for Jackbox messages while in the Choose Lie phase
    This one is a bit more complex because we have a few different bits of state to manage
    We also need to keep an eye out for missing details and update on those

    1. While choosing, we receive new data and update on it
    2. We pick a choice and get to pick likes
    3. We pick likes
    4. We run out of time and go back to wait state
  */
  JackboxState _handleDrawfulChooseLieState(ArgMsg msg, JackboxState state) {
    JackboxState nextState;

    if (state is DrawfulChooseLieState && msg is ArgEvent) {
      JackboxState defaultState;
      ArgEventBlob blob = getSpecificBlobType(msg);
      bool changed = false;

      DrawfulChooseLieState lieState = DrawfulChooseLieState.From(state);
      defaultState = lieState;

      if (msg.event == 'RoomBlobChanged') {
        if (blob is AEBRChooseLie) {
          HashSet<String> choices = new HashSet<String>();

          for (AEBLieChoice choice in blob.choices) {
            choices.add(choice.text);
          }

          // Case 1, we have new choices
          if (lieState.choices != choices) {
            lieState.choices.addAll(choices);
            changed = true;
          }

          // Case 2, we picked something
          if (blob.choosingDone && lieState.chosen == '') {
            lieState.chosen = 'anything';
            changed = true;
          }

          // Case 4
        } else if (blob.state == DrawfulState.GAMEPLAY_LOGO) {
          nextState = DrawfulWaitState();
          changed = true;
        }
      } else if (msg.event == 'CustomerBlobChanged') {
        if (blob is AEBCChooseLie) {
          // Case 1, new data about if this is ours or what our entry was
          if (blob.isAuthor != lieState.isAuthor ||
              blob.entry.text != lieState.myEntry) {
            lieState.myEntry = blob.entry.text;
            lieState.isAuthor = blob.isAuthor;
            changed = true;
          }

          // Case 2, we picked something
          if (blob.chosen != null && lieState.chosen == '') {
            lieState.chosen = blob.chosen.text;
            changed = true;
          }
        } else if (blob.state == DrawfulState.GAMEPLAY_LOGO) {
          nextState = DrawfulWaitState();
          changed = true;
        }
      }

      if (changed && nextState == null) {
        nextState = defaultState;
      }
    }

    return nextState;
  }

  String _formatActionMessage(Map<String, dynamic> message, SessionData meta) {
    if (meta.roomInfo == null) {
      return '';
    }

    Outer msg = Outer(args: [
      ArgActionSendMsg(
          appId: meta.roomInfo.appId,
          roomId: meta.roomInfo.roomId,
          userId: meta.userId,
          message: message)
    ]);

    String smsg = jsonEncode(msg);

    return smsg;
  }
}
