part of opendaf;

class Value {
  static const int DT_BINARY = 1;
  static const int DT_QUATERNARY = 2;
  static const int DT_INTEGER = 3;
  static const int DT_LONG = 4;
  static const int DT_FLOAT = 5;
  static const int DT_DOUBLE = 6;
  static const int DT_STRING = 7;
  
  static dynamic getDataType(String valueWithPrefix) {
    if(valueWithPrefix.length < 2)
      return null;
    else {
      if(valueWithPrefix.compareTo("<empty>") == 0)
        return null;
      else {
        return valueWithPrefix[0];
      }
    }
  }

  static dynamic parseValueWithPrefix(String valueWithPrefix) {
    if(valueWithPrefix == null)
      return null;
    
    var data_type = getDataType(valueWithPrefix);
    if(data_type == null)
      return null;
    else {
      String value = valueWithPrefix.substring(1);
      switch(data_type) {
        case 'b':
          return int.parse(value) != 0;
        case 'i':
        case 'l':
        case 'q':
          return int.parse(value);
        case 'f':
        case 'd':
          return double.parse(value);
        case 's':
          return value;
        default:
          return null;
      }
    }
  }
  
  static String formatAs(dynamic value, int datatype) {
    switch(datatype) {
      case DT_BINARY:
        bool b = value;
        return "b" + (b ? "1" : "0");
      case DT_QUATERNARY:
        return "q" + int.parse(value.toString()).toString();
      case DT_INTEGER:
        return "i" + int.parse(value.toString()).toString();
      case DT_LONG:
        return "l" + int.parse(value.toString()).toString();
      case DT_FLOAT:
        return "f" + double.parse(value.toString()).toString();
      case DT_DOUBLE:
        return "d" + double.parse(value.toString()).toString();
      case DT_STRING:
        return "s" + value.toString();
      default:
        return null;
    }
  }
}
