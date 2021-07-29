part of opendaf;

class Measurement extends CommunicationObject {
  static const int MS_WATCHDOG = 1, MS_SCALER = 2, MS_DEDUPLICATOR = 4, MS_DEADBAND = 8;

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
      properties: properties
    );

  Measurement dup() => new Measurement(_opendaf, 
      name: name, 
      description: description, 
      connectorName: connectorName, 
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
      properties: properties
    );

  Measurement.empty(this._opendaf) : super(_opendaf);
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
  }

  void updateConfigurationJson(Map<String, dynamic> cfg){
    if(cfg == null)
      return;

    super.updateConfigurationJson(cfg);
    if(cfg["deadband"] != null)           this.deadband           = cfg["deadband"];

    this.cfg_stash();
  }

  Map<String, dynamic> toCfgJson() {
    Map<String, dynamic> js = super.toCfgJson();
    js['deadband'] = deadband;
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
}