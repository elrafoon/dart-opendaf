part of opendaf;

class Response extends StreamEvent{}
class AlarmStateChangeNotification extends StreamEvent{ Set<Alarm> alarms; }
class MeasurementUpdateNotification extends StreamEvent{ Set<Measurement> measurements; }
class CommandUpdateNotification extends StreamEvent{ Set<Command> commands; }
class FunctionModuleUpdateNotification extends StreamEvent{ Set<FunctionModule> functionModules; }


@Injectable()
class OpenDAFWS {
  /// Constants
  static const String WS_RESPONSE                                     = "Response";
  static const String WS_RESPONSE_MEASUREMENT_UPDATE_NOTIFICATION     = "MeasurementUpdateNotification";
  static const String WS_RESPONSE_ALARMS_STATE_CHANGE_NOTIFICATION    = "AlarmStateChangeNotification";
  static const String WS_RESPONSE_FUNCTION_MODULE_UPDATE_NOTIFICATION = "FunctionModuleUpdateNotification";
  static const String WS_RESPONSE_COMMAND_UPDATE_NOTIFICATION         = "CommandUpdateNotification";

  static const String WS_REQUEST                          = "Request";
  static const String WS_HEARTBEAT                        = "Heartbeat";
  static const String WS_REQUEST_WATCH_MEASUREMENTS       = "WatchMeasurements";
  static const String WS_REQUEST_UNWATCH_MEASUREMENTS     = "UnwatchMeasurements";  
  static const String WS_REQUEST_WATCH_COMMANDS           = "WatchCommands";
  static const String WS_REQUEST_UNWATCH_COMMANDS         = "UnwatchCommands";  
  static const String WS_REQUEST_WATCH_FUNCTION_MODULES   = "WatchFunctionModules";
  static const String WS_REQUEST_UNWATCH_FUNCTION_MODULES = "UnwatchFunctionModules";
  static const String WS_REQUEST_WATCH_ALARMS             = "WatchAlarms";
  static const String WS_REQUEST_UNWATCH_ALARMS           = "UnwatchAlarms";
  static const String WS_REQUEST_ACK_ALARMS               = "AckAlarms";
  static const String WS_REQUEST_WRITE_COMMANDS           = "WriteCommands";

  static const String CS_CONNECTED = "connected", CS_DISCONNECTED = "disconnected", CS_CONNECTING = "connecting";

  static const String prefix = "/opendaf/ws/opendaf/";
  static const int WS_TIMEOUT = 10;
  static int RECONNECT_TIMEOUT = 0;

  /// Variables
  final http.Client _http;
  final OpenDAF _opendaf;
  static int id_counter = 0;
  static const int MAX_NAMES_IN_REQUEST = 2000;
  final StreamController<StreamEvent> eventController = new StreamController<StreamEvent>.broadcast();
  Stream<StreamEvent> eventStream;
  Future futConnection;
  bool connected = false;
  html.WebSocket _ws;
  String _url;
  Timer _keepAliveTimer;

  String connectionStatus = CS_CONNECTING;
  bool connectionFailed = false;
  String get url => _url;
  DateTime scheduledReconnect = new DateTime.now();



  Map<int, Completer> _completers = new Map<int, Completer>();

  final Map<dynamic, Set<String>> _alarmsByObject           = new Map<dynamic, Set<String>>();
  final Map<dynamic, Set<String>> _commandsByObject         = new Map<dynamic, Set<String>>();
  final Map<dynamic, Set<String>> _functionModulesByObject  = new Map<dynamic, Set<String>>();
  final Map<dynamic, Set<String>> _measurementsByObject     = new Map<dynamic, Set<String>>();


  Set<String> _watchedAlarms          = new Set<String>();
  Set<String> _watchedCommands        = new Set<String>();
  Set<String> _watchedFunctionModules = new Set<String>();
  Set<String> _watchedMeasurements    = new Set<String>();


  OpenDAFWS(this._http, this._opendaf) {
    eventStream = eventController.stream;
    reconnect();
  }

  void log(String message){
    print("[OpenDAF-WS]: $message");
  }

  void heartbeat() {
    Map<String, dynamic> heartbeat = new Map<String, dynamic>();
    heartbeat["request"] = WS_HEARTBEAT;
    _ws_request(heartbeat);
  }

