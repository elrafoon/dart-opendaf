part of opendaf;

class Controller {
  final http.Client _http;
  final OpenDAF _opendaf;

  AlarmController alarm;
  FunctionModuleController fm;
  MeasurementController measurement;
  CommandController command;
  ConnectorController connector;
  ConnectorStackController connectorStack;
  ProviderController provider;
  ProviderStackController providerStack;

  Controller (this._opendaf, this._http){
    alarm           = new AlarmController(this._opendaf, this._http);
    fm              = new FunctionModuleController(this._opendaf, this._http);
    measurement     = new MeasurementController(this._opendaf, this._http);
    command         = new CommandController(this._opendaf, this._http);
    connector       = new ConnectorController(this._opendaf, this._http);
    connectorStack  = new ConnectorStackController(this._opendaf, this._http);
    provider        = new ProviderController(this._opendaf, this._http);
    providerStack   = new ProviderStackController(this._opendaf, this._http);
  }

  Future reload({RequestOptions options}) => Future.wait([
    connectorStack.reload(options: options),
    connector.reload(options: options),
    providerStack.reload(options: options),
    provider.reload(options: options),
    command.reload(options: options),
    measurement.reload(options: options),
    alarm.reload(options: options),
    fm.reload(options: options),
  ]);

}

class RequestOptions {
  static const int LOAD_MODE_PARALLEL = 0, LOAD_MODE_SEQUENTIALLY = 1;

  Iterable<String> names = null;
  Iterable<String> fields = null; 
  bool fetchRuntime = true; 
  bool fetchConfiguration = false;

  RequestOptions({this.names, this.fields, this.fetchRuntime, this.fetchConfiguration});

  RequestOptions dup() => new RequestOptions(names: this.names, fields: this.fields, fetchRuntime: this.fetchRuntime, fetchConfiguration: this.fetchConfiguration);

  String toString() => "fetchRuntime: $fetchRuntime, fetchConfiguration: $fetchConfiguration, names: $names, fields: $fields";
}