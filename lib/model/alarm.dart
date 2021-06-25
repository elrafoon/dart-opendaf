part of opendaf;

enum EAlarmState { AS_INACT_ACK, AS_ACT_UNACK, AS_ACT_ACK, AS_INACT_UNACK }

class Alarm {
  static const String AM_NONE = "none", AM_CHANGE = "change", AM_PERIODIC = "periodic";

  final OpenDAF _opendaf;

  // Runtime 
  DateTime timestamp;
  String authority;
  EAlarmState state;

  // Configuration
  String name;
  String description;
  int severity;
  String archMode;
  String ackMode;
  bool enabled;

  
  Alarm(this._opendaf, [this.name, this.description, this.severity, this.archMode, this.ackMode, this.enabled]);

  Alarm.empty() : this(_opendaf);

  Alarm.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) {
    updateConfigurationJson(cfg);
  }

  Alarm.fromRuntimeJson(this._opendaf, Map<String, dynamic> runtime) {
      updateRuntimeJson(runtime);
  }

  void updateRuntimeJson(Map<String, dynamic> runtime){
      if(runtime == null)
        return;
      this.name = runtime["name"];
      this.description = runtime["description"];
      this.severity = runtime["severity"];
      this.timestamp = VT.parseTime(runtime["timestamp"]);
      this.authority = runtime["authority"];
      this.state = decodeState(runtime["state"]);
  }

    void updateConfigurationJson(Map<String, dynamic> cfg){
      if(cfg == null)
        return;
      this.name = cfg["name"];
      this.description = cfg["description"];
      this.severity = cfg["severity"];
      this.archMode = cfg["archMode"];
      this.ackMode = cfg["ackMode"];
      this.enabled = cfg["enabled"];
  }

  Alarm dup() => new Alarm(_opendaf, name, description, severity, archMode, ackMode, enabled);  

  Map<String, dynamic> toCfgJson() => {
    "name": name,
    "description": description,
    "severity": severity,
    "archMode": archMode,
    "ackMode": ackMode,
    "enabled": enabled
  };

  Future acknowledge() => _opendaf.alarmAcknowledge(name);
  Future activate() => _opendaf.alarmActivate(name);
  Future deactivate() => _opendaf.alarmDeactivate(name);
  
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
