part of opendaf;

class Descriptor {
	Map<String, String> measurements = new Map<String, String>();
	Map<String, String> commands = new Map<String, String>();
	Map<String, String> alarms = new Map<String, String>();

	Descriptor([this.measurements, this.commands, this.alarms]);

	Descriptor.fromJson(Map<String, dynamic> js) :
		measurements	= new Map<String, String>.from(js["measurements"] ?? {}),
		commands		= new Map<String, String>.from(js["commands"] ?? {}),
		alarms			= new Map<String, String>.from(js["alarms"] ?? {})
	;	
}
