part of opendaf;

enum EAlarmState { AS_ACT_UNACK, AS_ACT_ACK, AS_INACT_UNACK, AS_INACT_ACK }

class Alarm {
  static const String AM_NONE = "none", AM_CHANGE = "change";
  static List<String> get archModeList => [ AM_NONE, AM_CHANGE ];
  static List<String> get ackModeList => [ "manual", "auto" ];

  final OpenDAF _opendaf;

  Alarm _original;
  Alarm get original => _original;

  // Runtime 
  DateTime timestamp;
  String authority = "";
  EAlarmState state;
  bool runtimeLoaded;

  // Configuration
  String name;
  String description = "";
  int severity = 0;
  String archMode = AM_CHANGE;
  String ackMode = "manual";
  bool enabled = true;

  Map<String, dynamic> properties = new Map<String, dynamic>();
  bool configurationLoaded;

  bool get isActive => state != null && state == EAlarmState.AS_ACT_UNACK || state == EAlarmState.AS_ACT_ACK;
  bool get isAcknowledged => state != null && state == EAlarmState.AS_INACT_ACK || state == EAlarmState.AS_ACT_ACK;
  String get smartTimestamp => (timestamp == null) ? "--" : (
    getDate(new DateTime.now()) == getDate(timestamp)
    ? new DateFormat("HH:mm:ss").format(timestamp)
    : timestamp.toString() 
  );

  int get stateNumber => state?.index ?? -1;

  static DateTime getDate(DateTime t) => new DateTime(t.year, t.month, t.day);

  Alarm(this._opendaf, {this.name, this.description, this.severity, this.archMode, this.ackMode, this.enabled, this.properties = const {}});

  Alarm.empty(this._opendaf);

  Alarm.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) {
    updateConfigurationJson(cfg);
  }

  Alarm.fromRuntimeJson(this._opendaf, Map<String, dynamic> runtime) {
      updateRuntimeJson(runtime);
  }

  void updateRuntimeJson(Map<String, dynamic> runtime){
      if(runtime == null)
        return;

      if(runtime["name"] != null)
        this.name = runtime["name"];
      if(runtime["state"] != null)
        this.state = decodeState(runtime["state"]);
      if(runtime["timestamp"] != null)
        this.timestamp = VT.parseTime(runtime["timestamp"]);
      if(runtime["authority"] != null)
        this.authority = runtime["authority"];
      if(runtime["description"] != null)
        this.description = runtime["description"];
      if(runtime["severity"] != null)
        this.severity = runtime["severity"];

      this.runtimeLoaded = true;
  }

    void updateConfigurationJson(Map<String, dynamic> cfg){
      if(cfg == null)
        return;

      if(cfg["name"] != null)
        this.name = cfg["name"];
      if(cfg["description"] != null)
        this.description = cfg["description"];
      if(cfg["severity"] != null)
        this.severity = cfg["severity"];
      if(cfg["archMode"] != null)
        this.archMode = cfg["archMode"];
      if(cfg["ackMode"] != null)
        this.ackMode = cfg["ackMode"];
      if(cfg["enabled"] != null)
        this.enabled = cfg["enabled"];

      if(cfg["properties"] != null)
        this.properties = cfg["properties"];

      this.configurationLoaded = true;
      this.cfg_stash();
  }

  Alarm dup() => new Alarm(_opendaf, 
    name: name, 
    description: description, 
    severity: severity, 
    archMode: archMode, 
    ackMode: ackMode,
    enabled: enabled, 
    properties: new Map<String, dynamic>.from(properties)
  );  


  void cfg_assign(Alarm other) {
    if(other == null)
      return;
      
    this.name         = other.name;
    this.description  = other.description;
    this.severity     = other.severity;
    this.archMode     = other.archMode;
    this.ackMode      = other.ackMode;
    this.enabled      = other.enabled;
    this.properties   = new Map<String, dynamic>.from(other.properties);

    this.cfg_stash();
  }

  bool cfg_compare(Alarm other){
    if(other == null)
      return false;

    bool propertiesMatch = true;
    this.properties.forEach((key, value) {
      if(value != other.properties[key]){
        propertiesMatch = false;
      }
    });

    return propertiesMatch &&
      this.name         == other.name         &&
      this.description  == other.description  &&
      this.severity     == other.severity     &&
      this.archMode     == other.archMode     &&
      this.ackMode      == other.ackMode      &&
      this.enabled      == other.enabled      ;
  }

  void cfg_stash() {
    this.configurationLoaded = true;
    _original = this.dup();
  } 
  void cfg_revert() => this.cfg_assign(_original);
  bool cfg_changed() => !cfg_compare(_original);
  bool cfg_name_changed() => this.name != this._original?.name;

  Map<String, dynamic> toCfgJson() => {
    "name": name,
    "description": description,
    "severity": severity.toInt(),
    "archMode": archMode,
    "ackMode": ackMode,
    "enabled": enabled,
    "properties": properties
  };

  Future acknowledge() => _opendaf.ctrl.alarm.acknowledge(name);
  Future activate() => _opendaf.ctrl.alarm.activate(name);
  Future deactivate() => _opendaf.ctrl.alarm.deactivate(name);
  
  static EAlarmState decodeState(String stateName) {
    switch(stateName) {
      case "inact_ack": return EAlarmState.AS_INACT_ACK;
      case "act_unack": return EAlarmState.AS_ACT_UNACK;
      case "act_ack": return EAlarmState.AS_ACT_ACK;
      case "inact_unack": return EAlarmState.AS_INACT_UNACK;
      default: return null;
    }
  }
  
  bool get isEditable => this.original != null;

  String get id => this.name;
  String toString() => id;

    bool hasMatch(RegExp regex) => 
       regex.hasMatch(name ?? "")
    || regex.hasMatch(description ?? "")
    || regex.hasMatch(archMode ?? "")
    || regex.hasMatch(authority ?? "")
  ;

	dynamic operator[](String key) {
		switch(key){
			case "name": 		return this.name;
			case "state": 		return this.state;
			case "stateNumber": return this.stateNumber;
			case "authority": 	return this.authority;
			case "timestamp": 	return this.timestamp;
			case "description":	return this.description;
			case "severity": 	return this.severity;
			case "archMode": 	return this.archMode;
			case "ackMode": 	return this.ackMode;
			case "enabled": 	return this.enabled;
			default:			return this.properties[key];
		}
	}
}