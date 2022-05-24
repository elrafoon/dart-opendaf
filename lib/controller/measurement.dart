part of opendaf;

class MeasurementController extends GenericController {
	static String _prefix = "measurements";
	MeasurementController(_opendaf, _http) : super(_opendaf, _http);

	Future load({RequestOptions options}) => !_opendaf.root.measurementsLoaded ? reload(options: options) : new Future.value(null);

	Future reload({RequestOptions options}) async {
		_ls = new LoadingStatus();
		options = options == null ? new RequestOptions() : options;
		this._options = options;

		List<String> _names = _options.names != null && _options.names.isNotEmpty ? _options.names : await names();

		// Clear root model
		_opendaf.root.measurements.clear();
		_names.forEach((name) {
			_opendaf.root.measurements[name] = new Measurement(this._opendaf, name: name);
		});
		_opendaf.root.eventController.add(new MeasurementsSetChanged());

		_ls.setTarget(_names.length);

		if(_options.fetchConfiguration){
			_ls.fut = await _opendaf.ctrl.connector.load(options: _options);
			_ls.fut = await _opendaf.ctrl.provider.load(options: _options);
		}

		List<RequestOptions> _partialOptions = new List<RequestOptions>();
		for (int i = 0; i < _names.length; i += OpenDAF.MAX_NAMES_IN_REQUEST) {
		// Prepare sets
		RequestOptions _opt = _options.dup();
			_opt.names = new List<String>.from(_names.skip(i).take(OpenDAF.MAX_NAMES_IN_REQUEST));
			_partialOptions.add(_opt);
		}

		for(int j = 0; j < _partialOptions.length; j++){
			// Return is ingored, list() function automatically updates root model
			Map<String, Measurement> _ = await list(options: _partialOptions[j]);
			updateProperties(_.values);
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


	Future<List<String>> names() => _opendaf.dafman.names(_prefix);

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

	Future create(Measurement item) => _opendaf.dafman.create(_prefix, item.name, item.toCfgJson()).then((_) {
		item.cfg_stash();
		_opendaf.root.measurements[item.name] = item;
		_opendaf.root.eventController.add(new MeasurementsSetChanged());
	});
	Future update(Measurement item) => _opendaf.dafman.update(_prefix, item.name, item.toCfgJson()).then((_) {
		_opendaf.root.measurements[item.name] = item;
		_opendaf.root.eventController.add(new MeasurementsSetChanged());
	});
	Future delete(String name) => _opendaf.dafman.delete(_prefix, name).then((_) {
		_opendaf.root.measurements.remove(name);
		_opendaf.root.eventController.add(new MeasurementsSetChanged());
	});
	
	Future rename(Measurement item, String newName) {
		Measurement duplicate = item.dup();
		duplicate.name = newName;
		return create(duplicate).then((_) => delete(item.name));
	}
}
