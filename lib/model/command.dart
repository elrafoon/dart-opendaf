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
    ) { this.updateStackModules(); }

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
  

  Command.empty(this._opendaf) : super(_opendaf, 
    providerAddresses : new Map<String, String>(),
    stackUmask: 0,
    archMode: "none",
    archPeriod: 1000,
    archTimeDeadband: 0,
    enabled: true,
    properties: new Map<String, String>()
  );

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
  }

  void updateConfigurationJson(Map<String, dynamic> cfg){
    if(cfg == null)
      return;

    super.updateConfigurationJson(cfg);
    if(cfg["initialValue"] != null)       this.initialValue       = cfg["initialValue"];

    this.updateStackModules();
    this.cfg_stash();
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
    js['initialValue'] = initialValue;
    return js;
  }
}
