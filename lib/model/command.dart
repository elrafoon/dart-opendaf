part of opendaf;

class Command extends CommunicationObject {
  static const int CS_SCALER = 2;

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

  Command dup() => new Command(_opendaf, 
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
  

  Command.empty(this._opendaf) : super(_opendaf);
  Command.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) : super(_opendaf) { updateConfigurationJson(cfg); }
  Command.fromRuntimeJson(this._opendaf, Map<String, dynamic> runtime) : super(_opendaf) { updateRuntimeJson(runtime); }

    /* Getters */
  Command get original => _original;
  String get id => this.name;
  String get className => "Command";
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
    if(runtime["vt"] != null)  this.vt = new VT.fromJson(runtime["vt"]);
  }

  void updateConfigurationJson(Map<String, dynamic> cfg){
    if(cfg == null)
      return;

    super.updateConfigurationJson(cfg);
    if(cfg["initialValue"] != null)       this.initialValue       = cfg["initialValue"];

    this.cfg_stash();
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
    js['initialValue'] = initialValue;
    return js;
  }
}
