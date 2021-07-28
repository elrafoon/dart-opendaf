part of opendaf;

class ProviderController {
  static String _prefix = "providers";
  final http.Client _http;
  final OpenDAF _opendaf;

  RequestOptions _options;

  ProviderController(this._opendaf, this._http);

  Set<String> get properties {
    Set<String> res = new Set<String>();
    _opendaf.root.providers.values.forEach((a) => res.addAll(a.properties.keys));
    return res;
  } 

  Future load({RequestOptions options}) => !_opendaf.root.providersLoaded ? reload(options: options) : new Future.value(null);

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
    _opendaf.root.providers.clear();
    await _partialOptions.forEach((opt) async {
      Map<String, Provider> _ = await list(options: opt);
      _opendaf.root.providers.addAll(_);
      _opendaf.root.eventController.add(new ProvidersSetChanged());
      });
    _opendaf.root.providersLoaded = true;

    return future;
  }

  Future<Provider> item(String name, {RequestOptions options}) => _opendaf.item(_prefix, name, options: options)
    .then((List<http.Response> response) {
      Provider item = new Provider.fromRuntimeJson(this._opendaf, OpenDAF._json(response[1]));
      if(options.fetchConfiguration){
        item.updateConfigurationJson(OpenDAF._json(response[0]));
      }
      return item;
    });
  

  Future<List<String>> names() => _opendaf.names(_prefix);

  Future<Map<String, Provider>> list({RequestOptions options}) => _opendaf.list(_prefix, options: options)
    .then((List<http.Response> response) {
      Map<String, dynamic> configurations = OpenDAF._json(response[0]);
      Map<String, dynamic> runtimes = OpenDAF._json(response[1]);
      Map<String, Provider> items = new Map<String, Provider>();

      runtimes.keys.forEach((name) {
        items[name] = new Provider.fromRuntimeJson(this._opendaf, runtimes[name]);
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
          items[name] = new Provider.fromCfgJson(this._opendaf, configurations[name]);
        }
      });
      return items;
    });
  

  Future create(Provider item) => _opendaf.create(_prefix, item.name, item.toCfgJson()).then((_) => reload(options: _options));
  Future update(Provider item) => _opendaf.update(_prefix, item.name, item.toCfgJson()).then((_) => reload(options: _options));
  Future delete(String name) => _opendaf.delete(_prefix, name).then((_) => reload(options: _options));
  
  Future rename(Provider item, String newName) {
    Provider duplicate = item.dup();
    duplicate.name = newName;
    return create(duplicate).then((_) => delete(item.name));
  }
}
	
