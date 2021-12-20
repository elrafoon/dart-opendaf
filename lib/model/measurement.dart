part of opendaf;

class Measurement extends CommunicationObject {
  static const int MS_WATCHDOG = 1, MS_SCALER = 2, MS_DEDUPLICATOR = 4, MS_DEADBAND = 8;

  List<StackModule> stackModules = [
    new StackModule("Watchdog", MS_WATCHDOG),
    new StackModule("Scaler", MS_SCALER),
    new StackModule("Deduplicator", MS_DEDUPLICATOR),
    new StackModule("Deadband", MS_DEADBAND)
  ];

  final OpenDAF _opendaf;

  Measurement _original;

  // Runtime 
  VTQ vtq;

  // Configuration
  String deadband;

  Measurement(this._opendaf, { name, description, connectorName, address, datatype, euRangeLow, euRangeHigh, rawDatatype, rawRangeLow, rawRangeHigh, 
          providerAddresses, this.deadband, archMode, archPeriod, archValueDeadband, archTimeDeadband, leader, stackUmask, eu, enabled, properties}) 
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
    ){ this.updateStackModules(); }

  Measurement dup() => new Measurement(_opendaf, 
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
      deadband: deadband,
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

  Measurement.empty(this._opendaf) : super(_opendaf, 
    providerAddresses : new Map<String, String>(),
    stackUmask: 0,
    archMode: "none",
    archPeriod: 1000,
    archTimeDeadband: 0,
    enabled: true,
    properties: new Map<String, String>()
  ){ this.updateStackModules(); }
  Measurement.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) : super(_opendaf) { updateConfigurationJson(cfg); }
  Measurement.fromRuntimeJson(this._opendaf, Map<String, dynamic> runtime) : super(_opendaf) { updateRuntimeJson(runtime); }

    /* Getters */
  Measurement get original => _original;
  String get id => this.name;
  String get className => "Measurement";
  String toString() => id;
  bool get isEditable => this.original != null;

  void cfg_stash()          => _original = this.dup();
  void cfg_revert()         => this.cfg_assign(_original);
  bool cfg_changed()        => !cfg_compare(_original);
  bool cfg_name_changed()   => this.name != this._original?.name;

  void updateRuntimeJson(Map<String, dynamic> runtime){
    if(runtime == null)
      return;

    super.updateRuntimeJson(runtime);
    if(runtime["vtq"] != null)  this.vtq = new VTQ.fromJson(runtime["vtq"]);

    this.runtimeLoaded = true;
	_opendaf.ctrl.measurement._ls.wsUpdateCounter++;
  }

  void updateConfigurationJson(Map<String, dynamic> cfg){
    if(cfg == null)
      return;

    super.updateConfigurationJson(cfg);
    if(cfg["deadband"] != null)           this.deadband           = cfg["deadband"];

    this.updateStackModules();

    this.cfg_stash();

    this.configurationLoaded = true;
	_opendaf.ctrl.measurement._ls.objectsLoadedCounter++;
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

  Map<String, dynamic> toCfgJson() {
    Map<String, dynamic> js = super.toCfgJson();
    _toJson(js, "deadband", deadband);
    return js;
  }


  /* --- Helpers --- */  
  String get smartValue => (vtq?.value == null) ? "--" : vtq.value;
  String get smartQuality => (vtq?.quality == null) ? "--" : vtq.quality.toRadixString(16).toUpperCase().padLeft(2, '0');
  String get smartQualityDesc => (vtq?.quality == null) ? "" : Quality.getDescription(vtq.quality);
  String get smartTimestamp => (vtq?.timestamp == null) ? "--" : (
    getDate(new DateTime.now()) == getDate(vtq.timestamp)
    ? new DateFormat("HH:mm:ss").format(vtq.timestamp)
    : vtq.timestamp.toString() 
  );
  static DateTime getDate(DateTime t) => new DateTime(t.year, t.month, t.day);

  void cfg_assign(Measurement other) {
    if(other == null)
      return;
      
    super.cfg_assign(other);
    this.deadband = other.deadband;

    this.cfg_stash();
  }

  bool cfg_compare(Measurement other){
    if(other == null)
      return false;

    return super.cfg_compare(other) && this.deadband == other.deadband;
  }

  Future simulate(dynamic value, int quality, {int validFor, int timestamp}) {
    if(datatype == null || datatype == Datatype.DT_EMPTY)
      return new Future.error("Can't simulate null measurement!");
    
    switch(datatype) {
      case Datatype.DT_BINARY:
        if(!(value is bool))
          return new Future.error("Simulate binary measurement argument must be bool");
        break;
        
      case Datatype.DT_QUATERNARY:
      case Datatype.DT_INTEGER:
      case Datatype.DT_LONG:
        if(!(value is int))
          return new Future.error("Simulate quaternary, integer and long measurement argument must be int");
        break;
        
      case Datatype.DT_FLOAT:
      case Datatype.DT_DOUBLE:
        if(!(value is num))
          return new Future.error("Simulate quaternary, integer and long measurement argument must be number");
        break;
        
      case Datatype.DT_STRING:
        break;
        
      default:
        return new Future.error("Unknown measurement data type '${datatype}'");
    }

    return _opendaf.simulateMeasurement(name, Value.formatAs(value, datatype), quality, validFor: validFor, timestamp: timestamp);
  }

  Future cancelSimulation() => _opendaf.stopMeasurementSimulation(name);

	dynamic operator[](String key) {
		switch(key){
			case "deadband":	return this.deadband;
			case "value": 		return this.vtq?.value;
			case "timestamp": 	return this.vtq?.timestamp;
			case "quality": 	return this.vtq?.quality;
			default: return super[key];
		}
	}
}