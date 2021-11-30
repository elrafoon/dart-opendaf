part of opendaf;

class ProviderController {
  static String _prefix = "providers";
  final http.Client _http;
  final OpenDAF _opendaf;

  RequestOptions _options;

  ProviderController(this._opendaf, this._http);

  Set<String> get properties {
    Set<String> res = new Set<String>();
    _opendaf.root.providers.values.forEach((a) => res.addAll(a.properties != null ? a.properties.keys : []));
    return res;
  } 

  Future load({RequestOptions options}) => !_opendaf.root.providersLoaded ? reload(options: options) : new Future.value(null);

  Future reload({RequestOptions options}) async {
    options = options == null ? new RequestOptions() : options;
    this._options = options;
    Future future;
    List<String> _names = _options.names != null && _options.names.isNotEmpty ? _options.names : await names();

        // Clear root model
    _opendaf.root.providers.clear();
    _names.forEach((name) {
      _opendaf.root.providers[name] = new Provider(this._opendaf, name: name);
    });
    _opendaf.root.eventController.add(new ProvidersSetChanged());

    if(_options.fetchConfiguration){
      future = await _opendaf.ctrl.providerStack.load(options: _options);
    }

    List<RequestOptions> _partialOptions = new List<RequestOptions>();
    for (int i = 0; i < _names.length; i += OpenDAF.MAX_NAMES_IN_REQUEST) {
      // Prepare sets
      RequestOptions _opt = _options.dup();
      _opt.names = new List<String>.from(_names.skip(i).take(OpenDAF.MAX_NAMES_IN_REQUEST));
      _partialOptions.add(_opt);
    }

    await _partialOptions.forEach((opt) async {
      // Return is ingored, list() function automatically updates root model
      Map<String, Provider> _ = await list(options: opt);
    });
    _opendaf.root.providersLoaded = true;

    return future;
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
	
