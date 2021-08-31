part of opendaf;

class FunctionModuleController {
  static String _prefix = "function-modules";
  final http.Client _http;
  final OpenDAF _opendaf;

  RequestOptions _options;

  FunctionModuleController(this._opendaf, this._http);

  Set<String> get properties {
    Set<String> res = new Set<String>();
    _opendaf.root.functionModules.values.forEach((fm) => res.addAll(fm.properties.keys));
    return res;
  } 

  Future load({RequestOptions options}) => !_opendaf.root.functionModulesLoaded ? reload(options: options) : new Future.value(null);

  Future reload({RequestOptions options}) async {
    options = options == null ? new RequestOptions() : options;
    this._options = options;
    Future future;
    List<String> _names = _options.names != null && _options.names.isNotEmpty ? _options.names : await names();

    // Clear root model
    _opendaf.root.functionModules.clear();
    _names.forEach((name) {
      _opendaf.root.functionModules[name] = new FunctionModule(this._opendaf, name: name);
    });
    _opendaf.root.eventController.add(new FunctionModulesSetChanged());

    List<RequestOptions> _partialOptions = new List<RequestOptions>();
    for (int i = 0; i < _names.length; i += OpenDAF.MAX_NAMES_IN_REQUEST) {
      // Prepare sets
      RequestOptions _opt = _options.dup();
      _opt.names = new List<String>.from(_names.skip(i).take(OpenDAF.MAX_NAMES_IN_REQUEST));
      _partialOptions.add(_opt);
    }

    await _partialOptions.forEach((opt) async {
      // Return is ingored, list() function automatically updates root model
      Map<String, FunctionModule> _ = await list(options: opt);
    });
    _opendaf.root.functionModulesLoaded= true;

    return future;
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

  Future<List<String>> names() => _opendaf.names(_prefix);

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


  Future create(FunctionModule item) => _opendaf.create(_prefix, item.name, item.toCfgJson()).then((_) {
    item.cfg_stash();
    _opendaf.root.functionModules[item.name] = item;
    _opendaf.root.eventController.add(new FunctionModulesSetChanged());
  });
  Future update(FunctionModule item) => _opendaf.update(_prefix, item.name, item.toCfgJson()).then((_) {
    _opendaf.root.functionModules[item.name] = item;
    _opendaf.root.eventController.add(new FunctionModulesSetChanged());
  });
  Future delete(String name) => _opendaf.delete(_prefix, name).then((_) {
    _opendaf.root.functionModules.remove(name);
    _opendaf.root.eventController.add(new FunctionModulesSetChanged());
  });
  
  Future rename(FunctionModule fm, String newName) {
    FunctionModule duplicate = fm.dup();
    duplicate.name = newName;
    return create(duplicate).then((_) => delete(fm.name));
  }

  Future uploadExecutable(String fmName, File executable) =>
    HttpRequest.request(
      new Uri(path: "${OpenDAF.dafmanPrefix}/function-modules/$fmName/executable").toString(), 
      method: 'PUT',
      mimeType: "application/octet-stream",
      sendData: executable, 
      requestHeaders: { 'Content-Type': 'application/octet-stream' }
  );

  Future<FileStat> statExecutable(String fmName) =>
    _http.get("${OpenDAF.dafmanPrefix}/function-modules/$fmName/executable-stat")
    .then((_) {
      if(_.statusCode != 404){
        FileStat _stat = new FileStat.fromJson(OpenDAF._json(_));
        if(_opendaf.root.functionModulesLoaded){
          _opendaf.root.functionModules[fmName].stat = _stat;
        }
        return _stat;
      } else {
        return null;
      }
    }) 
    .catchError((e) => null, test: (e) => e is http.ClientException);

}
	
