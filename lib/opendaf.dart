library opendaf;

import 'dart:async';
import 'dart:convert';
import 'package:angular/angular.dart';
import 'package:http/http.dart' as http;

part 'model/datatype.dart';
part 'model/quality.dart';
part 'model/value.dart';
part 'model/range.dart';
part 'model/vt.dart';
part 'model/vtq.dart';
part 'model/communication_object.dart';
part 'model/measurement.dart';
part 'model/command.dart';
part 'model/field.dart';
part 'model/function_module.dart';
part 'model/alarm.dart';

@Injectable()
class OpenDAF {
  final String prefix = "/opendaf/";
  final String archPrefix = "/opendaf/archive/";
  final http.Client _http;
  
  static const int MAX_NAMES_IN_REQUEST = 2000;
  
  OpenDAF(this._http);
  
  static dynamic _json(http.Response rsp) => JSON.decode(rsp.body);
  
  Future<Measurement> measurement(String name) => _http.get(prefix + "measurements/" + name)
      .then((http.Response _) => new Measurement.fromJson(_json(_)));
  Future<VTQ> vtq(String measurementName) => measurement(measurementName).then((Measurement _) => _.vtq);
  Future<dynamic> value(String measurementName) => vtq(measurementName).then((VTQ _) => _.value);
  
  Future<Map<String, Measurement>> measurements(Iterable<String> names, [Iterable<String> fields = null]) {
    String optNames, optFields;
    
    if(names.length < MAX_NAMES_IN_REQUEST)
      optNames = "names=" + names.join(",");
    
    if(fields != null)
      optFields = "fields=" + fields.join(",");

    final Iterable<String> opts = [optNames, optFields].where((_) => _ != null);
    final String opt = (opts.length > 0) ? ("?" + opts.join("&")) : "";
    
    return
      _http.get(prefix + "measurements/" + opt)
      .then((http.Response _) {
        Map<String, Measurement> m = new Map<String, Measurement>();
        Map<String, dynamic> rawM = _json(_);
        names.forEach((name) {
          Map<String, dynamic> json = rawM[name];
          if(json != null)
            m[name] = new Measurement.fromJson(json);
        });
        return m;
      });
  }

  Future<Map<String, VTQ>> vtqs(Iterable<String> names) => measurements(names, [Field.VTQ])
      .then((Map<String, Measurement> _) {
        Map<String, VTQ> m = new Map<String, VTQ>();
        _.forEach((String name, Measurement mes) { m[name] = mes.vtq; });
        return m;
      });

  Future<Map<String, dynamic>> values(Iterable<String> names) => vtqs(names)
      .then((Map<String, VTQ> _) {
        Map<String, dynamic> m = new Map<String, dynamic>();
        _.forEach((String name, VTQ vtq) { m[name] = vtq.value; });
        return m;
      });
  
  Future<Command> command(String name) => _http.get(prefix + "commands/" + name)
      .then((http.Response _) => new Command.fromJson(_json(_)));
  Future<VT> commandVT(String commandName) => command(commandName).then((Command _) => _.vt);
  Future<dynamic> commandValue(String commandName) => vtq(commandName).then((VTQ _) => _.value);
  
  Future<Map<String, Command>> commands(Iterable<String> names, [Iterable<String> fields = null]) {
    String optNames, optFields;
    
    if(names.length < MAX_NAMES_IN_REQUEST)
      optNames = "names=" + names.join(",");
    
    if(fields != null)
      optFields = "fields=" + fields.join(",");

    final Iterable<String> opts = [optNames, optFields].where((_) => _ != null);
    final String opt = (opts.length > 0) ? ("?" + opts.join("&")) : "";
    
    return
      _http.get(prefix + "commands/" + opt)
      .then((http.Response _) {
        Map<String, Command> m = new Map<String, Command>();
        Map<String, dynamic> rawM = _json(_);
        rawM.forEach((String name, dynamic json) { m[name] = new Command.fromJson(json); });
        return m;
      });
  }
  
