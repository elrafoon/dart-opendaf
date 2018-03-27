part of opendaf;

class Measurement extends CommunicationObject {
  VTQ vtq;
  
  Measurement(name, address, datatype, rawDatatype, euRange, rawRange, this.vtq) :
    super(name, address, datatype, rawDatatype, euRange, rawRange);
  
  Measurement.fromJson(Map<String, dynamic> json) : this(json["name"], json["address"], Datatype.fromPrefix(json["datatype"]),
      Datatype.fromPrefix(json["raw-datatype"]), new Range.fromJson(json["eu-range"]), new Range.fromJson(json["raw-range"]),
      new VTQ.fromJson(json["vtq"]));
}
