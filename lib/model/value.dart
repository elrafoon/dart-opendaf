part of opendaf;

class Value {
  static String getPrefix(String valueWithPrefix) {
    if(valueWithPrefix == null || valueWithPrefix.length == 0 || (valueWithPrefix != "s" && valueWithPrefix.length < 2))
      return null;
    else
      return valueWithPrefix[0];
  }

  static int getDataType(String valueWithPrefix) => Datatype.fromPrefix(getPrefix(valueWithPrefix));

  static dynamic parseValueWithPrefix(String valueWithPrefix) {
    if(valueWithPrefix == null)
      return null;

    var prefix = getPrefix(valueWithPrefix);
    if(prefix == null)
      return null;
    else {
      String value = valueWithPrefix.substring(1);
      switch(Datatype.fromPrefix(prefix)) {
        case Datatype.DT_BINARY:
          switch(value.toLowerCase()) {
            case "0":
            case "false":
              return false;
            case "1":
            case "true":
              return true;
            default:
              throw new ArgumentError("Can't parseValueWithPrefix(${valueWithPrefix})!");
          }
          break;
        case Datatype.DT_INTEGER:
        case Datatype.DT_LONG:
        case Datatype.DT_QUATERNARY:
          return int.parse(value);
        case Datatype.DT_FLOAT:
        case Datatype.DT_DOUBLE:
          if (value.toLowerCase().compareTo("nan") == 0) {
            return double.NAN;
          } else if (value.toLowerCase().compareTo("inf") == 0) {
			      return double.INFINITY;
          } else if (value.toLowerCase().compareTo("-inf") == 0) {
			      return double.NEGATIVE_INFINITY;
          } else {
            return double.parse(value);
          }
          break;
        case Datatype.DT_STRING:
          return value;
        default:
          return null;
      }
    }
  }

  static String formatAs(dynamic value, int datatype) {
    String prefix = Datatype.toPrefix(datatype);

    switch(datatype) {
      case Datatype.DT_BINARY:
        bool b = value;
        return prefix + (b ? "1" : "0");
      case Datatype.DT_QUATERNARY:
        return prefix + int.parse(value.toString()).toString();
      case Datatype.DT_INTEGER:
        return prefix + int.parse(value.toString()).toString();
      case Datatype.DT_LONG:
        return prefix + int.parse(value.toString()).toString();
      case Datatype.DT_FLOAT:
        return prefix + double.parse(value.toString()).toString();
      case Datatype.DT_DOUBLE:
        return prefix + double.parse(value.toString()).toString();
      case Datatype.DT_STRING:
        return prefix + value.toString();
      default:
        return null;
    }
  }
}
