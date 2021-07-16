part of opendaf;

class Measurement extends CommunicationObject {
  final OpenDAF _opendaf;

  Measurement _original;
  Measurement get original => _original;

  VTQ vtq;

  Measurement(this._opendaf, name, address, datatype, rawDatatype, euRange, rawRange, this.vtq) :
    super(name, address, datatype, rawDatatype, euRange, rawRange);

  // Measurement.fromJson(Map<String, dynamic> json) : this(json["name"], json["address"], Datatype.fromPrefix(json["datatype"]),
  //     Datatype.fromPrefix(json["raw-datatype"]), new Range.fromJson(json["eu-range"]), new Range.fromJson(json["raw-range"]),
  //     new VTQ.fromJson(json["vtq"]));

  Measurement.fromRuntimeJson(this._opendaf, Map<String, dynamic> runtime) : super(null, null, null, null, null, null) {
      updateRuntimeJson(runtime);
  }

  void updateRuntimeJson(Map<String, dynamic> runtime){
    if(runtime == null)
      return;
    print("Measurement: updateRuntimeJson() not implemented!");

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
}