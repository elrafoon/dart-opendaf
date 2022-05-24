part of opendaf;

class FunctionModuleController extends GenericController {
	static String _prefix = "function-modules";

	FunctionModuleController(_opendaf, _http) : super(_opendaf, _http);

	Future load({RequestOptions options}) => !_opendaf.root.functionModulesLoaded ? reload(options: options) : new Future.value(null);

	Future reload({RequestOptions options}) async {
		_ls = new LoadingStatus();
		options = options == null ? new RequestOptions() : options;
		this._options = options;

		List<String> _names = _options.names != null && _options.names.isNotEmpty ? _options.names : await names();

		// Clear root model
		_opendaf.root.functionModules.clear();
		_names.forEach((name) {
			_opendaf.root.functionModules[name] = new FunctionModule(this._opendaf, name: name);
		});
		_opendaf.root.eventController.add(new FunctionModulesSetChanged());

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
			Map<String, FunctionModule> _ = await list(options: _partialOptions[j]);
			updateProperties(_.values);
		}
		_opendaf.root.functionModulesLoaded = true;

		_ls.endMeasuring();
		return _ls.fut;
	}

	Future<Alarm> item(String name, {RequestOptions options}) => _opendaf.item(_prefix, name, options: options)
		.then((List<http.Response> response) {
			options = options == null ? new RequestOptions() : options;
			FunctionModule item = new FunctionModule.fromRuntimeJson(this._opendaf, OpenDAF._json(response[1]));
			if(options.fetchConfiguration){
				item.updateConfigurationJson(OpenDAF._json(response[0]));
			}
			return item;
		});

	Future<List<String>> names() => _opendaf.dafman.names(_prefix);

	Future<Map<String, FunctionModule>> list({RequestOptions options}) => _opendaf.list(_prefix, options: options)
		.then((List<http.Response> response) {
			options = options == null ? new RequestOptions() : options;
			Map<String, FunctionModule> items = new Map<String, FunctionModule>();
			Map<String, dynamic> configurations = OpenDAF._json(response[0]);
			Map<String, dynamic> runtimes = OpenDAF._json(response[1]);

			runtimes.keys.forEach((name) {
				// Update item in root model
				if(_opendaf.root.functionModules.containsKey(name)){
					_opendaf.root.functionModules[name].updateRuntimeJson(runtimes[name]);
				} else {
					_opendaf.root.functionModules[name] = new FunctionModule.fromRuntimeJson(this._opendaf, runtimes[name]);
				}

				items[name] = _opendaf.root.functionModules[name];
			});

			configurations.keys.forEach((name) {
				// Update item in root model
				if(_opendaf.root.functionModules.containsKey(name)){
					_opendaf.root.functionModules[name].updateConfigurationJson(configurations[name]);
				} else {
					_opendaf.root.functionModules[name] = new FunctionModule.fromCfgJson(this._opendaf, configurations[name]);
				}

				items[name] = _opendaf.root.functionModules[name];
			});
			return items;
		});


	Future create(FunctionModule item) => _opendaf.dafman.create(_prefix, item.name, item.toCfgJson()).then((_) {
		item.cfg_stash();
		_opendaf.root.functionModules[item.name] = item;
		_opendaf.root.eventController.add(new FunctionModulesSetChanged());
	});
	Future update(FunctionModule item) => _opendaf.dafman.update(_prefix, item.name, item.toCfgJson()).then((_) {
		_opendaf.root.functionModules[item.name] = item;
		_opendaf.root.eventController.add(new FunctionModulesSetChanged());
	});
	Future delete(String name) => _opendaf.dafman.delete(_prefix, name).then((_) {
		_opendaf.root.functionModules.remove(name);
		_opendaf.root.eventController.add(new FunctionModulesSetChanged());
	});
	
	Future rename(FunctionModule fm, String newName) {
		FunctionModule duplicate = fm.dup();
		duplicate.name = newName;
		return create(duplicate).then((_) => delete(fm.name));
	}

	Future uploadExecutable(String fmName, File executable) => _opendaf.dafman.uploadExecutable(fmName, executable);
	Future<FileStat> statExecutable(String fmName) => _opendaf.dafman.statExecutable(fmName);
}