  Future<Map<String, VT>> commandVTs(Iterable<String> names) => commands(names, [Field.VT])
      .then((Map<String, Command> _) {
        Map<String, VT> m = new Map<String, VT>();
        _.forEach((String name, Command cmd) { m[name] = cmd.vt; });
        return m;
      });

  Future<Map<String, dynamic>> commandValues(Iterable<String> names) => commandVTs(names)
      .then((Map<String, VT> _) {
        Map<String, dynamic> m = new Map<String, dynamic>();
        _.forEach((String name, VT vt) { m[name] = vt.value; });
        return m;
      });

  Future writeCommand(String command, String valueWithPrefix) => 
      _http.put(new Uri(path: prefix + "commands/" + command, queryParameters : {"value" : valueWithPrefix}));

  Future<FunctionModule> functionModule(String name) =>
      _http.get("$prefix/function-modules/$name")
      .then((http.Response _) => new FunctionModule.fromJson(_json(_)));
        
  Future<Map<String, FunctionModule>> functionModules(Iterable<String> names) =>
      _http.get("$prefix/function-modules/")
      .then((http.Response _) {
        Map<String, FunctionModule> fm = new Map<String, FunctionModule>();
        Map<String, dynamic> rawFMs = _json(_);
        names.forEach((name) {
          Map<String, dynamic> json = rawFMs[name];
          if(json != null)
            fm[name] = new FunctionModule.fromJson(json);
        });
        return fm;
      });
  
  Future<Alarm> alarm(String name) =>
      _http.get("$prefix/alarms/$name")
      .then((http.Response _) => new Alarm.fromJson(_json(_)));
        
  Future<Map<String, Alarm>> alarms(Iterable<String> names, [Iterable<String> fields = null]) {
    String optNames, optFields;
    
    if(names.length < MAX_NAMES_IN_REQUEST)
      optNames = "names=" + names.join(",");
    
    if(fields != null)
      optFields = "fields=" + fields.join(",");

    final Iterable<String> opts = [optNames, optFields].where((_) => _ != null);
    final String opt = (opts.length > 0) ? ("?" + opts.join("&")) : "";    

    return _http.get("$prefix/alarms/$opt")
    .then((http.Response _) {
      Map<String, Alarm> alm = new Map<String, Alarm>();
      Map<String, dynamic> rawAlms = _json(_);
      names.forEach((name) {
        Map<String, dynamic> json = rawAlms[name];
        if(json != null)
          alm[name] = new Alarm.fromJson(json);
      });
      return alm;
    });
  }
  
  Future _alarmOp(String name, String op) =>
    _http.post("$prefix/alarms/$name/$op");
  
  Future alarmAcknowledge(String name) => _alarmOp(name, "acknowledge");
  Future alarmActivate(String name) => _alarmOp(name, "activate");
  Future alarmDeactivate(String name) => _alarmOp(name, "deactivate");
  
  /*
   * archive access
   */
  
  /*
   * backend
   */
  String _fmtQueryTime(dynamic t) {
    if(t is DateTime)
      return "${t.millisecondsSinceEpoch ~/ 1000}";
    else if(t is num && t <= 0)
      return "${t.toStringAsFixed(6)}";
    else
      throw new ArgumentError();
  }

  String _fmtQueryTimeRange(dynamic from, dynamic to) {
    return "/${_fmtQueryTime(from)}/${_fmtQueryTime(to)}";
  }
  
  Future<List<VTQ>> _history(String coType, String name, dynamic from, dynamic to, Duration resample, bool warpHead) {
    Map<String, dynamic> params = new Map<String, dynamic>();
    if(resample != null)
      params["resample"] = resample.inMilliseconds.toDouble() / 1000.0;
    
    if(warpHead == false)
      params["warp_head"] = 0;
    
    return _http.get(new Uri(path: archPrefix + "$coType/$name" + _fmtQueryTimeRange(from, to), queryParameters: params))
    .then((http.Response _) {
      List rawSamples = _json(_)[name];
      switch(coType) {
        case "measurements":
          return rawSamples.map((_) => new VTQ.fromJson(_)).toList();
        case "commands":
          return rawSamples.map((_) => new VT.fromJson(_)).toList();
        default:
          return new ArgumentError("Unknown communication object type $coType");
      }
    });
  }
  
