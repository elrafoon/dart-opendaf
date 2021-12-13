part of opendaf;

class StackInstantiation {
  final OpenDAF _opendaf;

  StackInstantiation _original;

  // Configuration
  String name, stackName;
  Map<String, dynamic> vars = new Map<String, dynamic>();
  String wdtMeasurementName;

  Map<String, dynamic> properties = new Map<String, dynamic>();
  bool configurationLoaded;
  
  StackInstantiation(this._opendaf, { this.name, this.stackName, this.vars, this.wdtMeasurementName, this.properties });
  StackInstantiation dup() => new StackInstantiation(_opendaf,
    name:               name,
    stackName:          stackName,
    vars:               vars != null ? new Map<String, dynamic>.from(vars) : new Map<String, dynamic>(),
    wdtMeasurementName: wdtMeasurementName,
    properties:         properties != null ? new Map<String, dynamic>.from(properties) : new Map<String, dynamic>()
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

  String get varsAsText {
    StringBuffer s = new StringBuffer();
    vars.forEach((k, v) {
      s.write("$k:${v == null ? '' : v.toString()}\n");
    });
    return s.toString();
  }

  void set varsAsText(String value) {
    Map<String, String> map = new Map<String, String>();
    value.split("\n").map((String _) => _.trim()).where((String _) => _.length > 0).forEach((String row) {
      int ixSep = row.indexOf(":");
      if(ixSep == -1)
        throw new ProviderAddressesException("Row '$row' does not contain separator ':'!");
      map[row.substring(0, ixSep)] = row.substring(ixSep+1);
    });
    vars = map;
  }

  static Map<String, dynamic> varsToJson(Stack stack, Map<String, String> vars) {
    Map<String, dynamic> json = {};
    stack.parameters.forEach((String param, Map<String, dynamic> cfg) {
      var i = vars[param];
      var o;
      if(i != null && i.isNotEmpty) {
        try {
          switch(cfg["type"]) {
            case "enum":
              o = stack.parameters[param]['enum'].firstWhere((e) => e.toString() == i.toString(), orElse: () => null);
              break;
            case "boolean":
              o = (i == '1');
              break;
            case "float":
              o = double.parse(i);
              break;
            case "int":
            case "integer":
              o = int.parse(i);
              break;
            default:
            // string
            // regex
            // hostname
            // iec-60870-5-structured-address
            // list_of_inet_addr
            // tty
              o = i.toString();
              break;
          }
        }
        catch(e) {
          print("Can't convert '$i' (${i.runtimeType}) to ${cfg["type"]}! ($e)");
        }
      }
      json[param] = o;
      });
      return json;
    }

  void updateConfigurationJson(Map<String, dynamic> cfg){
    if(cfg == null)
      return;

    if(cfg["name"] != null)               this.name               = cfg["name"];      
    if(cfg["stackName"] != null)          this.stackName          = cfg["stackName"];
    if(cfg["vars"] != null)               this.vars               = cfg["vars"];
    if(cfg["wdtMeasurementName"] != null) this.wdtMeasurementName = cfg["wdtMeasurementName"];
    if(cfg["properties"] != null)         this.properties         = cfg["properties"];

    this.cfg_stash();

    this.configurationLoaded = true;
  }

  void cfg_assign(StackInstantiation other) {
    if(other == null)
      return;
      
    this.name               = other.name;
    this.stackName          = other.stackName;
    this.vars               = new Map<String, dynamic>.from(other.vars);
    this.wdtMeasurementName = other.wdtMeasurementName;
    this.properties         = new Map<String, dynamic>.from(other.properties);

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

  bool hasMatch(RegExp regex) => 
       regex.hasMatch(name ?? "")
    || regex.hasMatch(stackName ?? "")
    || regex.hasMatch(wdtMeasurementName ?? "")
    || regex.hasMatch(varsAsText ?? "")
  ;

	dynamic operator[](String key) {
		switch(key){
			case "name": 				return this.name;
			case "stackName": 			return this.stackName;
			case "vars": 				return this.vars;
			case "wdtMeasurementName": 	return this.wdtMeasurementName;
			default:					return this.properties[key];
		}
	}
}
