part of opendaf;

class StackModule {
  String name;
  int id;
  bool _enabled;
  
  CommunicationObject parent;
  
  bool get enabled => _enabled;
  void set enabled(bool en) {
    if (en)
      parent?.stackUmask |= id;
    else
      parent?.stackUmask &= ~id;
    _enabled = en;
  }
  
  StackModule(this.name, this.id, [this._enabled = false]);
}
class Stack {
  final OpenDAF _opendaf;

  Stack _original;

  String name;
  Map<String, dynamic> description = new Map<String, dynamic>();
  Map<String, String> defaults = new Map<String, String>();
  Map<String, dynamic> defaultPreload = new Map<String, dynamic>();
  
  Stack(this._opendaf, {this.name, this.description, this.defaults});
  Stack.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) { updateConfigurationJson(cfg); }
  Stack dup() => new Stack(_opendaf,
    name:         name,
    description:  new Map<String, dynamic>.from(description),
    defaults:     new Map<String, dynamic>.from(defaults)
  );  

  Stack get original => _original;
  String get id => this.name;
  String get className => "Stack";
  String toString() => id;

  Map<String, dynamic> get parameters => description["parameters"];
  Map<String, dynamic> get measurement => description["measurement"];
  Map<String, dynamic> get command => description["command"];
  bool get measurementEnabled => measurement != null && measurement["enabled"] == true;
  bool get commandEnabled => command != null && command["enabled"] == true;

  void updateConfigurationJson(Map<String, dynamic> cfg){
    if(cfg == null)
      return;

    if(cfg["name"] != null)               this.name               = cfg["name"];      
    if(cfg["description"] != null)        this.description        = cfg["description"];
    if(cfg["defaults"] != null)           this.defaults           = cfg["defaults"];

    if(parameters != null) {
      parameters.forEach((String name, Map<String, dynamic> value) {
        defaultPreload[name] = value["default"];
      });
    }
  }

  static Map<String, String> parseDefaults(String rawDefaults) {
    Map<String, String> m = new Map<String, String>();
    rawDefaults.split("\n").where((line) => line.isNotEmpty).forEach((String line) {
      List<String> p = line.split("=");
      m[p[0]] = p[1];
    });
    return m;
  }
}