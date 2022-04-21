part of opendaf;

class Descriptor {
	final Map<String, String> measurements;
	final Map<String, String> commands;
	final Map<String, String> alarms;

	Descriptor([this.measurements, this.commands, this.alarms]);

	Descriptor.fromJson(Map<String, dynamic> js) :
		measurements	= js["measurements"],
		commands		= js["commands"],
		alarms			= js["alarms"]
	;	
}
