part of opendaf;

class MeasurementController {
  static String _prefix = "measurements";
  final http.Client _http;
  final OpenDAF _opendaf;

  RequestOptions _options;
LoadingStatus _ls;
  LoadingStatus get loadingStatus => _ls;

  int LIMIT = 500;

  MeasurementController(this._opendaf, this._http);

  Set<String> get properties {
    Set<String> res = new Set<String>();
    _opendaf.root.measurements.values.forEach((a) => res.addAll(a.properties != null ? a.properties.keys : []));
    return res;
  } 

  Future load({RequestOptions options}) => !_opendaf.root.measurementsLoaded ? reload(options: options) : new Future.value(null);

  Future reload({RequestOptions options}) async {
	_ls = new LoadingStatus();
	_ls.startMeasuring();

    options = options == null ? new RequestOptions() : options;
    this._options = options;
    List<String> _names = _options.names != null && _options.names.isNotEmpty ? _options.names : await names();

	_ls.logMilestone("Loaded Measurement names");
    // Clear root model
    _opendaf.root.measurements.clear();
    _names.take(LIMIT).forEach((name) {
      _opendaf.root.measurements[name] = new Measurement(this._opendaf, name: name);
    });
    _opendaf.root.eventController.add(new MeasurementsSetChanged());
	_ls.logMilestone("Create empty model");

	_ls.stepTarget = _names.length;
	_ls.stepCounter = 0;

    if(_options.fetchConfiguration){
      _ls.fut = await _opendaf.ctrl.connector.load(options: _options);
	  	  _ls.logMilestone("Fetched connectors");
      _ls.fut = await _opendaf.ctrl.provider.load(options: _options);
	    _ls.logMilestone("Fetched providers");
    }

    List<RequestOptions> _partialOptions = new List<RequestOptions>();
    for (int i = 0; i < _names.length; i += OpenDAF.MAX_NAMES_IN_REQUEST) {
      // Prepare sets
      RequestOptions _opt = _options.dup();
      _opt.names = new List<String>.from(_names.skip(i).take(OpenDAF.MAX_NAMES_IN_REQUEST));
      _partialOptions.add(_opt);
    }

	_ls.logMilestone("Start loading ${_partialOptions.length} parts");

	for(int j = 0; j < _partialOptions.length; j++){
      // Return is ingored, list() function automatically updates root model
      Map<String, Measurement> _ = await list(options: _partialOptions[j]);
	  _ls.logMilestone("Part ${j} loaded");

		if(j * OpenDAF.MAX_NAMES_IN_REQUEST + OpenDAF.MAX_NAMES_IN_REQUEST >= LIMIT) 
	  		break;
	}
    _opendaf.root.measurementsLoaded = true;

	_ls.endMeasuring();
    return _ls.fut;
  }

  Future<Measurement> item(String name, {RequestOptions options}) => _opendaf.item(_prefix, name, options: options)
    .then((List<http.Response> response) {
      options = options == null ? new RequestOptions() : options;
      Measurement item = new Measurement.fromRuntimeJson(this._opendaf, OpenDAF._json(response[1]));
      if(options.fetchConfiguration){
        item.updateConfigurationJson(OpenDAF._json(response[0]));
      }
      return item;
    });
  

  Future<List<String>> names() => _opendaf.names(_prefix);

  Future<Map<String, Measurement>> list({RequestOptions options}) => _opendaf.list(_prefix, options: options)
    .then((List<http.Response> response) {
      options = options == null ? new RequestOptions() : options;
      Map<String, dynamic> configurations = OpenDAF._json(response[0]);
      Map<String, dynamic> runtimes = OpenDAF._json(response[1]);
      Map<String, Measurement> items = new Map<String, Measurement>();

      runtimes.keys.forEach((name) {
        // Update item in root model
        if(_opendaf.root.measurements.containsKey(name)){
          _opendaf.root.measurements[name].updateRuntimeJson(runtimes[name]);
        } else {
          _opendaf.root.measurements[name] = new Measurement.fromRuntimeJson(this._opendaf, runtimes[name]);
        }

        items[name] = _opendaf.root.measurements[name];
      });

      configurations.keys.forEach((name) {
        // Update item in root model
        if(_opendaf.root.measurements.containsKey(name)){
          _opendaf.root.measurements[name].updateConfigurationJson(configurations[name]);
        } else {
          _opendaf.root.measurements[name] = new Measurement.fromCfgJson(this._opendaf, configurations[name]);
        }

        items[name] = _opendaf.root.measurements[name];
      });
      return items;
    });
  
  Future create(Measurement item) => _opendaf.create(_prefix, item.name, item.toCfgJson()).then((_) {
    item.cfg_stash();
    _opendaf.root.measurements[item.name] = item;
    _opendaf.root.eventController.add(new MeasurementsSetChanged());
  });
  Future update(Measurement item) => _opendaf.update(_prefix, item.name, item.toCfgJson()).then((_) {
    _opendaf.root.measurements[item.name] = item;
    _opendaf.root.eventController.add(new MeasurementsSetChanged());
  });
  Future delete(String name) => _opendaf.delete(_prefix, name).then((_) {
    _opendaf.root.measurements.remove(name);
    _opendaf.root.eventController.add(new MeasurementsSetChanged());
  });
  
  Future rename(Measurement item, String newName) {
    Measurement duplicate = item.dup();
    duplicate.name = newName;
    return create(duplicate).then((_) => delete(item.name));
  }
}
	
