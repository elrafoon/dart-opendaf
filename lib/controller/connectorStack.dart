part of opendaf;

class ConnectorStackController extends GenericController {
	static String _prefix = "stacks/connector";
	
	ConnectorStackController(_opendaf, _http) : super(_opendaf, _http);

  Future load({RequestOptions options}) => !_opendaf.root.connectorStacksLoaded ? reload(options: options) : new Future.value(null);

  Future reload({RequestOptions options}) async {
	_ls = new LoadingStatus();
    options = options == null ? new RequestOptions() : options;
    this._options = options;

    List<String> _names = _options.names != null && _options.names.isNotEmpty ? _options.names : await names();

    // Clear root model
    _opendaf.root.connectorStacks.clear();
    _names.forEach((name) {
      _opendaf.root.connectorStacks[name] = new Stack(this._opendaf, name: name);
    });
    _opendaf.root.eventController.add(new ConnectorStacksSetChanged());

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
		Map<String, Stack> _ = await list(options: _partialOptions[j]);
	}
	_opendaf.root.connectorStacksLoaded = true;

	_ls.endMeasuring();
	return _ls.fut;
  }

  Future<Stack> item(String name, {RequestOptions options}) {
    options = options == null ? new RequestOptions() : options;
    options.fetchRuntime = false;
    return _opendaf.item(_prefix, name, options: options)
      .then((List<http.Response> response) {
        return new Stack.fromCfgJson(this._opendaf, OpenDAF._json(response[0]));
      });
  } 
  

  Future<List<String>> names() => _opendaf.names(_prefix);

  Future<Map<String, Stack>> list({RequestOptions options}) {
    options = options == null ? new RequestOptions() : options;
    options.fetchRuntime = false;
    return _opendaf.list(_prefix, options: options)
      .then((List<http.Response> response) {
        Map<String, dynamic> configurations = OpenDAF._json(response[0]);
        Map<String, Stack> items = new Map<String, Stack>();

        configurations.keys.forEach((name) {
          // Update item in root model
          if(_opendaf.root.connectorStacks.containsKey(name)){
            _opendaf.root.connectorStacks[name].updateConfigurationJson(configurations[name]);
          } else {
            _opendaf.root.connectorStacks[name] = new Stack.fromCfgJson(this._opendaf, configurations[name]);
          }

          items[name] = _opendaf.root.connectorStacks[name];
        });

        return items;
      });
  }
}
	