  Future<Map<String, List<VTQ>>> _histories(String coType, List<String> names, dynamic from, dynamic to, Duration resample, bool warpHead) =>
    Future.wait(
      names.map((_) => _history(coType, _, from, to, resample, warpHead))
    )
    .then((List<List<VTQ>> l) {
      Map<String, List<VTQ>> m = new Map<String, List<VTQ>>();
      for(int i = 0; i < names.length; ++i)
        m[names[i]] = l[i];
      return m;
    });

  /* frontends */
  
  // expects negative offset relative to server's current time or absolute DateTime
  Future<List<VTQ>> measurementHistory(String name, dynamic from, dynamic to, {Duration resample, bool warpHead: true}) =>
      _history("measurements", name, from, to, resample, warpHead);
  
  // expects negative offset relative to server's current time or absolute DateTime
  Future<Map<String, List<VTQ>>> measurementsHistory(List<String> names, dynamic from, dynamic to, {Duration resample, bool warpHead: true}) =>
      _histories("measurements", names, from, to, resample, warpHead);
   
  // expects negative offset relative to server's current time or absolute DateTime
  Future<List<VT>> commandHistory(String name, dynamic from, dynamic to, {Duration resample, bool warpHead: true}) =>
      _history("commands", name, from, to, resample, warpHead);

  // expects negative offset relative to server's current time or absolute DateTime
  Future<Map<String, List<VT>>> commandsHistory(List<String> names, dynamic from, dynamic to, {Duration resample, bool warpHead: true}) =>
      _histories("commands", names, from, to, resample, warpHead);

  Future _eraseHistory(String coType, String name, dynamic from, dynamic to) {
    if(from == null)
      from = new DateTime.fromMillisecondsSinceEpoch(0);
    
    if(to == null)
      to = new DateTime.now();
    
    return _http.delete(archPrefix + "$coType/$name" + _fmtQueryTimeRange(from, to));    
  }
  
  Future eraseMeasurementHistory(String name, { DateTime from, DateTime to }) =>
      _eraseHistory("measurements", name, from, to);

  Future eraseCommandHistory(String name, { DateTime from, DateTime to }) =>
      _eraseHistory("commands", name, from, to);

  Future eraseMeasurementHistoryRelative(String name, { dynamic from, dynamic to }) =>
      _eraseHistory("measurements", name, from, to);

  Future eraseCommandHistoryRelative(String name, { dynamic from, dynamic to }) =>
      _eraseHistory("commands", name, from, to);

  static const int RCFG_OPENDAF = 1, RCFG_ARCHIVE = 2, RCFG_AUTO = 4;
  
  Future reconfigure([int mask = RCFG_AUTO]) {
    print("Reconfiguring with mask $mask");
    if(mask != RCFG_AUTO) {
      Future f = ((mask & RCFG_OPENDAF) != 0) ? _http.post(prefix + "management/reconfigure") : new Future.value();
      return ((mask & RCFG_ARCHIVE) != 0) ? f.then((_) => _http.post(archPrefix + "management/reconfigure")) : f;
    }
    else {
      return Future.wait([
        pid.catchError((e) => null).then((_) => (_ == null) ? null : _http.post(prefix + "management/reconfigure")),
        archivePid.catchError((e) => null).then((_) => (_ == null) ? null : _http.post(archPrefix + "management/reconfigure"))
      ]);
    }
  }
  
  int _parsePid(String sPid) {
    try {
      return int.parse(sPid);
    }
    catch(e) {
      return null;
    }
  }
  
  Future<int> get pid =>
      _http.get(prefix + "management/pid").then((http.Response rsp) => _parsePid(rsp.body));

  Future<int> get archivePid =>
      _http.get(archPrefix + "management/pid").then((http.Response rsp) => _parsePid(rsp.body));
}
