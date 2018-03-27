part of opendaf;

class Command extends CommunicationObject {
  VT vt;
  
  Command(name, address, datatype, rawDatatype, euRange, rawRange, this.vt) :
    super(name, address, datatype, rawDatatype, euRange, rawRange);
  
  Command.fromJson(Map<String, dynamic> json) : this(json["name"], json["address"], Datatype.fromPrefix(json["datatype"]),
      Datatype.fromPrefix(json["raw-datatype"]), new Range.fromJson(json["eu-range"]), new Range.fromJson(json["raw-range"]),
      new VT.fromJson(json["vt"]));
}
