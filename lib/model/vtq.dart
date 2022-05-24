part of opendaf;

class VTQ extends VT {
	int quality;

	VTQ(var value, DateTime time, this.quality, int dataType) : super(value, time, dataType);

	VTQ.fromJson(List json) :
		this(
			(json == null) ? null : Value.parseValueWithPrefix(json[0]),
			(json == null) ? null : VT.parseTime(json[1]),
			(json == null) ? null : json[2],
			(json == null) ? null : Value.getDataType(json[0])
		);

	String getQualityClass() {
		if((quality & 0xC0) == 0xC0)
			return "quality-good";
		else if((quality & 0xC0) == 0x40)
			return "quality-uncertain";
		else
			return "quality-bad";
	}

	bool get isSimulated => Quality.isSimulated(quality);
}