part of opendaf;

class CommandController {
  static String _prefix = "commands";
  final http.Client _http;
  final OpenDAF _opendaf;

  RequestOptions _options;

  CommandController(this._opendaf, this._http);

  Set<String> get properties {
    Set<String> res = new Set<String>();
    _opendaf.root.commands.values.forEach((a) => res.addAll(a.properties.keys));
    return res;
  } 

  Future load({RequestOptions options}) => !_opendaf.root.commandsLoaded ? reload(options: options) : new Future.value(null);

  Future reload({RequestOptions options}) async {
    options = options == null ? new RequestOptions() : options;
    this._options = options;
    Future future;

    if(_options.fetchConfiguration){
      future = await _opendaf.ctrl.connector.load(options: _options);
      future = await _opendaf.ctrl.provider.load(options: _options);
    }

    List<String> _names = _options.names != null && _options.names.isNotEmpty ? _options.names : await names();
    List<RequestOptions> _partialOptions = new List<RequestOptions>();
    for (int i = 0; i < _names.length; i += OpenDAF.MAX_NAMES_IN_REQUEST) {
      // Prepare sets
      RequestOptions _opt = _options.dup();
      _opt.names = new List<String>.from(_names.skip(i).take(OpenDAF.MAX_NAMES_IN_REQUEST));
      _partialOptions.add(_opt);
    }

    // Clear root model
    _opendaf.root.commands.clear();
    await _partialOptions.forEach((opt) async {
      Map<String, Command> _ = await list(options: opt);
      _opendaf.root.commands.addAll(_);
      _opendaf.root.eventController.add(new CommandsSetChanged());
      });
    _opendaf.root.commandsLoaded = true;

    return future;
  }

  Future<Command> item(String name, {RequestOptions options}) => _opendaf.item(_prefix, name, options: options)
    .then((List<http.Response> response) {
      options = options == null ? new RequestOptions() : options;
      Command item = new Command.fromRuntimeJson(this._opendaf, OpenDAF._json(response[1]));
      if(options.fetchConfiguration){
        item.updateConfigurationJson(OpenDAF._json(response[0]));
      }
      return item;
    });
  

  Future<List<String>> names() => _opendaf.names(_prefix);

  Future<Map<String, Command>> list({RequestOptions options}) => _opendaf.list(_prefix, options: options)
    .then((List<http.Response> response) {
      options = options == null ? new RequestOptions() : options;
      Map<String, dynamic> configurations = OpenDAF._json(response[0]);
      Map<String, dynamic> runtimes = OpenDAF._json(response[1]);
      Map<String, Command> items = new Map<String, Command>();

      runtimes.keys.forEach((name) {
        items[name] = new Command.fromRuntimeJson(this._opendaf, runtimes[name]);
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
          items[name] = new Command.fromCfgJson(this._opendaf, configurations[name]);
        }
      });
      return items;
    });
  

  Future create(Command item) => _opendaf.create(_prefix, item.name, item.toCfgJson()).then((_) {
    item.cfg_stash();
    _opendaf.root.commands[item.name] = item;
    _opendaf.root.eventController.add(new CommandsSetChanged());
  });
  Future update(Command item) => _opendaf.update(_prefix, item.name, item.toCfgJson()).then((_) {
    _opendaf.root.commands[item.name] = item;
    _opendaf.root.eventController.add(new CommandsSetChanged());
  });
  Future delete(String name) => _opendaf.delete(_prefix, name).then((_) {
    _opendaf.root.commands.remove(name);
    _opendaf.root.eventController.add(new CommandsSetChanged());
  });
  
  Future rename(Command item, String newName) {
    Command duplicate = item.dup();
    duplicate.name = newName;
    return create(duplicate).then((_) => delete(item.name));
  }
}
	
