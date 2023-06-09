part of opendaf;

abstract class StreamEvent {}

class MeasurementUpdated extends StreamEvent{ VTQ vtq; }
class CommandWritten extends StreamEvent{ VT vt; }

class MeasurementsSetChanged extends StreamEvent{ }
class CommandsSetChanged extends StreamEvent{ }
class ConnectorsSetChanged extends StreamEvent{ }
class ProvidersSetChanged extends StreamEvent{ }
class ConnectorStacksSetChanged extends StreamEvent{ }
class ProviderStacksSetChanged extends StreamEvent{ }
class FunctionModulesSetChanged extends StreamEvent{ }
class AlarmsSetChanged extends StreamEvent{ }
class AlarmGroupsSetChanged extends StreamEvent{ }
class OpendafRootLoaded extends StreamEvent{ }

class ModelException implements Exception {}
class ProviderAddressesException extends ModelException {
	String _msg;
	
	ProviderAddressesException(this._msg);
	String toString() => _msg;
}

class OpendafRoot {
	final OpenDAF _opendaf;

	final Map<String, Measurement> measurements = new SplayTreeMap<String, Measurement>();
	final Map<String, Command> commands = new SplayTreeMap<String, Command>();
	final Map<String, Connector> connectors = new SplayTreeMap<String, Connector>();
	final Map<String, Provider> providers = new SplayTreeMap<String, Provider>();
	final Map<String, Stack> connectorStacks = new SplayTreeMap<String, Stack>();
	final Map<String, Stack> providerStacks = new SplayTreeMap<String, Stack>();
	final Map<String, FunctionModule> functionModules = new SplayTreeMap<String, FunctionModule>();
	final Map<String, Alarm> alarms = new SplayTreeMap<String, Alarm>();
	final Map<String, AlarmGroup> alarmGroups = new SplayTreeMap<String, AlarmGroup>();

	bool loaded;
	bool measurementsLoaded, commandsLoaded, functionModulesLoaded, alarmsLoaded, alarmGroupsLoaded, connectorsLoaded, providersLoaded, connectorStacksLoaded, providerStacksLoaded;

	final StreamController<StreamEvent> eventController = new StreamController<StreamEvent>.broadcast();
	Stream<StreamEvent> eventStream;

	OpendafRoot(this._opendaf) {
		eventStream = eventController.stream;
		eventStream.where((StreamEvent evt) => evt is OpendafRootLoaded).listen((StreamEvent evt) => this.loaded = true);
	}

	Measurement getMeasurement(String name, { bool autocreate = false }){
		if(measurements[name] == null){
			_opendaf.log("Measurement $name does not exists" + (autocreate ? ", auto-creating one." : ''));
			if(autocreate)
				measurements[name] = new Measurement(_opendaf, name: name);
		}
		return measurements[name];
	}
	Measurement getMeasurementFromDesc(String key, Descriptor desc, { bool autocreate = true }){
		return desc.measurements[key] != null ? getMeasurement(desc.measurements[key], autocreate: autocreate) : null;
	}

	Command getCommand(String name, { bool autocreate = false }){
		if(commands[name] == null){
			_opendaf.log("Command $name does not exists" + (autocreate ? ", auto-creating one." : ''));
			if(autocreate)
				commands[name] = new Command(_opendaf, name: name);
		}
		return commands[name];
	}
	Command getCommandFromDesc(String key, Descriptor desc, { bool autocreate = true }){
		return desc.commands[key] != null ? getCommand(desc.commands[key], autocreate: autocreate) : null;
	}

	Alarm getAlarm(String name, { bool autocreate = false }){
		if(alarms[name] == null){
			_opendaf.log("Alarm $name does not exists" + (autocreate ? ", auto-creating one." : ''));
			if(autocreate)
				alarms[name] = new Alarm(_opendaf, name: name);
		}
		return alarms[name];
	}
	Alarm getAlarmFromDesc(String key, Descriptor desc, { bool autocreate = true }){
		return desc.alarms[key] != null ? getAlarm(desc.alarms[key], autocreate: autocreate) : null;
	}
}

_toJson(Map<String, dynamic> source, String key, dynamic value){
	if(value == null || (value.runtimeType == String && (value as String).length == 0))
		source[key] = null;
	else
		source[key] = value;
}