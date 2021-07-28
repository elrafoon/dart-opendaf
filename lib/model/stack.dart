part of opendaf;

class Stack {
  final OpenDAF _opendaf;

  Stack _original;
  Stack get original => _original;

  String name;
  Map<String, dynamic> description;
  Map<String, String> defaults;
  
  Stack(this._opendaf, {this.name, this.description, this.defaults});
  Stack.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) { updateConfigurationJson(cfg); }
  Stack dup() => new Stack(_opendaf,
    name:         name,
    description:  description,
    defaults:     defaults
  );  

  void updateConfigurationJson(Map<String, dynamic> cfg){
    if(cfg == null)
      return;

    if(cfg["name"] != null)               this.name               = cfg["name"];      
    if(cfg["description"] != null)        this.description        = cfg["description"];
    if(cfg["defaults"] != null)           this.defaults           = parseDefaults(cfg["defaults"]);
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