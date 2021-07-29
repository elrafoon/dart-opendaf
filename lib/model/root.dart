part of opendaf;

abstract class StreamEvent {}

class MeasurementsSetChanged extends StreamEvent{ }
class CommandsSetChanged extends StreamEvent{ }
class ConnectorsSetChanged extends StreamEvent{ }
class ProvidersSetChanged extends StreamEvent{ }
class ConnectorStacksSetChanged extends StreamEvent{ }
class ProviderStacksSetChanged extends StreamEvent{ }
class FunctionModulesSetChanged extends StreamEvent{ }
class AlarmsSetChanged extends StreamEvent{ }

class ModelException implements Exception {}
class ProviderAddressesException extends ModelException {
  String _msg;
  
  ProviderAddressesException(this._msg);
  String toString() => _msg;
}

class Root {
  final Map<String, Measurement> measurements = new SplayTreeMap<String, Measurement>();
  final Map<String, Command> commands = new SplayTreeMap<String, Command>();
  final Map<String, Connector> connectors = new SplayTreeMap<String, Connector>();
  final Map<String, Provider> providers = new SplayTreeMap<String, Provider>();
  final Map<String, Stack> connectorStacks = new SplayTreeMap<String, Stack>();
  final Map<String, Stack> providerStacks = new SplayTreeMap<String, Stack>();
  final Map<String, FunctionModule> functionModules = new SplayTreeMap<String, FunctionModule>();
  final Map<String, Alarm> alarms = new SplayTreeMap<String, Alarm>();

  bool measurementsLoaded, commandsLoaded, functionModulesLoaded, alarmsLoaded, connectorsLoaded, providersLoaded, connectorStacksLoaded, providerStacksLoaded;

  final StreamController<StreamEvent> eventController = new StreamController<StreamEvent>.broadcast();
  Stream<StreamEvent> eventStream;
  
  Root() {
    eventStream = eventController.stream;
  }
  
}

