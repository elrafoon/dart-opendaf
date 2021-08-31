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
    options = options == null ? new RequestOptions() : options;
     this._options = options;
    List<String> _names = _options.names != null && _options.names.isNotEmpty ? _options.names : await names();

    // Clear root model
    _opendaf.root.connectors.clear();
    _names.forEach((name) {
      _opendaf.root.connectors[name] = new Connector(this._opendaf, name: name);
    });
    _opendaf.root.eventController.add(new ConnectorsSetChanged());

    // Wait for stacks
    await _opendaf.ctrl.connectorStack.load(options: options);

    Future future;

    List<RequestOptions> _partialOptions = new List<RequestOptions>();
    for (int i = 0; i < _names.length; i += OpenDAF.MAX_NAMES_IN_REQUEST) {
      // Prepare sets
      RequestOptions _opt = _options.dup();
      _opt.names = new List<String>.from(_names.skip(i).take(OpenDAF.MAX_NAMES_IN_REQUEST));
      _partialOptions.add(_opt);
    }

    // Clear root model
    await _partialOptions.forEach((opt) async {
      // Return is ingored, list() function automatically updates root model
      Map<String, Connector> _ = await list(options: opt);
    });
    _opendaf.root.connectorsLoaded = true;

    return future;
  }

  Future<Connector> item(String name, {RequestOptions options}) {
    options = options == null ? new RequestOptions() : options;
    options.fetchRuntime = false;
    return _opendaf.item(_prefix, name, options: options)
      .then((List<http.Response> response) {
        return new Connector.fromCfgJson(this._opendaf, OpenDAF._json(response[0]));
      });
  } 
  

  Future<List<String>> names() => _opendaf.names(_prefix);

  Future<Map<String, Connector>> list({RequestOptions options}) {
    options = options == null ? new RequestOptions() : options;
    options.fetchRuntime = false;
    return _opendaf.list(_prefix, options: options)
      .then((List<http.Response> response) {
        Map<String, dynamic> configurations = OpenDAF._json(response[0]);
        Map<String, Connector> items = new Map<String, Connector>();

        configurations.keys.forEach((name) {
                  // Update item in root model
          if(_opendaf.root.connectors.containsKey(name)){
            _opendaf.root.connectors[name].updateConfigurationJson(configurations[name]);
          } else {
            _opendaf.root.connectors[name] = new Connector.fromCfgJson(this._opendaf, configurations[name]);
          }
          items[name] = _opendaf.root.connectors[name];
        });
        return items;
      });
  }

  Future create(Connector item) => _opendaf.create(_prefix, item.name, item.toCfgJson()).then((_) {
    item.cfg_stash();
    _opendaf.root.connectors[item.name] = item;
    _opendaf.root.eventController.add(new ConnectorsSetChanged());
  });
  Future update(Connector item) => _opendaf.update(_prefix, item.name, item.toCfgJson()).then((_) {
    _opendaf.root.connectors[item.name] = item;
    _opendaf.root.eventController.add(new ConnectorsSetChanged());
  });
  Future delete(String name) => _opendaf.delete(_prefix, name).then((_) {
    _opendaf.root.connectors.remove(name);
    _opendaf.root.eventController.add(new ConnectorsSetChanged());
  });
  
  Future rename(Connector item, String newName) {
    Connector duplicate = item.dup();
    duplicate.name = newName;
    return create(duplicate).then((_) => delete(item.name));
  }
}
	
