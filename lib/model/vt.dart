part of opendaf;

class VT {
    var value;
    DateTime timestamp;
    int dataType;

    VT(this.value, this.timestamp, this.dataType);

    VT.fromJson(List json) : 
      this(
          (json == null) ? null : Value.parseValueWithPrefix(json[0]),
          (json == null) ? null : parseTime(json[1]),
          Value.getDataType(json[0])
      );

    /**
     * Converts list in form [seconds, microseconds] to DateTime.
     */
    static DateTime parseTime(List<num> time) {
      return new DateTime.fromMillisecondsSinceEpoch((time[0]*1000) + (time[1] ~/ 1000), isUtc: true).toLocal();
    }
}