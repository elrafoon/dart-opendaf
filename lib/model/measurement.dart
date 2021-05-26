part of opendaf;

class Measurement extends CommunicationObject {
  VTQ vtq;

  Measurement(name, address, datatype, rawDatatype, euRange, rawRange, this.vtq) :
    super(name, address, datatype, rawDatatype, euRange, rawRange);

  Measurement.fromJson(Map<String, dynamic> json) : this(json["name"], json["address"], Datatype.fromPrefix(json["datatype"]),
      Datatype.fromPrefix(json["raw-datatype"]), new Range.fromJson(json["eu-range"]), new Range.fromJson(json["raw-range"]),
      new VTQ.fromJson(json["vtq"]));


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