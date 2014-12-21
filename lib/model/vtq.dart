part of opendaf;

class VTQ extends VT {
    int quality;

    VTQ(var value, DateTime time, this.quality, String dataType) : super(value, time, dataType);

    VTQ.fromJson(List json) : this(Value.parseValueWithPrefix(json[0]), VT.parseTime(json[1]), json[2], Value.getDataType(json[0]));

    String getQualityClass() {
      if((quality & 0xC0) == 0xC0)
        return "quality-good";
      else if((quality & 0xC0) == 0x40)
        return "quality-uncertain";
      else
        return "quality-bad";
    }
}