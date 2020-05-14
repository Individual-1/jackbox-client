library socketio;

const int UNKNOWN = -1;
const int OPEN = 1;
const int PING = 2;
const int PONG = 3;
const int MSG = 5;

int getMessageType(String message) {
  if (message == '1::') {
    return OPEN;
  } else if (message == '2:::') {
    return PING;
  } else if (message == '2::') {
    return PONG;
  } else if (message.startsWith('5:::')) {
    return MSG;
  }

  return UNKNOWN;
}

String prepareMessageOfType(int type, String msg) {
  switch (type) {
    case OPEN:
      return '1::';
    case PING:
      return '2:::';
    case PONG:
      return '2::';
    case MSG:
      return '5:::' + msg;
  }

  return msg;
}

String getMsgBody(String message) {
  return message.substring(4);
}
