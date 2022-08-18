part of opendaf;

class AlarmGroupController extends GenericController {
	static String _prefix = "alarm-groups";

	AlarmGroupController(_opendaf, _http) : super(_opendaf, _http);


	Future load({RequestOptions options}) => !_opendaf.root.alarmGroupsLoaded ? reload(options: options) : new Future.value(null);

	Future reload({RequestOptions options}) async {
		_ls = new LoadingStatus();
		options = options == null ? new RequestOptions() : options;
		this._options = options;
		List<String> _names = _options.names != null && _options.names.isNotEmpty ? _options.names : await names();

		// Clear root model
		_opendaf.root.alarmGroups.clear();
		_names.forEach((name) {
			_opendaf.root.alarmGroups[name] = new AlarmGroup(this._opendaf, name: name);
		});
		_opendaf.root.eventController.add(new AlarmGroupsSetChanged());

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
			Map<String, AlarmGroup> _ = await list(options: _partialOptions[j]);
			updateProperties(_.values);
		}
		_opendaf.root.alarmGroupsLoaded = true;

		_ls.endMeasuring();
		return _ls.fut;
	}

	Future<AlarmGroup> item(String name, {RequestOptions options}) {
		options = options == null ? new RequestOptions() : options;
		options.fetchRuntime = false;
		return _opendaf.item(_prefix, name, options: options)
			.then((List<http.Response> response) {
				return new AlarmGroup.fromCfgJson(this._opendaf, OpenDAF._json(response[0]));
			});
	}


	Future<List<String>> names() => _opendaf.dafman.names(_prefix);

	Future<Map<String, AlarmGroup>> list({RequestOptions options}) {
		options = options == null ? new RequestOptions() : options;
		options.fetchRuntime = false;
		return _opendaf.list(_prefix, options: options)
			.then((List<http.Response> response) {
				Map<String, dynamic> configurations = OpenDAF._json(response[0]);
				Map<String, AlarmGroup> items = new Map<String, AlarmGroup>();

				configurations.keys.forEach((name) {
					// Update item in root model
					if(_opendaf.root.alarmGroups.containsKey(name)){
						_opendaf.root.alarmGroups[name].updateConfigurationJson(configurations[name]);
					} else {
						_opendaf.root.alarmGroups[name] = new AlarmGroup.fromCfgJson(this._opendaf, configurations[name]);
					}
					items[name] = _opendaf.root.alarmGroups[name];
				});
				return items;
			});
	}

	Future create(AlarmGroup item) => _opendaf.dafman.create(_prefix, item.name, item.toCfgJson()).then((_) {
		item.cfg_stash();
		_opendaf.root.alarmGroups[item.name] = item;
		_opendaf.root.eventController.add(new AlarmGroupsSetChanged());
	});
	Future update(AlarmGroup item) => _opendaf.dafman.update(_prefix, item.name, item.toCfgJson()).then((_) {
		_opendaf.root.alarmGroups[item.name] = item;
		_opendaf.root.eventController.add(new AlarmGroupsSetChanged());
	});
	Future delete(String name) => _opendaf.dafman.delete(_prefix, name).then((_) {
		_opendaf.root.alarmGroups.remove(name);
		_opendaf.root.eventController.add(new AlarmGroupsSetChanged());
	});
	
	Future rename(AlarmGroup item, String newName) {
		AlarmGroup duplicate = item.dup();
		duplicate.name = newName;
		return create(duplicate).then((_) => delete(item.name));
	}
}
	
