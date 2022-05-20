part of opendaf;

class Command extends CommunicationObject {
  static const int CS_SCALER = 2, CS_RAW_RANGE_LIMIT = 16, CS_EU_RANGE_LIMIT = 21;
  List<StackModule> stackModules = [
    new StackModule("Scaler", CS_SCALER),
    new StackModule("RawRangeLimit", CS_RAW_RANGE_LIMIT),
    new StackModule("EuRangeLimit", CS_EU_RANGE_LIMIT)
  ];

  final OpenDAF _opendaf;
  Command _original;

  // Runtime
  VT vt;

  // Configuration
  String initialValue;

  Command(this._opendaf, { name, description, connectorName, address, datatype, euRangeLow, euRangeHigh, rawDatatype, rawRangeLow, rawRangeHigh, 
          providerAddresses, this.initialValue, archMode, archPeriod, archValueDeadband, archTimeDeadband, leader, stackUmask, eu, enabled, properties}) 
    :super(_opendaf, 
      name: name, 
      description: description, 
      connectorName: connectorName, 
      address: address,
      datatype: datatype, 
      euRangeLow: euRangeLow, 
      euRangeHigh: euRangeHigh, 
      rawDatatype: rawDatatype, 
      rawRangeLow: rawRangeLow, 
      rawRangeHigh: rawRangeHigh, 
      providerAddresses: providerAddresses, 
      archMode: archMode, 
      archPeriod: archPeriod, 
      archValueDeadband: archValueDeadband, 
      archTimeDeadband: archTimeDeadband, 
      leader: leader, 
      stackUmask: stackUmask, 
      eu: eu, 
      enabled: enabled, 
      properties: properties != null ? new Map<String, dynamic>.from(properties) : new Map<String, dynamic>()
    ) { this.updateStackModules(); }

  Command dup() => new Command(_opendaf, 
      name: name, 
      description: description, 
      connectorName: connectorName, 
      address: address,
      datatype: datatype, 
      euRangeLow: euRangeLow, 
      euRangeHigh: euRangeHigh, 
      rawDatatype: rawDatatype, 
      rawRangeLow: rawRangeLow, 
      rawRangeHigh: rawRangeHigh, 
      providerAddresses: providerAddresses, 
      initialValue: initialValue,
      archMode: archMode, 
      archPeriod: archPeriod, 
      archValueDeadband: archValueDeadband, 
      archTimeDeadband: archTimeDeadband, 
      leader: leader, 
      stackUmask: stackUmask, 
      eu: eu, 
      enabled: enabled, 
      properties: properties != null ? new Map<String, dynamic>.from(properties) : new Map<String, dynamic>()
    );
  

  Command.empty(this._opendaf) : super(_opendaf, 
    providerAddresses : new Map<String, String>(),
    stackUmask: 0,
    archMode: "none",
    archPeriod: 1000,
    archTimeDeadband: 0,
    enabled: true,
    properties: new Map<String, String>()
  ){ this.updateStackModules(); }

  Command.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) : super(_opendaf) { updateConfigurationJson(cfg); }
  Command.fromRuntimeJson(this._opendaf, Map<String, dynamic> runtime) : super(_opendaf) { updateRuntimeJson(runtime); }

    /* Getters */
  Command get original => _original;
  String get id => this.name;
  String get className => "Command";
  String toString() => id;
  bool get isEditable => this.original != null;

  String get smartValue => (vt?.value == null) ? "--" : vt.value;
  String get smartTimestamp => (vt?.timestamp == null) ? "--" : (
  	getDate(new DateTime.now()) == getDate(vt.timestamp)
  	? new DateFormat("HH:mm:ss").format(vt.timestamp)
  	: vt.timestamp.toString() 
  );

  static DateTime getDate(DateTime t) => new DateTime(t.year, t.month, t.day);

  void cfg_stash()          => _original = this.dup();
  void cfg_revert()         => this.cfg_assign(_original);
  bool cfg_changed()        => !cfg_compare(_original);
  bool cfg_name_changed()   => this.name != this._original?.name;

  void updateRuntimeJson(Map<String, dynamic> runtime){
    if(runtime == null)
      return;

    super.updateRuntimeJson(runtime);
    if(runtime["vt"] != null)  this.vt = new VT.fromJson(runtime["vt"]);

    this.runtimeLoaded = true;
	_opendaf.ctrl.command._ls.wsUpdateCounter++;
  }

  void updateConfigurationJson(Map<String, dynamic> cfg){
    if(cfg == null)
      return;

    super.updateConfigurationJson(cfg);
    if(cfg["initialValue"] != null)       this.initialValue       = cfg["initialValue"];

    this.updateStackModules();
    this.cfg_stash();

    this.configurationLoaded = true;
	_opendaf.ctrl.command._ls.objectsLoadedCounter++;
  }

  void updateStackModules(){
    if(this.stackUmask == null){
      this.stackUmask = 0;
    }
    stackModules.forEach((stackModule) {
      stackModule.enabled = (this.stackUmask & stackModule.id) != 0;
      stackModule.parent = this;
    });
  }

  void cfg_assign(Command other) {
    if(other == null)
      return;
      
    super.cfg_assign(other);
    this.initialValue = other.initialValue;

    this.cfg_stash();
  }

  bool cfg_compare(Command other){
    if(other == null)
      return false;

    return super.cfg_compare(other) && this.initialValue == other.initialValue;
  }

  Map<String, dynamic> toCfgJson() {
    Map<String, dynamic> js = super.toCfgJson();
    _toJson(js, "initialValue", initialValue);
    return js;
  }

	String validateWrite(dynamic value){
		if(datatype == null || datatype == Datatype.DT_EMPTY)
			return "Can't write null command!";

		switch(datatype) {
			case Datatype.DT_BINARY:
				if(!(value is bool))
					return "Write binary command argument must be bool";
				break;
			
			case Datatype.DT_QUATERNARY:
			case Datatype.DT_INTEGER:
			case Datatype.DT_LONG:
				if(!(value is int))
					return "Write quaternary, integer and long command argument must be int";
				break;
			
			case Datatype.DT_FLOAT:
			case Datatype.DT_DOUBLE:
				if(!(value is num))
					return "Write quaternary, integer and long command argument must be number";
				break;
			
			case Datatype.DT_STRING:
				break;
			
			default:
				return "Unknown command data type '${datatype}'";
		}
		return null;
	}

	Future write(dynamic value) {
		String err = validateWrite(value);

		if(err != null)
			return new Future.error(err);

		return _opendaf.writeCommand(this.name, Value.formatAs(value, datatype));
	}

	Future writeWs(dynamic value, OpenDAFWS _ws) {
		String err = validateWrite(value);

		if(err != null)
			return new Future.error(err);

		return _ws.writeCommand(this.name, Value.formatAs(value, datatype));
	}

	dynamic operator[](String key) {
		switch(key){
			case "initialValue": 	return this.initialValue;
			case "value": 			return this.vt?.value;
			case "timestamp": 		return this.vt?.timestamp;
			default: return super[key];
		}
	}
}