  void reconnect() {
    connectionStatus = CS_CONNECTING;
    _url = ((html.window.location.protocol == "https:") ? "wss://" : "ws://") + html.window.location.host + prefix;
    log("Connecting to " + _url);
    _ws = new html.WebSocket(_url);
    _ws.onOpen.listen((e) {
      connectionStatus = CS_CONNECTED;
      connected = true;
      log('WebSocket Connected to ' + _url);
      RECONNECT_TIMEOUT = 0;

      /// For reconnect
      _mergeAlarmSet(forceWatchSet: true);
      _mergeCommandSet(forceWatchSet: true);
      _mergeFunctionModuleSet(forceWatchSet: true);
      _mergeMeasurementSet(forceWatchSet: true);

      _keepAliveTimer = new Timer.periodic(new Duration(seconds: 30), (Timer t) {
        heartbeat();
      });



      _ws.onMessage.listen((html.MessageEvent e) {
        Map<String, dynamic> data = JSON.decode(e.data);
        if (data.containsKey("notification")){
          switch(data["notification"]){

            case WS_RESPONSE_ALARMS_STATE_CHANGE_NOTIFICATION:
              Set<Alarm> a = new Set<Alarm>();
              data["changes"].forEach((_) {
                  String name = _["name"];

                  if(_opendaf.root.alarms.containsKey(name))
                    _opendaf.root.alarms[name].updateRuntimeJson(_);
                    
                  a.add(new Alarm.fromRuntimeJson(this._opendaf, _));
              });
              eventController.add(new AlarmStateChangeNotification()..alarms = a);
            break;

            case WS_RESPONSE_COMMAND_UPDATE_NOTIFICATION:
            //   Set<Command> c = new Set<Command>();
			  log("Command notification: ${data['updates'].length} updates ... ${new DateTime.now()}");
              data["updates"].forEach((_) {
                  String name = _["name"];

                  if(_opendaf.root.commands.containsKey(name))
                    _opendaf.root.commands[name].updateRuntimeJson(_);
                    
                //   c.add(new Command.fromRuntimeJson(this._opendaf, _));
              });
            //   eventController.add(new CommandUpdateNotification()..commands = c);
			  log("Command notification: ${data['updates'].length} updates ... OK");
            break;

            case WS_RESPONSE_FUNCTION_MODULE_UPDATE_NOTIFICATION:
              Set<FunctionModule> f = new Set<FunctionModule>();
              data["updates"].forEach((_) {
                  String name = _["name"];

                  if(_opendaf.root.functionModules.containsKey(name))
                    _opendaf.root.functionModules[name].updateRuntimeJson(_);
                    
                  f.add(new FunctionModule.fromRuntimeJson(this._opendaf, _));
              });
              eventController.add(new FunctionModuleUpdateNotification()..functionModules = f);
            break;

            case WS_RESPONSE_MEASUREMENT_UPDATE_NOTIFICATION:
            //   Set<Measurement> m = new Set<Measurement>();
			//   log("Measurement notification: ${data['updates'].length} updates ... ${new DateTime.now()}");
              data["updates"].forEach((_) {
                  String name = _["name"];

                  if(_opendaf.root.measurements.containsKey(name))
                    _opendaf.root.measurements[name].updateRuntimeJson(_);

                //   m.add(new Measurement.fromRuntimeJson(this._opendaf, _));
              });
            //   eventController.add(new MeasurementUpdateNotification()..measurements = m);
			//   log("Measurement notification: ${data['updates'].length} updates ... OK");
            break;

            default:
              throw new Future.error("Notification ${data["notification"]} not implemented!");
          }
        } else if (data.containsKey("request_id")){
          _complete(data["request_id"], data["result"]);
        } else {
          throw new Future.error("Message '${data}' parsing not implemented!");
        };
      });
    });

    _ws.onClose.listen((CloseEvent e) {
      connectionStatus = CS_DISCONNECTED;
      RECONNECT_TIMEOUT = RECONNECT_TIMEOUT < 5 ? RECONNECT_TIMEOUT + 1 : 60;
      log('WebSocket disconnected from $_url, reconnecting in $RECONNECT_TIMEOUT second/s');
      if (_keepAliveTimer != null){
        _keepAliveTimer.cancel();
        _keepAliveTimer = null;
      }
      connected = false;
      connectionFailed = true;

      scheduledReconnect = new DateTime.now().add(new Duration(seconds: RECONNECT_TIMEOUT));
      return futConnection = new Future.delayed(new Duration(seconds: RECONNECT_TIMEOUT), () => reconnect());
    });
  }

