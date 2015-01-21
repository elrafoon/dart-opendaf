part of opendaf;

class CommunicationObject {
  final String name, address;
  final int datatype, rawDatatype;
  final Range euRange, rawRange;
  
  CommunicationObject(this.name, this.address, this.datatype, this.rawDatatype, this.euRange, this.rawRange);
  
  CommunicationObject.fromJson(Map<String, dynamic> json) : this(json["name"], json["address"], json["datatype"],
      json["raw-datatype"], new Range.fromJson(json["eu-range"]), new Range.fromJson(json["raw-range"]));
}
