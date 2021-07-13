part of opendaf;

class AlarmController {
  final http.Client _http;
  final OpenDAF _opendaf;

  RequestOptions _options;

  AlarmController(this._opendaf, this._http);

  Set<String> get properties {
    Set<String> res = new Set<String>();
    _opendaf.root.alarms.values.forEach((a) => res.addAll(a.properties.keys));
    return res;
  } 

  Future reload({RequestOptions options}) {
    return list(options: options)
      .then((Map<String, Alarm> _) {
        _options = options;
        _opendaf.root.alarms.clear();
        _opendaf.root.alarms.addAll(_);
      })
      .then((_) {
         _opendaf.root.eventController.add(new AlarmsSetChanged());
      });
  }

  Future<Alarm> item(String name, {bool fetchRuntime = true, bool fetchConfiguration = false}) {
    return Future.wait([
      fetchConfiguration ? _http.get("${OpenDAF.dafmanPrefix}/alarms/$name", headers: OpenDAF._headers) : new Future.value(null),
      fetchRuntime ? _http.get("${OpenDAF.prefix}/alarms/$name", headers: OpenDAF._headers) : new Future.value(null)
    ]).then((List<http.Response> response) {
      Alarm alarm = new Alarm.fromRuntimeJson(this._opendaf, OpenDAF._json(response[1]));
      if(fetchConfiguration){
        alarm.updateConfigurationJson(OpenDAF._json(response[0]));
      }
      return alarm;
    });
  }

  Future<Map<String, Alarm>> list({RequestOptions options}) {
    String optNames, optFields;

    if(options.names != null && options.names.length < OpenDAF.MAX_NAMES_IN_REQUEST)
      optNames = "names=" + options.names.join(",");

    if(options.fields != null)
      optFields = "fields=" + options.fields.join(",");

    final Iterable<String> opts = [optNames, optFields].where((_) => _ != null);
    final String opt = (opts.length > 0) ? ("?" + opts.join("&")) : "";

    return Future.wait([
      options.fetchConfiguration ? _http.get("${OpenDAF.dafmanPrefix}/alarms/$opt", headers: OpenDAF._headers) : new Future.value(null),
      options.fetchRuntime ? _http.get("${OpenDAF.prefix}/alarms/$opt", headers: OpenDAF._headers) : new Future.value(null)
    ]).then((List<http.Response> response) {
      Map<String, Alarm> alarms = new Map<String, Alarm>();
      Map<String, dynamic> configurations = OpenDAF._json(response[0]);
      Map<String, dynamic> runtimes = OpenDAF._json(response[1]);

      runtimes.keys.forEach((name) {
        alarms[name] = new Alarm.fromRuntimeJson(this._opendaf, runtimes[name]);
        if(options.fetchConfiguration){
          alarms[name].updateConfigurationJson(configurations[name]);
        }
      });

      configurations.keys.forEach((name) {
        if(alarms.containsKey(name)){
          if(options.fetchConfiguration){
            alarms[name].updateConfigurationJson(configurations[name]);
          }
        } else {
          alarms[name] = new Alarm.fromCfgJson(this._opendaf, configurations[name]);
        }
      });
      return alarms;
    });
  }

  Future create(Alarm alm) =>
    _http.put(
        new Uri(path: "${OpenDAF.dafmanPrefix}/alarms/${alm.name}"),
        body: JSON.encode(alm.toCfgJson()),
        headers: {'Content-Type': 'application/json'})
    .then((_) {
      return reload(options: _options);
    });

  Future update(Alarm alm) =>
      _http.put(
          new Uri(path: "${OpenDAF.dafmanPrefix}/alarms/${alm.name}"),
          body: JSON.encode(alm.toCfgJson()),
          headers: {'Content-Type': 'application/json'})
      .then((_) {
        return reload(options: _options);
      });
  
  Future delete(String name) =>
      _http.delete("${OpenDAF.dafmanPrefix}/alarms/$name")
      .then((_) {
        return reload(options: _options);
      });
  
  Future rename(Alarm alm, String newName) {
    Alarm duplicate = alm.dup();
    duplicate.name = newName;
    return create(duplicate)
        .then((_) => delete(alm.name));
  }

  Future _op(String name, String op, String authority) =>
    _http.post("${OpenDAF.prefix}/alarms/$name/$op?authority=$authority");

  Future acknowledge(String name, {String authority = "webdaf"}) => _op(name, "acknowledge", authority);
  Future activate(String name, {String authority = "webdaf"}) => _op(name, "activate", authority);
  Future deactivate(String name, {String authority = "webdaf"}) => _op(name, "deactivate", authority);

}
	
