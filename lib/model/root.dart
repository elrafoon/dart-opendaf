part of opendaf;

abstract class StreamEvent {}

// class MeasurementsSetChanged extends StreamEvent{ }
// class CommandsSetChanged extends StreamEvent{ }
// class ConnectorsSetChanged extends StreamEvent{ }
// class ProvidersSetChanged extends StreamEvent{ }
// class ConnectorStackChanged extends StreamEvent{ }
// class ProviderStackChanged extends StreamEvent{ }
// class FunctionModulesSetChanged extends StreamEvent{ }
class AlarmsSetChanged extends StreamEvent{ }

class Root {
  // final Map<String, Measurement> measurements = new SplayTreeMap<String, Measurement>();
  // final Map<String, Command> commands = new SplayTreeMap<String, Command>();
  // final Map<String, Connector> connectors = new SplayTreeMap<String, Connector>();
  // final Map<String, Provider> providers = new SplayTreeMap<String, Provider>();
  // final Map<String, Stack> connectorStacks = new SplayTreeMap<String, Stack>();
  // final Map<String, Stack> providerStacks = new SplayTreeMap<String, Stack>();
  // final Map<String, FunctionModule> functionModules = new SplayTreeMap<String, FunctionModule>();
  final Map<String, Alarm> alarms = new SplayTreeMap<String, Alarm>();

  // Future measurementsLoaded, commandsLoaded, connectorsLoaded, providersLoaded;
  // Future connectorStacksLoaded, providerStacksLoaded;
  // Future functionModulesLoaded;
  
 
  // Future rootLoaded; String loadingStep; int loadingSteps = 7;
  
  // bool fullModelLoaded = false;

  final StreamController<StreamEvent> eventController = new StreamController<StreamEvent>.broadcast();
  Stream<StreamEvent> eventStream;
  
  Root() {
    eventStream = eventController.stream;
  }
  
}

