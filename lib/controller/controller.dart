part of opendaf;

class Controller {
  final http.Client _http;
  final OpenDAF _opendaf;

  AlarmController alarm;

  Controller (this._opendaf, this._http){
    alarm = new AlarmController(this._opendaf, this._http);
  }

}

class RequestOptions {
  Iterable<String> names = null;
  Iterable<String> fields = null; 
  bool fetchRuntime = true; 
  bool fetchConfiguration = false;

  RequestOptions({this.names, this.fields, this.fetchRuntime, this.fetchConfiguration});
}