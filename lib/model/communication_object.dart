part of opendaf;

class CommunicationObject {
  static const String AM_NONE = "none", AM_CHANGE = "change", AM_PERIODIC = "periodic";

  final OpenDAF _opendaf;
  
  // Runtime 
  String name;
  String address;
  int datatype;
  int rawDatatype;
  Range euRange;
  Range rawRange;

  // Configuration
  String description;
  String connectorName;
  String euRangeLow;
  String euRangeHigh;
  String rawRangeLow;
  String rawRangeHigh;
  Map<String, String> providerAddresses;
  String archMode = "none";
  int archPeriod = 1000; // [] = ms
  String archValueDeadband;
  int archTimeDeadband = 0; // [] = ms
  String leader;
  int stackUmask = 0;
  String eu;
  bool enabled = true;
  Map<String, dynamic> properties = new Map<String, dynamic>();
  
  CommunicationObject(this._opendaf, {this.name, this.description, this.connectorName, this.address, this.datatype,
          this.euRangeLow, this.euRangeHigh, this.rawDatatype, this.rawRangeLow, this.rawRangeHigh,
          this.providerAddresses, this.archMode, this.archPeriod, this.archValueDeadband, this.archTimeDeadband, this.leader,
          this.stackUmask, this.eu, this.enabled, this.properties});

  void updateRuntimeJson(Map<String, dynamic> runtime){
    if(runtime == null)
      return;

    if(runtime["name"] != null)           this.name         = runtime["name"];
    if(runtime["address"] != null)        this.address      = runtime["address"];    
    if(runtime["datatype"] != null)       this.datatype     = Datatype.fromPrefix(runtime["datatype"]);    
    if(runtime["raw-datatype"] != null)   this.rawDatatype  = Datatype.fromPrefix(runtime["raw-datatype"]);
    if(runtime["eu-range"] != null)       this.euRange      = new Range.fromJson(runtime["eu-range"]);
    if(runtime["raw-range"] != null)      this.rawRange     = new Range.fromJson(runtime["raw-range"]);
  }

  void updateConfigurationJson(Map<String, dynamic> cfg){
    if(cfg == null)
      return;

    if(cfg["name"] != null)               this.name               = cfg["name"];      
    if(cfg["description"] != null)        this.description        = cfg["description"];
    if(cfg["connectorName"] != null)      this.connectorName      = cfg["connectorName"];
    if(cfg["address"] != null)            this.address            = cfg["address"];
    if(cfg["datatype"] != null)           this.datatype           = cfg["datatype"];
    if(cfg["euRangeLow"] != null)         this.euRangeLow         = cfg["euRangeLow"];
    if(cfg["euRangeHigh"] != null)        this.euRangeHigh        = cfg["euRangeHigh"];      
    if(cfg["rawDataType"] != null)        this.rawDatatype        = Datatype.fromPrefix(cfg["rawDataType"]);
    if(cfg["rawRangeLow"] != null)        this.rawRangeLow        = cfg["rawRangeLow"];
    if(cfg["rawRangeHigh"] != null)       this.rawRangeHigh       = cfg["rawRangeHigh"];
    if(cfg["providerAddresses"] != null)  this.providerAddresses  = cfg["providerAddresses"];
    if(cfg["archMode"] != null)           this.archMode           = cfg["archMode"];
    if(cfg["archPeriod"] != null)         this.archPeriod         = cfg["archPeriod"];
    if(cfg["archValueDeadband"] != null)  this.archValueDeadband  = cfg["archValueDeadband"];
    if(cfg["archTimeDeadband"] != null)   this.archTimeDeadband   = cfg["archTimeDeadband"];
    if(cfg["leader"] != null)             this.leader             = cfg["leader"];
    if(cfg["stackUmask"] != null)         this.stackUmask         = cfg["stackUmask"];
    if(cfg["eu"] != null)                 this.eu                 = cfg["eu"];
    if(cfg["enabled"] != null)            this.enabled            = cfg["enabled"];
    if(cfg["properties"] != null)         this.properties         = cfg["properties"];
  }

