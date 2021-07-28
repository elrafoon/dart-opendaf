part of opendaf;

class MeasurementController {
  static String _prefix = "measurements";
  final http.Client _http;
  final OpenDAF _opendaf;

  RequestOptions _options;

  MeasurementController(this._opendaf, this._http);

  Set<String> get properties {
    Set<String> res = new Set<String>();
    _opendaf.root.measurements.values.forEach((a) => res.addAll(a.properties.keys));
    return res;
  } 

  Future load({RequestOptions options}) => !_opendaf.root.measurementsLoaded ? reload(options: options) : new Future.value(null);

  Future reload({RequestOptions options}) async {
    this._options = options;
    Future future;

    List<String> _names = options.names != null && options.names.isNotEmpty ? options.names : await names();
    List<RequestOptions> _partialOptions = new List<RequestOptions>();
    for (int i = 0; i < _names.length; i += OpenDAF.MAX_NAMES_IN_REQUEST) {
      // Prepare sets
      RequestOptions _opt = options.dup();
      _opt.names = new List<String>.from(_names.skip(i).take(OpenDAF.MAX_NAMES_IN_REQUEST));
      _partialOptions.add(_opt);
    }

    // Clear root model
    _opendaf.root.measurements.clear();
    await _partialOptions.forEach((opt) async {
      Map<String, Measurement> _ = await list(options: opt);
      _opendaf.root.measurements.addAll(_);
      _opendaf.root.eventController.add(new MeasurementsSetChanged());
      });
    _opendaf.root.measurementsLoaded = true;

    return future;
  }

  Future<Measurement> item(String name, {RequestOptions options}) => _opendaf.item(_prefix, name, options: options)
    .then((List<http.Response> response) {
      Measurement item = new Measurement.fromRuntimeJson(this._opendaf, OpenDAF._json(response[1]));
      if(options.fetchConfiguration){
        item.updateConfigurationJson(OpenDAF._json(response[0]));
      }
      return item;
    });
  

  Future<List<String>> names() => _opendaf.names(_prefix);

  Future<Map<String, Measurement>> list({RequestOptions options}) => _opendaf.list(_prefix, options: options)
    .then((List<http.Response> response) {
      Map<String, dynamic> configurations = OpenDAF._json(response[0]);
      Map<String, dynamic> runtimes = OpenDAF._json(response[1]);
      Map<String, Measurement> items = new Map<String, Measurement>();

      runtimes.keys.forEach((name) {
        items[name] = new Measurement.fromRuntimeJson(this._opendaf, runtimes[name]);
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
          items[name] = new Measurement.fromCfgJson(this._opendaf, configurations[name]);
        }
      });
      return items;
    });
  

  Future create(Measurement item) => _opendaf.create(_prefix, item.name, item.toCfgJson()).then((_) => reload(options: _options));
  Future update(Measurement item) => _opendaf.update(_prefix, item.name, item.toCfgJson()).then((_) => reload(options: _options));
  Future delete(String name) => _opendaf.delete(_prefix, name).then((_) => reload(options: _options));
  
  Future rename(Measurement item, String newName) {
    Measurement duplicate = item.dup();
    duplicate.name = newName;
    return create(duplicate).then((_) => delete(item.name));
  }
}
	
