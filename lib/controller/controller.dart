part of opendaf;

class Controller {
  final http.Client _http;
  final OpenDAF _opendaf;

  AlarmController alarm;
  FunctionModuleController fm;

  Controller (this._opendaf, this._http){
    alarm = new AlarmController(this._opendaf, this._http);
    fm = new FunctionModuleController(this._opendaf, this._http);
  }

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