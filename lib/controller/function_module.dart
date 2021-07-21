part of opendaf;

class FunctionModuleController {
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
    _opendaf.root.functionModules.clear();
    await _partialOptions.forEach((opt) async {
      Map<String, FunctionModule> _ = await list(options: opt);
      _opendaf.root.functionModules.addAll(_);
      _opendaf.root.eventController.add(new FunctionModulesSetChanged());
      });
    _opendaf.root.functionModulesLoaded= true;

    return future;
  }

  Future<Alarm> item(String name, {bool fetchRuntime = true, bool fetchConfiguration = false}) {
    return Future.wait([
      fetchConfiguration ? _http.get("${OpenDAF.dafmanPrefix}/function-modules/$name", headers: OpenDAF._headers) : new Future.value(null),
      fetchRuntime ? _http.get("${OpenDAF.prefix}/function-modules/$name", headers: OpenDAF._headers) : new Future.value(null)
    ]).then((List<http.Response> response) {
      FunctionModule fm = new FunctionModule.fromRuntimeJson(this._opendaf, OpenDAF._json(response[1]));
      if(fetchConfiguration){
        fm.updateConfigurationJson(OpenDAF._json(response[0]));
      }
      return fm;
    });
  }

  Future<List<String>> names() =>
    _http.get("${OpenDAF.dafmanPrefix}/function-modules/names", headers: OpenDAF._headers)
    .then((http.Response response) => OpenDAF._json(response));

  Future<Map<String, FunctionModule>> list({RequestOptions options}) {
    String optNames, optFields;

    if(options.names != null && options.names.length < OpenDAF.MAX_NAMES_IN_REQUEST)
      optNames = "names=" + options.names.join(",");

    if(options.fields != null)
      optFields = "fields=" + options.fields.join(",");

    final Iterable<String> opts = [optNames, optFields].where((_) => _ != null);
    final String opt = (opts.length > 0) ? ("?" + opts.join("&")) : "";

    return Future.wait([
      options.fetchConfiguration ? _http.get("${OpenDAF.dafmanPrefix}/function-modules/$opt", headers: OpenDAF._headers) : new Future.value(null),
      options.fetchRuntime ? _http.get("${OpenDAF.prefix}/function-modules/$opt", headers: OpenDAF._headers) : new Future.value(null)
    ]).then((List<http.Response> response) {
      Map<String, FunctionModule> fms = new Map<String, FunctionModule>();
      Map<String, dynamic> configurations = OpenDAF._json(response[0]);
      Map<String, dynamic> runtimes = OpenDAF._json(response[1]);

      runtimes.keys.forEach((name) {
        fms[name] = new FunctionModule.fromRuntimeJson(this._opendaf, runtimes[name]);
        if(options.fetchConfiguration){
          fms[name].updateConfigurationJson(configurations[name]);
        }
      });

      configurations.keys.forEach((name) {
        if(fms.containsKey(name)){
          if(options.fetchConfiguration){
            fms[name].updateConfigurationJson(configurations[name]);
          }
        } else {
          fms[name] = new FunctionModule.fromCfgJson(this._opendaf, configurations[name]);
        }
      });
      return fms;
    });
  }

  Future create(FunctionModule fm) =>
    _http.put(
        new Uri(path: "${OpenDAF.dafmanPrefix}/function-modules/${fm.name}/configuration"),
        body: JSON.encode(fm.toCfgJson()),
        headers: {'Content-Type': 'application/json'})
    .then((_) {
      return reload(options: _options);
    });

  Future update(FunctionModule fm) =>
      _http.put(
          new Uri(path: "${OpenDAF.dafmanPrefix}/function-modules/${fm.name}/configuration"),
          body: JSON.encode(fm.toCfgJson()),
          headers: {'Content-Type': 'application/json'})
      .then((_) {
        return reload(options: _options);
      });
  
  Future delete(String name) =>
      _http.delete("${OpenDAF.dafmanPrefix}/function-modules/$name")
      .then((_) {
        return reload(options: _options);
      });
  
  Future rename(FunctionModule fm, String newName) {
    FunctionModule duplicate = fm.dup();
    duplicate.name = newName;
    return create(duplicate)
        .then((_) => delete(fm.name));
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
	
