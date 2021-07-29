part of opendaf;

class StackInstantiation {
  final OpenDAF _opendaf;

  StackInstantiation _original;

  // Configuration
  String name, stackName;
  Map<String, String> vars;
  String wdtMeasurementName;

  Map<String, dynamic> properties = new Map<String, dynamic>();
  
  StackInstantiation(this._opendaf, { this.name, this.stackName, this.vars, this.wdtMeasurementName, this.properties });
  StackInstantiation dup() => new StackInstantiation(_opendaf,
    name:               name,
    stackName:          stackName,
    vars:               new Map<String, String>.from(vars),
    wdtMeasurementName: wdtMeasurementName,
    properties:         new Map<String, dynamic>.from(properties)
  );  
  StackInstantiation.empty(this._opendaf);

  /* Getters */
  String get id => this.name;
  StackInstantiation get original => _original;
  bool get isEditable => this.original != null;
  String toString() => id;

  void cfg_stash()          => _original = this.dup();
  void cfg_revert()         => this.cfg_assign(_original);
  bool cfg_changed()        => !cfg_compare(_original);
  bool cfg_name_changed()   => this.name != this._original?.name;

  void updateConfigurationJson(Map<String, dynamic> cfg){
    if(cfg == null)
      return;

    if(cfg["name"] != null)               this.name               = cfg["name"];      
    if(cfg["stackName"] != null)          this.stackName          = cfg["stackName"];
    if(cfg["vars"] != null)               this.vars               = cfg["vars"];
    if(cfg["wdtMeasurementName"] != null) this.wdtMeasurementName = cfg["wdtMeasurementName"];
    if(cfg["properties"] != null)         this.properties         = cfg["properties"];

    this.cfg_stash();
  }

  void cfg_assign(StackInstantiation other) {
    if(other == null)
      return;
      
    this.name               = other.name;
    this.stackName          = other.stackName;
    this.vars               = other.vars;
    this.wdtMeasurementName = other.wdtMeasurementName;
    this.properties         = other.properties;

    this.cfg_stash();
  }

  bool cfg_compare(StackInstantiation other){
    if(other == null)
      return false;

    bool propertiesMatch = true;
    this.properties.forEach((key, value) {
      if(value != other.properties[key]){
        propertiesMatch = false;
      }
    });

    bool varsMatch = true;
    this.vars.forEach((key, value) {
      if(value != other.vars[key]){
        varsMatch = false;
      }
    });

    return propertiesMatch && varsMatch &&
      this.name               == other.name         &&
      this.stackName          == other.stackName   &&
      this.wdtMeasurementName == other.wdtMeasurementName    
    ;
  }

  Map<String, dynamic> toCfgJson() => {
    "name":               name,
    "stackName":          stackName,
    'vars':               vars,
    'wdtMeasurementName': wdtMeasurementName,
    'properties':         properties
  };

}
