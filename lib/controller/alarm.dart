part of opendaf;

class AlarmController {
  static String _prefix = "alarms";
  final http.Client _http;
  final OpenDAF _opendaf;

  RequestOptions _options;

  AlarmController(this._opendaf, this._http);

  Set<String> get properties {
    Set<String> res = new Set<String>();
    _opendaf.root.alarms.values.forEach((a) => res.addAll(a.properties.keys));
    return res;
  } 

  Future load({RequestOptions options}) => !_opendaf.root.alarmsLoaded ? reload(options: options) : new Future.value(null);

  Future reload({RequestOptions options}) async {
    options = options == null ? new RequestOptions() : options;
    this._options = options;
    Future future;

    List<String> _names = _options.names != null && _options.names.isNotEmpty ? _options.names : await names();
    List<RequestOptions> _partialOptions = new List<RequestOptions>();
    for (int i = 0; i < _names.length; i += OpenDAF.MAX_NAMES_IN_REQUEST) {
      // Prepare sets
      RequestOptions _opt = _options.dup();
      _opt.names = new List<String>.from(_names.skip(i).take(OpenDAF.MAX_NAMES_IN_REQUEST));
      _partialOptions.add(_opt);
    }

    // Clear root model
    _opendaf.root.alarms.clear();
    await _partialOptions.forEach((opt) async {
      Map<String, Alarm> _ = await list(options: opt);
      _opendaf.root.alarms.addAll(_);
      _opendaf.root.eventController.add(new AlarmsSetChanged());
      });
    _opendaf.root.alarmsLoaded = true;

    return future;
  }

  Future<Alarm> item(String name, {RequestOptions options}) => _opendaf.item(_prefix, name, options: options)
    .then((List<http.Response> response) {
      options = options == null ? new RequestOptions() : options;
      Alarm item = new Alarm.fromRuntimeJson(this._opendaf, OpenDAF._json(response[1]));
      if(options.fetchConfiguration){
        item.updateConfigurationJson(OpenDAF._json(response[0]));
      }
      return item;
    });
  

  Future<List<String>> names() => _opendaf.names(_prefix);

  Future<Map<String, Alarm>> list({RequestOptions options}) => _opendaf.list(_prefix, options: options)
    .then((List<http.Response> response) {
      options = options == null ? new RequestOptions() : options;

      Map<String, dynamic> configurations = OpenDAF._json(response[0]);
      Map<String, dynamic> runtimes = OpenDAF._json(response[1]);
      Map<String, Alarm> items = new Map<String, Alarm>();

      runtimes.keys.forEach((name) {
        items[name] = new Alarm.fromRuntimeJson(this._opendaf, runtimes[name]);
        if(options.fetchConfiguration){
          items[name].updateConfigurationJson(configurations[name]);
        }
      });

      configurations.keys.forEach((name) {
        if(items.containsKey(name)){
          if(options.fetchConfiguration){
            items[name].updateConfigurationJson(configurations[name]);
          }
        } else {
          items[name] = new Alarm.fromCfgJson(this._opendaf, configurations[name]);
        }
      });
      return items;
    });
  

  Future create(Alarm item) => _opendaf.create(_prefix, item.name, item.toCfgJson()).then((_) {
    item.cfg_stash();
    _opendaf.root.alarms[item.name] = item;
    _opendaf.root.eventController.add(new AlarmsSetChanged());
  });
  Future update(Alarm item) => _opendaf.update(_prefix, item.name, item.toCfgJson()).then((_) {
    _opendaf.root.alarms[item.name] = item;
    _opendaf.root.eventController.add(new AlarmsSetChanged());
  });
  Future delete(String name) => _opendaf.delete(_prefix, name).then((_) {
    _opendaf.root.alarms.remove(name);
    _opendaf.root.eventController.add(new AlarmsSetChanged());
  });
  
  Future rename(Alarm alm, String newName) {
    Alarm duplicate = alm.dup();
    duplicate.name = newName;
    return create(duplicate).then((_) => delete(alm.name));
  }

  Future _op(String name, String op, String authority) =>
    _http.post("${OpenDAF.opendafPrefix}/alarms/$name/$op?authority=$authority");

  Future acknowledge(String name, {String authority = "webdaf"}) => _op(name, "acknowledge", authority);
  Future activate(String name, {String authority = "webdaf"}) => _op(name, "activate", authority);
  Future deactivate(String name, {String authority = "webdaf"}) => _op(name, "deactivate", authority);

}
	
