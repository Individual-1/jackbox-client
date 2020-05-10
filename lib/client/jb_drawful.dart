library jb_drawful;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';

import 'package:jackbox_client/model/internal.dart';
import 'package:jackbox_client/model/jackbox.dart';
import 'package:jackbox_client/model/drawful.dart';

import 'package:jackbox_client/client/jb_game_handler.dart';

class DrawfulHandler extends GameHandler {
  DrawfulHandler(SendPort port, SessionData meta, JackboxState initial)
      : super(port, meta, initial);

  @override
  void handleSessMessage(IntSessionMsg msg) {
    switch (msg.action) {
      case IntSessionAction.UPDATESTATE:
        if (msg.data is Map<String, dynamic>) {
          if (msg.data['process'] && currentState.runtimeType == msg.data['state'].runtimeType) {

            /*
              We should never receive a state different from our current which we need to process.
              This is because the UI is limited in what kind of actions it can perform.
              We expect that we only get updates on given states/elements.

              1. Drawing is being submitted
              2. Lie is being submitted
              3. Lobby is launching
              4. Likes are being submitted
            */
            switch (currentState.runtimeType) {
              case DrawfulDrawingState:
                DrawfulDrawingState curDraw = currentState;
                DrawfulDrawingState inDraw = msg.data['state'];

                if (curDraw.lines == null && inDraw.lines != null) {
                  sendImage(inDraw.lines);
                }
                break;
              
              case DrawfulEnterLieState:
                DrawfulEnterLieState curLie = currentState;
                DrawfulEnterLieState inLie = msg.data['state'];

                if (curLie.lie == '' && inLie.lie != '') {
                  sendLie(inLie.lie);
                }
                break;
              
              case DrawfulChooseLieState:
                DrawfulChooseLieState curLie = currentState;
                DrawfulChooseLieState inLie = msg.data['state'];

                if (curLie.chosen == '' && inLie.chosen != '') {
                  sendChoice(inLie.chosen, inLie.usedSuggestion);
                } else if (!curLie.usedSuggestion && inLie.usedSuggestion) {
                  sendChoice('', inLie.usedSuggestion);
                }

              break;
              case SessionLobbyState:
                SessionLobbyState curLobby = currentState;
                SessionLobbyState inLobby = msg.data['state'];
                if (!curLobby.startGame && inLobby.startGame) {
                  startGame();
                }
              break;
            }
          }

          currentState = msg.data['state'];
        }
        break;
      default:
        break;
    }
  }

