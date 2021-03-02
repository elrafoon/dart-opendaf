part of opendaf;

abstract class StreamEvent {}

class Response extends StreamEvent{}
class AlarmStateChangeNotification extends StreamEvent{ Set<Alarm> alarms; }
class MeasurementUpdateNotification extends StreamEvent{ Set<Measurement> measurements; }


@Injectable()
class OpenDAFWS {
  /// Constants
  static const String WS_RESPONSE = "Response";
  static const String WS_RESPONSE_MEASUREMENT_UPDATE_NOTIFICATION = "MeasurementUpdateNotification";
  static const String WS_RESPONSE_ALARMS_STATE_CHANGE_NOTIFICATION = "AlarmStateChangeNotification";

  static const String WS_REQUEST = "Request";
  static const String WS_HEARTBEAT = "Heartbeat";
  static const String WS_REQUEST_WATCH_MEASUREMENTS = "WatchMeasurements";
  static const String WS_REQUEST_UNWATCH_MEASUREMENTS = "UnwatchMeasurements";
  static const String WS_REQUEST_WATCH_ALARMS = "WatchAlarms";
  static const String WS_REQUEST_UNWATCH_ALARMS = "UnwatchAlarms";
  static const String WS_REQUEST_ACK_ALARMS = "AckAlarms";
  static const String WS_REQUEST_WRITE_COMMANDS = "WriteCommands";

  static const String prefix = "/opendaf/ws/opendaf/";
  static const int WS_TIMEOUT = 10;
  static int RECONNECT_TIMEOUT = 0;

  /// Variables
  final http.Client _http;
  static int id_counter = 0;
  static const int MAX_NAMES_IN_REQUEST = 2000;
  final StreamController<StreamEvent> eventController = new StreamController<StreamEvent>.broadcast();
  Stream<StreamEvent> eventStream;
  Future futConnection;
  bool connected = false;
  html.WebSocket _ws;
  String _url;
  Timer _keepAliveTimer;

  Map<int, Completer> _completers = new Map<int, Completer>();

  final Map<dynamic, Set<String>> _measurementsByObject = new Map<dynamic, Set<String>>();
  Set<String> _watchedMeasurements = new Set<String>();


  OpenDAFWS(this._http) {
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
    _url = ((html.window.location.protocol == "https:") ? "wss://" : "ws://") + html.window.location.host + prefix;
    log("Connecting to " + _url);
    _ws = new html.WebSocket(_url);
    _ws.onOpen.listen((e) {
      log('WebSocket Connected to ' + _url);
      connected = true;
      RECONNECT_TIMEOUT = 0;

      /// For reconnect
      _mergeMeasurementSet(forceWatchSet: true);

      _keepAliveTimer = new Timer.periodic(new Duration(seconds: 30), (Timer t) {
        heartbeat();
      });



      _ws.onMessage.listen((html.MessageEvent e) {
        Map<String, dynamic> data = JSON.decode(e.data);
        if (data.containsKey("notification")){
          switch(data["notification"]){

            case WS_RESPONSE_MEASUREMENT_UPDATE_NOTIFICATION:
              Set<Measurement> m = new Set<Measurement>();
              data["updates"].forEach((measurementUpdate) {
                  m.add(new Measurement.fromJson(measurementUpdate));
              });
              eventController.add(new MeasurementUpdateNotification()..measurements = m);
              break;

            case WS_RESPONSE_ALARMS_STATE_CHANGE_NOTIFICATION:
              Set<Alarm> a = new Set<Alarm>();
              data["changes"].forEach((alarmStateChange) {
                  a.add(new Alarm.fromJson(alarmStateChange));
              });
              eventController.add(new AlarmStateChangeNotification()..alarms = a);
              eventController.add(new AlarmStateChangeNotification());
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

    _ws.onClose.listen((e) {
      log('WebSocket disconnected from ' + _url);
      if (_keepAliveTimer != null){
        _keepAliveTimer.cancel();
        _keepAliveTimer = null;
      }
      connected = false;
      RECONNECT_TIMEOUT = RECONNECT_TIMEOUT < 10 ? RECONNECT_TIMEOUT++ : 60;
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
        log("Response (" + id.toString() + ") competerError: " + reason);
      else
        log("Response (" + id.toString() + ") completed.");
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


    Map<String, dynamic> unwatch = new Map<String, dynamic>();
    unwatch["request"] = WS_REQUEST_UNWATCH_MEASUREMENTS;
    unwatch["measurements"] = toUnwatch.toList();

    Map<String, dynamic> watch = new Map<String, dynamic>();
    watch["request"] = WS_REQUEST_WATCH_MEASUREMENTS;
    watch["measurements"] = toWatch.toList();

//    print("toUnwatch: " + toUnwatch.toString());
//    print("toWatch: " + toWatch.toString());

    return Future.wait([
      toUnwatch.isNotEmpty ? _ws_request(unwatch) : new Future.value(),
      toWatch.isNotEmpty ? _ws_request(watch) : new Future.value(),
    ]);
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

    names.forEach((m) {
      Set<String> watchedMeasurements = _measurementsByObject[objectReference];
      if(watchedMeasurements == null) {
        watchedMeasurements = new Set<String>();
        _measurementsByObject[objectReference] = watchedMeasurements;
      }

      watchedMeasurements.add(m);
    });

    return _mergeMeasurementSet();
  }

  Future<dynamic> unwatchAllMeasurements(dynamic objectReference){
    _measurementsByObject[objectReference] = new Set<String>();
    return _mergeMeasurementSet();
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