  /// A web-socket request function
  ///
  /// Every [message] receives generated [id] before sending to WS Server.
  /// [message] is paired with new [Completer] and sent to WS Server.
  ///
  /// _Returns_ [Completer.future]. Total 3 sending attempts with 1s delay are performed before function returns an [Future.error]
  Future<dynamic> _ws_request(Map<String, dynamic> message, [int retry = 0]){
    if (_ws != null && _ws.readyState == html.WebSocket.OPEN) {
      message["id"] = id_counter++;
      Completer completer = new Completer();
      _completers.putIfAbsent(message["id"], () => completer);

      /// Send message
      log(message["request"] + " (${message["id"]})");
      _ws.send(JSON.encode(message));

      /// Add default timeout completion
      new Timer(new Duration(seconds: WS_TIMEOUT), () => _complete(message["id"], false, "Timeout"));

      return completer.future;
    } else {
      if(retry < 3)
        return new Future.delayed(const Duration(seconds: 1), () => _ws_request(message, retry++));
      else
        return new Future.error('WebSocket not connected, message ${message["request"]} not sent');
    }
  }

  void _complete(int id, bool result, [String reason]){
    if(_completers.containsKey(id)){
      result ? _completers[id].complete(result) : _completers[id].completeError(reason);
      _completers.remove(id);

      if (!result)
        log("Response ($id) completerError: $reason");
      else
        log("Response ($id) completed.");
    }
  }

  Future<dynamic> _mergeMeasurementSet({bool forceWatchSet = false, bool forceUnwatchSet = false}) {
    /// Create copy of [_currentMeasurementsWatchSet] for future diff
    Set<String> oldSet = new Set<String>.from(_watchedMeasurements);
    _watchedMeasurements.clear();

    /// Create new set of [_watchedMeasurements] by merging all sets
    _measurementsByObject.values.forEach((set) { set.forEach((_) { _watchedMeasurements.add(_); }); });

    /// Diff old and new set
    Set<String> toWatch = new Set<String>(), toUnwatch = new Set<String>();
    oldSet.forEach((m) {
      if(!_watchedMeasurements.contains(m) || forceUnwatchSet){
        /// Not in new set anymore, unobserve this measurement
        toUnwatch.add(m);
      }
    });

    _watchedMeasurements.forEach((m) {
      if(!oldSet.contains(m) || forceWatchSet){
        /// Not in new set anymore, unobserve this measurement
        toWatch.add(m);
      }
    });

	List<Future> _futures = new List<Future>();

	if(toUnwatch.isNotEmpty){
		Map<String, dynamic> unwatch = new Map<String, dynamic>();
		unwatch["request"] = WS_REQUEST_UNWATCH_MEASUREMENTS;
		unwatch["measurements"] = toUnwatch.toList();

		_futures.add(_ws_request(unwatch));
	}

	if(toWatch.isNotEmpty){
		Map<String, dynamic> watch = new Map<String, dynamic>();
		watch["request"] = WS_REQUEST_WATCH_MEASUREMENTS;
		watch["measurements"] = toWatch.toList();

		_futures.add(_ws_request(watch));
	}

	if(_futures.isNotEmpty)
		return Future.wait(_futures);
  }

  Future<dynamic> _mergeCommandSet({bool forceWatchSet = false, bool forceUnwatchSet = false}) {
    /// Create copy of [_currentCommandsWatchSet] for future diff
    Set<String> oldSet = new Set<String>.from(_watchedCommands);
    _watchedCommands.clear();

    /// Create new set of [_watchedCommands] by merging all sets
    _commandsByObject.values.forEach((set) { set.forEach((_) { _watchedCommands.add(_); }); });

    /// Diff old and new set
    Set<String> toWatch = new Set<String>(), toUnwatch = new Set<String>();
    oldSet.forEach((c) {
      if(!_watchedCommands.contains(c) || forceUnwatchSet){
        /// Not in new set anymore, unobserve this measurement
        toUnwatch.add(c);
      }
    });

    _watchedCommands.forEach((c) {
      if(!oldSet.contains(c) || forceWatchSet){
        /// Not in new set anymore, unobserve this measurement
        toWatch.add(c);
      }
    });

	List<Future> _futures = new List<Future>();

	if(toUnwatch.isNotEmpty){
    	Map<String, dynamic> unwatch = new Map<String, dynamic>();
    	unwatch["request"] = WS_REQUEST_UNWATCH_COMMANDS;
    	unwatch["commands"] = toUnwatch.toList();

		_futures.add(_ws_request(unwatch));
	}

	if(toWatch.isNotEmpty){
		Map<String, dynamic> watch = new Map<String, dynamic>();
		watch["request"] = WS_REQUEST_WATCH_COMMANDS;
		watch["commands"] = toWatch.toList();

		_futures.add(_ws_request(watch));
	}

	if(_futures.isNotEmpty)
		return Future.wait(_futures);
  }

