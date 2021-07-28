part of opendaf;

class ConnectorController {
  static String _prefix = "connectors";
  final http.Client _http;
  final OpenDAF _opendaf;

  RequestOptions _options;

  ConnectorController(this._opendaf, this._http);

  Set<String> get properties {
    Set<String> res = new Set<String>();
    _opendaf.root.connectors.values.forEach((a) => res.addAll(a.properties.keys));
    return res;
  } 

  Future load({RequestOptions options}) => !_opendaf.root.connectorsLoaded ? reload(options: options) : new Future.value(null);

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
    _opendaf.root.connectors.clear();
    await _partialOptions.forEach((opt) async {
      Map<String, Connector> _ = await list(options: opt);
      _opendaf.root.connectors.addAll(_);
      _opendaf.root.eventController.add(new ConnectorsSetChanged());
      });
    _opendaf.root.connectorsLoaded = true;

    return future;
  }

  Future<Connector> item(String name, {RequestOptions options}) {
    options.fetchRuntime = false;
    return _opendaf.item(_prefix, name, options: options)
      .then((List<http.Response> response) {
        return new Connector.fromCfgJson(this._opendaf, OpenDAF._json(response[0]));
      });
  } 
  

  Future<List<String>> names() => _opendaf.names(_prefix);

  Future<Map<String, Connector>> list({RequestOptions options}) {
    options.fetchRuntime = false;
    return _opendaf.list(_prefix, options: options)
      .then((List<http.Response> response) {
        Map<String, dynamic> configurations = OpenDAF._json(response[0]);
        Map<String, Connector> items = new Map<String, Connector>();

        configurations.keys.forEach((name) {
          items[name] = new Connector.fromCfgJson(this._opendaf, configurations[name]);
        });
        return items;
      });
  }

  Future create(Connector item) => _opendaf.create(_prefix, item.name, item.toCfgJson()).then((_) => reload(options: _options));
  Future update(Connector item) => _opendaf.update(_prefix, item.name, item.toCfgJson()).then((_) => reload(options: _options));
  Future delete(String name) => _opendaf.delete(_prefix, name).then((_) => reload(options: _options));
  
  Future rename(Connector item, String newName) {
    Connector duplicate = item.dup();
    duplicate.name = newName;
    return create(duplicate).then((_) => delete(item.name));
  }
}
	
