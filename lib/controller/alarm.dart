part of opendaf;

class AlarmController extends GenericController {
	static String _prefix = "alarms";

	AlarmController(_opendaf, _http) : super(_opendaf, _http);

	Future load({RequestOptions options}) => !_opendaf.root.alarmsLoaded ? reload(options: options) : new Future.value(null);

	Future reload({RequestOptions options}) async {
		_ls = new LoadingStatus();
		options = options == null ? new RequestOptions() : options;
		this._options = options;

		List<String> _names = _options.names != null && _options.names.isNotEmpty ? _options.names : await names();

			// Clear root model
		_opendaf.root.alarms.clear();
		_names.forEach((name) {
			_opendaf.root.alarms[name] = new Alarm(this._opendaf, name: name);
		});
		_opendaf.root.eventController.add(new AlarmsSetChanged());

		_ls.setTarget(_names.length);

		List<RequestOptions> _partialOptions = new List<RequestOptions>();
		for (int i = 0; i < _names.length; i += OpenDAF.MAX_NAMES_IN_REQUEST) {
			// Prepare sets
			RequestOptions _opt = _options.dup();
			_opt.names = new List<String>.from(_names.skip(i).take(OpenDAF.MAX_NAMES_IN_REQUEST));
			_partialOptions.add(_opt);
		}

		for(int j = 0; j < _partialOptions.length; j++){
			// Return is ingored, list() function automatically updates root model
			Map<String, Alarm> _ = await list(options: _partialOptions[j]);
			updateProperties(_.values);
		}
		_opendaf.root.alarmsLoaded = true;

		_ls.endMeasuring();
		return _ls.fut;
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

	Future<List<String>> names() => _opendaf.dafman.names(_prefix);

	Future<Map<String, Alarm>> list({RequestOptions options}) => _opendaf.list(_prefix, options: options)
		.then((List<http.Response> response) {
			options = options == null ? new RequestOptions() : options;

			Map<String, dynamic> configurations = OpenDAF._json(response[0]);
			Map<String, dynamic> runtimes = OpenDAF._json(response[1]);
			Map<String, Alarm> items = new Map<String, Alarm>();

			runtimes.keys.forEach((name) {
				// Update item in root model
				if(_opendaf.root.alarms.containsKey(name)){
					_opendaf.root.alarms[name].updateRuntimeJson(runtimes[name]);
				} else {
					_opendaf.root.alarms[name] = new Alarm.fromRuntimeJson(this._opendaf, runtimes[name]);
				}

				items[name] = _opendaf.root.alarms[name];
			});

			configurations.keys.forEach((name) {
				// Update item in root model
				if(_opendaf.root.alarms.containsKey(name)){
					_opendaf.root.alarms[name].updateConfigurationJson(configurations[name]);
				} else {
					_opendaf.root.alarms[name] = new Alarm.fromCfgJson(this._opendaf, configurations[name]);
				}

				items[name] = _opendaf.root.alarms[name];
			});

			return items;
		});

	Future create(Alarm item) => _opendaf.dafman.create(_prefix, item.name, item.toCfgJson()).then((_) {
		item.cfg_stash();
		_opendaf.root.alarms[item.name] = item;
		_opendaf.root.eventController.add(new AlarmsSetChanged());
	});
	Future update(Alarm item) => _opendaf.dafman.update(_prefix, item.name, item.toCfgJson()).then((_) {
		_opendaf.root.alarms[item.name] = item;
		_opendaf.root.eventController.add(new AlarmsSetChanged());
	});
	Future delete(String name) => _opendaf.dafman.delete(_prefix, name).then((_) {
		_opendaf.root.alarms.remove(name);
		_opendaf.root.eventController.add(new AlarmsSetChanged());
	});
	
	Future rename(Alarm alm, String newName) {
		Alarm duplicate = alm.dup();
		duplicate.name = newName;
		return create(duplicate).then((_) => delete(alm.name));
	}
}
	