  Future<dynamic> _mergeFunctionModuleSet({bool forceWatchSet = false, bool forceUnwatchSet = false}) {
    /// Create copy of [_currentCommandsWatchSet] for future diff
    Set<String> oldSet = new Set<String>.from(_watchedFunctionModules);
    _watchedFunctionModules.clear();

    /// Create new set of [_watchedFunctionModules] by merging all sets
    _functionModulesByObject.values.forEach((set) { set.forEach((_) { _watchedFunctionModules.add(_); }); });

    /// Diff old and new set
    Set<String> toWatch = new Set<String>(), toUnwatch = new Set<String>();
    oldSet.forEach((_) {
      if(!_watchedFunctionModules.contains(_) || forceUnwatchSet){
        /// Not in new set anymore, unobserve this measurement
        toUnwatch.add(_);
      }
    });

    _watchedFunctionModules.forEach((_) {
      if(!oldSet.contains(_) || forceWatchSet){
        /// Not in new set anymore, unobserve this measurement
        toWatch.add(_);
      }
    });

	List<Future> _futures = new List<Future>();

	if(toUnwatch.isNotEmpty){
		Map<String, dynamic> unwatch = new Map<String, dynamic>();
		unwatch["request"] = WS_REQUEST_UNWATCH_FUNCTION_MODULES;
		unwatch["function_modules"] = toUnwatch.toList();

		_futures.add(_ws_request(unwatch));
	}

	if(toWatch.isNotEmpty){
		Map<String, dynamic> watch = new Map<String, dynamic>();
		watch["request"] = WS_REQUEST_WATCH_FUNCTION_MODULES;
		watch["function_modules"] = toWatch.toList();

		_futures.add(_ws_request(watch));
	}

	if(_futures.isNotEmpty)
		return Future.wait(_futures);
  }

  Future<dynamic> _mergeAlarmSet({bool forceWatchSet = false, bool forceUnwatchSet = false}) {
    /// Create copy of [_currentAlarmsWatchSet] for future diff
    Set<String> oldSet = new Set<String>.from(_watchedAlarms);
    _watchedAlarms.clear();

    /// Create new set of [_watchedAlarms] by merging all sets
    _alarmsByObject.values.forEach((set) { set.forEach((_) { _watchedAlarms.add(_); }); });

    /// Diff old and new set
    Set<String> toWatch = new Set<String>(), toUnwatch = new Set<String>();
    oldSet.forEach((a) {
      if(!_watchedAlarms.contains(a) || forceUnwatchSet){
        /// Not in new set anymore, unobserve this measurement
        toUnwatch.add(a);
      }
    });

    _watchedAlarms.forEach((a) {
      if(!oldSet.contains(a) || forceWatchSet){
        /// Not in new set anymore, unobserve this measurement
        toWatch.add(a);
      }
    });

	List<Future> _futures = new List<Future>();

	if(toUnwatch.isNotEmpty){
		Map<String, dynamic> unwatch = new Map<String, dynamic>();
		unwatch["request"] = WS_REQUEST_UNWATCH_ALARMS;
		unwatch["alarms"] = toUnwatch.toList();

		_futures.add(_ws_request(unwatch));
	}

	if(toWatch.isNotEmpty){
		Map<String, dynamic> watch = new Map<String, dynamic>();
		watch["request"] = WS_REQUEST_WATCH_ALARMS;
		watch["alarms"] = toWatch.toList();

		_futures.add(_ws_request(watch));
	}

	if(_futures.isNotEmpty)
		return Future.wait(_futures);
  }

  /* Public functions */

