part of opendaf;

class Measurement {
  final String name, address, datatype, rawDatatype;
  final Range euRange, rawRange;
  final VTQ vtq;
  
  Measurement(this.name, this.address, this.datatype, this.rawDatatype, this.euRange, this.rawRange, this.vtq);
  
  Measurement.fromJson(Map<String, dynamic> json) : this(json["name"], json["address"], json["datatype"],
      json["raw-datatype"], new Range.fromJson(json["eu-range"]), new Range.fromJson(json["raw-range"]),
      new VTQ.fromJson(json["vtq"]));
}
