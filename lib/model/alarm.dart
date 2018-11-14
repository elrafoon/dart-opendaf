part of opendaf;

enum EAlarmState { AS_INACT_ACK, AS_ACT_UNACK, AS_ACT_ACK, AS_INACT_UNACK }

class Alarm {
  final String name;
  final int severity;
  final DateTime timestamp;
  final String authority;
  final EAlarmState state;
  final String description;
  
  Alarm(this.name, this.severity, this.timestamp, this.authority, this.state, this.description);
  Alarm.fromJson(Map<String, dynamic> json) : 
    this(json["name"], json["severity"], VT.parseTime(json["timestamp"]), json["authority"], decodeState(json["state"]), json["description"]);
  
  static EAlarmState decodeState(String stateName) {
    switch(stateName) {
      case "inact_ack": return EAlarmState.AS_INACT_ACK;
      case "act_unack": return EAlarmState.AS_ACT_UNACK;
      case "act_ack": return EAlarmState.AS_ACT_ACK;
      case "inact_unack": return EAlarmState.AS_INACT_UNACK;
      default: return null;
    }
  }
}
