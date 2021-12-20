part of opendaf;

class ProviderController extends GenericController {
	static String _prefix = "providers";
	
	ProviderController(_opendaf, _http) : super(_opendaf, _http);

  Future load({RequestOptions options}) => !_opendaf.root.providersLoaded ? reload(options: options) : new Future.value(null);

  Future reload({RequestOptions options}) async {
	_ls = new LoadingStatus();
    options = options == null ? new RequestOptions() : options;
    this._options = options;

    List<String> _names = _options.names != null && _options.names.isNotEmpty ? _options.names : await names();

        // Clear root model
    _opendaf.root.providers.clear();
    _names.forEach((name) {
      _opendaf.root.providers[name] = new Provider(this._opendaf, name: name);
    });
    _opendaf.root.eventController.add(new ProvidersSetChanged());

	_ls.setTarget(_names.length);

    if(_options.fetchConfiguration){
      _ls.fut = await _opendaf.ctrl.providerStack.load(options: _options);
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
		Map<String, Provider> _ = await list(options: _partialOptions[j]);
		updateProperties(_.values);
	}
	_opendaf.root.providersLoaded = true;

	_ls.endMeasuring();
	return _ls.fut;
  }

  Future<Provider> item(String name, {RequestOptions options}) {
    options = options == null ? new RequestOptions() : options;
    options.fetchRuntime = false;
    return _opendaf.item(_prefix, name, options: options)
      .then((List<http.Response> response) {
        return new Provider.fromCfgJson(this._opendaf, OpenDAF._json(response[0]));
      });
  } 
  

  Future<List<String>> names() => _opendaf.names(_prefix);

  Future<Map<String, Provider>> list({RequestOptions options}) {
    options = options == null ? new RequestOptions() : options;
    options.fetchRuntime = false;
    return _opendaf.list(_prefix, options: options)
      .then((List<http.Response> response) {
        Map<String, dynamic> configurations = OpenDAF._json(response[0]);
        Map<String, Provider> items = new Map<String, Provider>();

        configurations.keys.forEach((name) {
          // Update item in root model
          if(_opendaf.root.providers.containsKey(name)){
            _opendaf.root.providers[name].updateConfigurationJson(configurations[name]);
          } else {
            _opendaf.root.providers[name] = new Provider.fromCfgJson(this._opendaf, configurations[name]);
          }

          items[name] = _opendaf.root.providers[name];
        });
        return items;
      });
  }

  Future create(Provider item) => _opendaf.create(_prefix, item.name, item.toCfgJson()).then((_) {
    item.cfg_stash();
    _opendaf.root.providers[item.name] = item;
    _opendaf.root.eventController.add(new ProvidersSetChanged());
  });
  Future update(Provider item) => _opendaf.update(_prefix, item.name, item.toCfgJson()).then((_) {
    _opendaf.root.providers[item.name] = item;
    _opendaf.root.eventController.add(new ProvidersSetChanged());
  });
  Future delete(String name) => _opendaf.delete(_prefix, name).then((_) {
    _opendaf.root.providers.remove(name);
    _opendaf.root.eventController.add(new ProvidersSetChanged());
  });
  
  Future rename(Provider item, String newName) {
    Provider duplicate = item.dup();
    duplicate.name = newName;
    return create(duplicate).then((_) => delete(item.name));
  }
}
	
