library sio_msg_type;

const int UNKNOWN = -1;
const int OPEN = 1;
const int PING = 2;
const int PONG = 3;
const int MSG = 5;

int GetMessageType(String message) {
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

String PrepareMessageOfType(int type, String msg) {
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

String GetMSGBody(String message) {
  return message.substring(4);
}