  void cfg_assign(CommunicationObject other) {
    if(other == null)
      return;
      
    this.name               = other.name;
    this.description        = other.description;
    this.connectorName      = other.connectorName;
    this.address            = other.address;
    this.datatype           = other.datatype;
    this.euRangeLow         = other.euRangeLow;
    this.euRangeHigh        = other.euRangeHigh;
    this.rawDatatype        = other.rawDatatype;
    this.rawRangeLow        = other.rawRangeLow;
    this.rawRangeHigh       = other.rawRangeHigh;
    this.providerAddresses  = other.providerAddresses;
    this.archMode           = other.archMode;
    this.archPeriod         = other.archPeriod;
    this.archValueDeadband  = other.archValueDeadband;
    this.archTimeDeadband   = other.archTimeDeadband;
    this.leader             = other.leader;
    this.stackUmask         = other.stackUmask;
    this.eu                 = other.eu;
    this.enabled            = other.enabled;
    this.properties         = other.properties;
  }

  bool cfg_compare(CommunicationObject other){
    if(other == null)
      return false;

    bool propertiesMatch = true;
    this.properties.forEach((key, value) {
      if(value != other.properties[key]){
        propertiesMatch = false;
      }
    });

    return propertiesMatch &&
      this.name               == other.name               &&
      this.description        == other.description        &&
      this.connectorName      == other.connectorName      &&
      this.address            == other.address            &&
      this.datatype           == other.datatype           &&
      this.euRangeLow         == other.euRangeLow         &&
      this.euRangeHigh        == other.euRangeHigh        &&
      this.rawDatatype        == other.rawDatatype        &&
      this.rawRangeLow        == other.rawRangeLow        &&
      this.rawRangeHigh       == other.rawRangeHigh       &&
      this.providerAddresses  == other.providerAddresses  &&
      this.archMode           == other.archMode           &&
      this.archPeriod         == other.archPeriod         &&
      this.archValueDeadband  == other.archValueDeadband  &&
      this.archTimeDeadband   == other.archTimeDeadband   &&
      this.leader             == other.leader             &&
      this.stackUmask         == other.stackUmask         &&
      this.eu                 == other.eu                 &&
      this.enabled            == other.enabled       
    ;
  }

  Map<String, dynamic> toCfgJson() => {
    "name":               name,
    "description":        description,
    'connectorName':      connectorName,
    'address':            address,
    'datatype':           Datatype.toPrefix(datatype),
    'euRangeLow':         euRangeLow,
    'euRangeHigh':        euRangeHigh,
    'rawDatatype':        Datatype.toPrefix(rawDatatype),
    'rawRangeLow':        rawRangeLow,
    'rawRangeHigh':       rawRangeHigh,
    'providerAddresses':  providerAddresses,
    'archMode':           archMode,
    'archPeriod':         archPeriod,
    'archValueDeadband':  archValueDeadband,
    'archTimeDeadband':   archTimeDeadband,
    'leader':             leader,
    'stackUmask':         stackUmask,
    'eu':                 eu,
    "enabled":            enabled,
    'properties':         properties
  };
  

  static dynamic toDataType(String value, int datatype) {
    if(value == null)
      return null;
    
    switch(datatype) {
      case Datatype.DT_BINARY:
        return value.isEmpty ? null : int.parse(value) != 0;
      case Datatype.DT_QUATERNARY:
      case Datatype.DT_INTEGER:
      case Datatype.DT_LONG:
        return value.isEmpty ? null : int.parse(value);
      case Datatype.DT_FLOAT:
      case Datatype.DT_DOUBLE:
        return value.isEmpty ? null : double.parse(value);
      case Datatype.DT_STRING:
        return value;
      default:
        return null;
    }
  }

  dynamic get euRangeLowValue => toDataType(euRangeLow, datatype);
  dynamic get euRangeHighValue => toDataType(euRangeHigh, datatype);
  dynamic get rawRangeLowValue => toDataType(rawRangeLow, rawDatatype);
  dynamic get rawRangeHighValue => toDataType(rawRangeHigh, rawDatatype);

  Map<String, String> dupProviderAddresses() {
    Map<String, String> d = new Map<String, String>();
    d.addAll(providerAddresses);
    return d;
  }

}