  /// [WatchMeasurements] request handler.
  ///
  /// To unwatch some measurements simply send new [names] Set and let function handle all by itself.
  ///
  /// [objectReference] = usually [this]
  Future<dynamic> watchMeasurements(dynamic objectReference, Set<String> names){
    names.forEach((m) {
     if(m == null )
       throw new StateError("WatchMeasurements accepts only non-null names");
    });
    
    Set<String> watchedMeasurements = _measurementsByObject[objectReference];
    if(watchedMeasurements == null) {
      watchedMeasurements = new Set<String>();
      _measurementsByObject[objectReference] = watchedMeasurements;
    } else {
      watchedMeasurements.clear();
    }
    
    names.forEach((m) {
        watchedMeasurements.add(m);
    });

    return _mergeMeasurementSet();
  }

  Future<dynamic> unwatchAllMeasurements(dynamic objectReference){
    _measurementsByObject[objectReference] = new Set<String>();
    return _mergeMeasurementSet();
  }

  /// [WatchCommands] request handler.
  ///
  /// To unwatch some commands simply send new [names] Set and let function handle all by itself.
  ///
  /// [objectReference] = usually [this]
  Future<dynamic> watchCommands(dynamic objectReference, Set<String> names){
    names.forEach((m) {
     if(m == null )
       throw new StateError("WatchCommands accepts only non-null names");
    });
    
    Set<String> watchedCommands = _commandsByObject[objectReference];
    if(watchedCommands == null) {
      watchedCommands = new Set<String>();
      _commandsByObject[objectReference] = watchedCommands;
    } else {
      watchedCommands.clear();
    }
    
    names.forEach((m) {
        watchedCommands.add(m);
    });

    return _mergeCommandSet();
  }

  Future<dynamic> unwatchAllCommands(dynamic objectReference){
    _commandsByObject[objectReference] = new Set<String>();
    return _mergeCommandSet();
  }

  /// [WatchFunctionModules] request handler.
  ///
  /// To unwatch some function modules simply send new [names] Set and let function handle all by itself.
  ///
  /// [objectReference] = usually [this]
  Future<dynamic> watchFunctionModules(dynamic objectReference, Set<String> names){
    names.forEach((m) {
     if(m == null )
       throw new StateError("WatchFunctionModules accepts only non-null names");
    });
    
    Set<String> watchedFunctionModules = _functionModulesByObject[objectReference];
    if(watchedFunctionModules == null) {
      watchedFunctionModules = new Set<String>();
      _functionModulesByObject[objectReference] = watchedFunctionModules;
    } else {
      watchedFunctionModules.clear();
    }
    
    names.forEach((m) {
        watchedFunctionModules.add(m);
    });

    return _mergeFunctionModuleSet();
  }

  Future<dynamic> unwatchAllFunctionModules(dynamic objectReference){
    _functionModulesByObject[objectReference] = new Set<String>();
    return _mergeFunctionModuleSet();
  }

  /// [WatchAlarms] request handler.
  ///
  /// To unwatch some alarms simply send new [names] Set and let function handle all by itself.
  ///
  /// [objectReference] = usually [this]
  Future<dynamic> watchAlarms(dynamic objectReference, Set<String> names){
    names.forEach((m) {
     if(m == null )
       throw new StateError("WatchAlarms accepts only non-null names");
    });
    
    Set<String> watchedAlarms = _alarmsByObject[objectReference];
    if(watchedAlarms == null) {
      watchedAlarms = new Set<String>();
      _alarmsByObject[objectReference] = watchedAlarms;
    } else {
      watchedAlarms.clear();
    }
    
    names.forEach((m) {
        watchedAlarms.add(m);
    });

    return _mergeAlarmSet();
  }

  Future<dynamic> unwatchAllAlarms(dynamic objectReference){
    _alarmsByObject[objectReference] = new Set<String>();
    return _mergeAlarmSet();
  }

  Future<dynamic> writeCommand (String commandName, String newValueWithPrefix)
  => writeCommands({commandName: newValueWithPrefix});

  Future<dynamic> writeCommands(Map<String, dynamic> commands){
    Map<String, dynamic> properties = new Map<String, dynamic>();
    properties["request"] = WS_REQUEST_WRITE_COMMANDS;

    List<Map<String, dynamic>> items = new List<Map<String, dynamic>>();
    commands.forEach((key, value) {
      Map<String, dynamic> item = new Map<String, dynamic>();
      item["name"] = key;
      item["value"] = value;
      items.add(item);
    });

    properties["writes"] = items;
    return _ws_request(properties);
  }
}