  @override
  void handleJbMessage(IntJackboxMsg msg) {
    Map<String, dynamic> jmsg = jsonDecode(msg.msg);
    Outer msgp = Outer.fromJson(jmsg);

    for (ArgMsg argm in msgp.args) {
      JackboxState nextState;
      JackboxState defaultState;
      bool changed = false;

      if (argm is ArgEvent) {
        ArgEventBlob blob = getSpecificBlobType(argm);
        switch (currentState.runtimeType) {

          /*
            Processor for Jackbox messages while in a Lobby state
            There are 4 directions we can go from this state
            1. Continue to wait for players/for leader to start
            2. Go to drawing canvas because we don't have a picture
            3. Start the game
            4. Game ends
          */
          case SessionLobbyState:
            SessionLobbyState lobbyState = SessionLobbyState.From(currentState);
            defaultState = lobbyState;

            if (!lobbyState.postGame) {
              if (argm.event == 'RoomBlobChanged') {
                if (blob is AEBRLobby) {
                  // Case 1
                  // We have enough people to start now
                  if (blob.lobbyState == 'CanStart' &&
                      !lobbyState.enoughPlayers) {
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
              } else if (argm.event == 'CustomerBlobChanged') {
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

            break;

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
          case DrawfulDrawingState:
            DrawfulDrawingState drawState =
                DrawfulDrawingState.From(currentState);
            defaultState = drawState;

            if (argm.event == 'RoomBlobChanged') {
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
            } else if (argm.event == 'CustomerBlobChanged') {
              if (blob is AEBCLobby) {
                // Case 1a
                // We are the host
                if (blob.isAllowedToStartGame !=
                    drawState.lobbyState.allowedToStart) {
                  drawState.lobbyState.allowedToStart =
                      blob.isAllowedToStartGame;
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
            break;

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
          case DrawfulWaitState:
            if (argm.event == 'RoomBlobChanged') {
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
                    usedSuggestion: false,
                    isAuthor: false);
                changed = true;
              }
            } else if (argm.event == 'CustomerBlobChanged') {
              // Case 1
              if (blob is AEBCDrawingTime) {
                nextState =
                    DrawfulDrawingState(prompt: blob.prompt, lobbyState: null);
                changed = true;

                // Case 2
              } else if (blob is AEBCEnterLie) {
                nextState =
                    DrawfulEnterLieState(lie: '', isAuthor: blob.isAuthor);
                changed = true;

                // Case 3a/b
              } else if (blob is AEBCChooseLie) {
                nextState = DrawfulChooseLieState(
                    choices: HashSet<String>(),
                    myEntry: blob.entry.text,
                    likes: HashSet<String>(),
                    chosen: '',
                    usedSuggestion: false,
                    isAuthor: blob.isAuthor);
                changed = true;
              }
            }
            break;

          /*
            Processor for Jackbox messages while in the Enter Lie phase
            Not a lot of places we can go from here:
            1. Enter lie and wait (or choose lie for me)
            2. Run out of time
          */
          case DrawfulEnterLieState:
            if (argm.event == 'RoomBlobChanged') {
              // Case 1 or 2
              if (blob.state == DrawfulState.GAMEPLAY_LYINGDONE) {
                nextState = DrawfulWaitState();
                changed = true;
              }
            } else if (argm.event == 'CustomerBlobChanged') {
              // Case 1 or 2
              if (blob.state == DrawfulState.GAMEPLAY_LIERECEIVED ||
                  blob.state == DrawfulState.GAMEPLAY_LYINGDONE) {
                nextState = DrawfulWaitState();
                changed = true;
              }
            }
            break;

          /*
            Processor for Jackbox messages while in the Choose Lie phase
            This one is a bit more complex because we have a few different bits of state to manage
            We also need to keep an eye out for missing details and update on those

            1. While choosing, we receive new data and update on it
            2. We pick a choice and get to pick likes
            3. We pick likes
            4. We run out of time and go back to wait state
          */
          case DrawfulChooseLieState:
            DrawfulChooseLieState lieState =
                DrawfulChooseLieState.From(currentState);
            defaultState = lieState;

            if (argm.event == 'RoomBlobChanged') {
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
            } else if (argm.event == 'CustomerBlobChanged') {
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
            break;
        }
      }

      if (changed) {
        if (nextState == null) {
          nextState = defaultState;
        }

        currentState = nextState;

        sendIntMessage(IntSessionMsg(
            action: IntSessionAction.UPDATESTATE,
            data: {'process': false, 'state': currentState}));
      }
    }
  }

  void _sendActionMessage(Map<String, dynamic> message) {
    if (meta.roomInfo == null) {
      return;
    }

    Outer msg = Outer(args: [
      ArgActionSendMsg(
          appId: meta.roomInfo.appId,
          roomId: meta.roomInfo.roomId,
          userId: meta.userId,
          message: message)
    ]);

    String smsg = jsonEncode(msg);

    sendIntMessage(IntJackboxMsg(msg: smsg));
  }

  // sendImage takes in a serialized json array and sends it to the jackbox server
  void sendImage(Map<String, dynamic> lines) {
    _sendActionMessage({
      'setPlayerPicture': true,
      'pictureLines': lines,
    });
  }

  // startGame send a message which starts the game
  void startGame() {
    _sendActionMessage({'startGame': true});
  }

  void sendLie(String lie) {
    _sendActionMessage({'like': lie});
  }

  void sendChoice(String choice, bool usedSuggestion) {
    _sendActionMessage({'lieEntered': choice, 'usedSuggestion': usedSuggestion});
  }

  // likeChoice sends a message liking a given choice string
  void likeChoice(String choice) {
    _sendActionMessage({'like': choice});
  }

  @override
  bool canHandleStateType(JackboxState state) {
    if (state is DrawfulState) {
      return true;
    } else {
      return false;
    }
  }
}
