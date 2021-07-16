part of opendaf;

class Command extends CommunicationObject {
  final OpenDAF _opendaf;

  Command _original;
  Command get original => _original;


  VT vt;
  
  Command(this._opendaf, name, address, datatype, rawDatatype, euRange, rawRange, this.vt) :
    super(name, address, datatype, rawDatatype, euRange, rawRange);
  
  // Command.fromJson(Map<String, dynamic> json) : this(json["name"], json["address"], Datatype.fromPrefix(json["datatype"]),
  //     Datatype.fromPrefix(json["raw-datatype"]), new Range.fromJson(json["eu-range"]), new Range.fromJson(json["raw-range"]),
  //     new VT.fromJson(json["vt"]));

  Command.fromRuntimeJson(this._opendaf, Map<String, dynamic> runtime) : super(null, null, null, null, null, null) {
      updateRuntimeJson(runtime);
  }

  void updateRuntimeJson(Map<String, dynamic> runtime){
    if(runtime == null)
      return;
    print("Command: updateRuntimeJson() not implemented!");

    // if(runtime["name"] != null)
    //   this.name = runtime["name"];
    // if(runtime["state"] != null)
    //   this.state = decodeState(runtime["state"]);
    // if(runtime["timestamp"] != null)
    //   this.timestamp = VT.parseTime(runtime["timestamp"]);
    // if(runtime["authority"] != null)
    //   this.authority = runtime["authority"];
    // if(runtime["description"] != null)
    //   this.description = runtime["description"];
    // if(runtime["severity"] != null)
    //   this.severity = runtime["severity"];
  }
}
