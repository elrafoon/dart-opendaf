part of opendaf;

class Quality {
  static const int STATUS_MASK = 0xC0, SUBSTATUS_MASK = 0x3C, LIMITS_MASK = 0x03;
  static const int STATUS_SHIFT = 6, SUBSTATUS_SHIFT = 2, LIMITS_SHIFT = 0;
  
  // statuses
  static const int GOOD = 0xC0, UNCERTAIN = 0x40, BAD = 0x00;
  
  // substatuses for status BAD
  static const int BAD_DEFAULT = 0x00, BAD_CONFIGURATION_ERROR = 0x04, BAD_NOT_CONNECTED = 0x08, 
      BAD_DEVICE_FAILURE = 0x0C, BAD_SENSOR_FAILURE = 0x10, BAD_LAST_KNOWN_VALUE = 0x14, BAD_COMM_FAILURE = 0x18, 
      BAD_OUT_OF_SERVICE = 0x1C;
  
  static final Map<int, String> badSubstatusDesc = {
    BAD_CONFIGURATION_ERROR : "Configuration error",
    BAD_NOT_CONNECTED : "Not connected",
    BAD_DEVICE_FAILURE : "Device failure",
    BAD_SENSOR_FAILURE : "Sensor failure",
    BAD_LAST_KNOWN_VALUE : "Last known value",
    BAD_COMM_FAILURE : "Communication failure",
    BAD_OUT_OF_SERVICE : "Out of service"
  };
  
  // substatuses for status UNCERTAIN
  static const int UNC_DEFAULT = 0x00, UNC_LAST_USABLE_VALUE = 0x04, UNC_SENSOR_NOT_ACCURATE = 0x10, 
      UNC_ENG_UNITS_EXCEEDED = 0x14, UNC_SUBNORMAL = 0x18;
  
  static final Map<int, String> uncSubstatusDesc = {
    UNC_LAST_USABLE_VALUE : "Last usable value",
    UNC_SENSOR_NOT_ACCURATE : "Sensor not accurate",
    UNC_ENG_UNITS_EXCEEDED : "Eng.units exceeded",
    UNC_SUBNORMAL : "Subnormal"
  };

  // substatuses for status GOOD
  static const int GOOD_DEFAULT = 0x00, GOOD_LOCAL_OVERRIDE = 0x18;
  
  static final Map<int, String> goodSubstatusDesc = {
    GOOD_LOCAL_OVERRIDE : "Local override"                                                
  };
  
  // limits
  static const int LIMIT_NONE = 0x00, LIMIT_LOW = 0x01, LIMIT_HIGH = 0x02, LIMIT_CONSTANT = 0x03;
  
  static final Map<int, String> limitDesc = {
    LIMIT_LOW : "Low-limited",
    LIMIT_HIGH : "High-limited",
    LIMIT_CONSTANT : "Constant"
  };
  
  static int status(int q) => (q & STATUS_MASK);
  static int substatus(int q) => (q & SUBSTATUS_MASK);
  static int limits(int q) => (q & LIMITS_MASK);
  
  static bool isGood(int q) => status(q) == GOOD;
  static bool isUncertain(int q) => status(q) == UNCERTAIN;
  static bool isBad(int q) => status(q) == BAD;
  
  static String _toHex(int n) => n.toRadixString(16).toUpperCase().padLeft(2, '0');
  
  static String getDescription(int q) {
    StringBuffer s = new StringBuffer();
    
    Map<int, String> descMap;
    switch(status(q)) {
      case GOOD:
        s.write("Good");
        descMap = goodSubstatusDesc;
        break;
      case UNCERTAIN:
        s.write("Uncertain");
        descMap = uncSubstatusDesc;
        break;
      case BAD:
        s.write("Bad");
        descMap = badSubstatusDesc;
        break;
      default:
        return "Unknown (${_toHex(q)})";
    }

    int sub = substatus(q);
    if(sub != 0) {
      String desc = descMap[sub];
      if(desc == null)
        desc = _toHex(sub >> SUBSTATUS_SHIFT);
      
      s.write(", $desc");
    }
    
    int lim = limits(q);
    if(lim != 0) {
      String desc = limitDesc[lim];
      if(desc == null)
        desc = _toHex(lim >> LIMIT_SHIFT);
      
      s.write(", $desc");
    }
    
    return s.toString();
  }
  
  static int combine(int q1, int q2) {
    if(isGood(q1)) {
      if(isGood(q2))
        return q1;
      else
        return q2;
    }
    else if(isUncertain(q1)) {
      if(isGood(q2) || isUncertain(q2))
        return q1;
      else
        return q2;
    }
    else
      return q1;
  }
}