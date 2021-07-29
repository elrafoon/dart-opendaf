part of opendaf;

class ProviderStackController {
  static String _prefix = "stacks/provider";
  final http.Client _http;
  final OpenDAF _opendaf;

  RequestOptions _options;

  ProviderStackController(this._opendaf, this._http);

  Future load({RequestOptions options}) => !_opendaf.root.providerStacksLoaded ? reload(options: options) : new Future.value(null);

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
    _opendaf.root.providerStacks.clear();
    await _partialOptions.forEach((opt) async {
      Map<String, Stack> _ = await list(options: opt);
      _opendaf.root.providerStacks.addAll(_);
      _opendaf.root.eventController.add(new ProviderStacksSetChanged());
      });
    _opendaf.root.providerStacksLoaded = true;

    return future;
  }

  Future<Stack> item(String name, {RequestOptions options}) {
    options.fetchRuntime = false;
    return _opendaf.item(_prefix, name, options: options)
      .then((List<http.Response> response) {
        return new Stack.fromCfgJson(this._opendaf, OpenDAF._json(response[0]));
      });
  } 
  

  Future<List<String>> names() => _opendaf.names(_prefix);

  Future<Map<String, Stack>> list({RequestOptions options}) {
    options.fetchRuntime = false;
    return _opendaf.list(_prefix, options: options)
      .then((List<http.Response> response) {
        Map<String, dynamic> configurations = OpenDAF._json(response[0]);
        Map<String, Stack> items = new Map<String, Stack>();

        configurations.keys.forEach((name) {
          items[name] = new Stack.fromCfgJson(this._opendaf, configurations[name]);
        });
        return items;
      });
  }
}
	
