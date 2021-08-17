library opendaf;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:html';
import 'package:angular/angular.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:intl/intl.dart';

part 'model/alarm.dart';
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
part 'model/root.dart';
part 'model/connector.dart';
part 'model/provider.dart';
part 'model/stack.dart';
part 'model/stack_instantion.dart';

part 'controller/alarm.dart';
part 'controller/measurement.dart';
part 'controller/command.dart';
part 'controller/provider.dart';
part 'controller/connector.dart';
part 'controller/connectorStack.dart';
part 'controller/providerStack.dart';
part 'controller/function_module.dart';
part 'controller/controller.dart';

part 'opendaf_ws.dart';

@Injectable()
class OpenDAF {
  static String opendafPrefix = "/opendaf/";
  static String archPrefix = "/opendaf/archive/";
  static String dafmanPrefix = "/dafman/v2";
  final http.Client _http;

  static const int MAX_NAMES_IN_REQUEST = 2000;

  Controller ctrl;

  Root root;

  OpenDAF(this._http) {
    root = new Root();
    ctrl = new Controller(this, this._http);
  }


  static Map<String, String> _headers = { "content-type" : "application/json; charset=UTF-8" };
  static dynamic _json(http.Response rsp) => rsp != null ? JSON.decode(new Utf8Decoder().convert(rsp.bodyBytes)) : null;

  /* REST API Function */
  Future<List<String>> names(String prefix) =>
    _http.get("$dafmanPrefix/$prefix/names", headers: _headers)
    .then((http.Response response) => _json(response));

  Future create(String prefix, String name, Map<String, dynamic> js) => 
    _http.put(
      new Uri(path: "$dafmanPrefix/$prefix/$name"),
      body: JSON.encode(js),
      headers: {'Content-Type': 'application/json'}
    );

  Future update(String prefix, String name, Map<String, dynamic> js) =>
    _http.put(
      new Uri(path: "$dafmanPrefix/$prefix/$name"),
      body: JSON.encode(js),
      headers: {'Content-Type': 'application/json'}
    );
  
  Future delete(String prefix, String name) =>
    _http.delete("$dafmanPrefix/$prefix/$name");

  Future<List<http.Response>> item(String prefix, String name, {RequestOptions options}) =>
    Future.wait([
      options.fetchConfiguration  ? _http.get("$dafmanPrefix/$prefix/$name", headers: _headers) : new Future.value({}),
      options.fetchRuntime        ? _http.get("$opendafPrefix/$prefix/$name", headers: _headers) : new Future.value({})
    ]);

  Future<List<http.Response>> list(String prefix, {RequestOptions options}) {
    String optNames, optFields;

    if(options.names != null && options.names.length <= MAX_NAMES_IN_REQUEST)
      optNames = "names=" + options.names.join(",");

    if(options.fields != null)
      optFields = "fields=" + options.fields.join(",");

    final Iterable<String> opts = [optNames, optFields].where((_) => _ != null);
    final String opt = (opts.length > 0) ? ("?" + opts.join("&")) : "";

    return Future.wait([
      options.fetchConfiguration  ? _http.get("$dafmanPrefix/$prefix/$opt", headers: _headers) : new Future.value({}),
      options.fetchRuntime        ? _http.get("$opendafPrefix/$prefix/$opt", headers: _headers) : new Future.value({})
    ]);
  }


  Future<Measurement> measurement(String name) => _http.get(opendafPrefix + "measurements/" + name)
      .then((http.Response _) => new Measurement.fromRuntimeJson(this, _json(_)));
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
      _http.get(opendafPrefix + "measurements/" + opt)
      .then((http.Response _) {
        Map<String, Measurement> m = new Map<String, Measurement>();
        Map<String, dynamic> rawM = _json(_);
        names.forEach((name) {
          Map<String, dynamic> json = rawM[name];
          if(json != null)
            m[name] = new Measurement.fromRuntimeJson(this, json);
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

  Future simulateMeasurement(String measurement, String valueWithPrefix, int quality, {int validFor, int timestamp}) {
    dynamic query = {"value" : valueWithPrefix, "quality" : quality.toString() };
    if(timestamp != null)
      query["timestamp"] = timestamp.toString();
    else
      query["valid-for"] = validFor != null && validFor is num ? validFor.toString() : "60";

    return _http.put(new Uri(path: opendafPrefix + "measurements/" + measurement, queryParameters : query));
  }

  Future stopMeasurementSimulation(String measurement) => 
    _http.delete(new Uri(path: opendafPrefix + "measurements/" + measurement));
  
     

  Future<Command> command(String name) => _http.get(opendafPrefix + "commands/" + name)
      .then((http.Response _) => new Command.fromRuntimeJson(this, _json(_)));
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
      _http.get(opendafPrefix + "commands/" + opt)
      .then((http.Response _) {
        Map<String, Command> m = new Map<String, Command>();
        Map<String, dynamic> rawM = _json(_);
        rawM.forEach((String name, dynamic json) { m[name] = new Command.fromRuntimeJson(this, json); });
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
      _http.put(new Uri(path: opendafPrefix + "commands/" + command, queryParameters : {"value" : valueWithPrefix}));

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

  Future<List> _history(String coType, String name, dynamic from, dynamic to, Duration resample, bool warpHead) {
    Map<String, dynamic> params = new Map<String, dynamic>();
    if(resample != null)
      params["resample"] = (resample.inMilliseconds.toDouble() / 1000.0).toString();

    if(warpHead == false)
      params["warp_head"] = "0";

    return _http.get(new Uri(path: archPrefix + "$coType/$name" + _fmtQueryTimeRange(from, to), queryParameters: params))
    .then((http.Response _) {
      List rawSamples = _json(_)[name];
      switch(coType) {
        case "measurements":
          return rawSamples.map((_) => new VTQ.fromJson(_)).toList();
        case "commands":
          return rawSamples.map((_) => new VT.fromJson(_)).toList();
        default:
          throw new ArgumentError("Unknown communication object type $coType");
      }
    });
  }

  Future<Map<String, List>> _histories(String coType, List<String> names, dynamic from, dynamic to, Duration resample, bool warpHead, bool parallel) async {
    Future fut;

    if(parallel)
      fut = Future.wait(names.map((_) => _history(coType, _, from, to, resample, warpHead)));
    else {
      List<List> l = new List<List>();
      for(int i = 0; i < names.length; ++i)
        l.add(await _history(coType, names[i], from, to, resample, warpHead));

      fut = new Future.value(l);
    }

    return fut.then((List<List> l) {
      Map<String, List> m = new Map<String, List>();
      for(int i = 0; i < names.length; ++i)
        m[names[i]] = l[i];
      return m;
    });
  }

  /* frontends */

  // expects negative offset relative to server's current time or absolute DateTime
  Future<List<VTQ>> measurementHistory(String name, dynamic from, dynamic to, {Duration resample, bool warpHead: true}) =>
      _history("measurements", name, from, to, resample, warpHead) as Future<List<VTQ>>;

  // expects negative offset relative to server's current time or absolute DateTime
  Future<Map<String, List<VTQ>>> measurementsHistory(List<String> names, dynamic from, dynamic to, {Duration resample, bool warpHead: true, bool parallel: false}) =>
      _histories("measurements", names, from, to, resample, warpHead, parallel) as Future<Map<String, List<VTQ>>>;

  // expects negative offset relative to server's current time or absolute DateTime
  Future<List<VT>> commandHistory(String name, dynamic from, dynamic to, {Duration resample, bool warpHead: true}) =>
      _history("commands", name, from, to, resample, warpHead) as Future<List<VT>>;

  // expects negative offset relative to server's current time or absolute DateTime
  Future<Map<String, List<VT>>> commandsHistory(List<String> names, dynamic from, dynamic to, {Duration resample, bool warpHead: true, bool parallel: false}) =>
      _histories("commands", names, from, to, resample, warpHead, parallel) as Future<Map<String, List<VT>>>;

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
      Future f = ((mask & RCFG_OPENDAF) != 0) ? _http.post(opendafPrefix + "management/reconfigure") : new Future.value();
      return ((mask & RCFG_ARCHIVE) != 0) ? f.then((_) => _http.post(archPrefix + "management/reconfigure")) : f;
    }
    else {
      return Future.wait([
        pid.catchError((e) => null).then((_) => (_ == null) ? null : _http.post(opendafPrefix + "management/reconfigure")),
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
      _http.get(opendafPrefix + "management/pid").then((http.Response rsp) => _parsePid(rsp.body));

  Future<int> get archivePid =>
      _http.get(archPrefix + "management/pid").then((http.Response rsp) => _parsePid(rsp.body));

  Future downloadDatabase() =>
    _http.get(dafmanPrefix + '/cfgdb/database')
    .then((rsp) => _json(rsp));
  
  Future uploadDatabase(File database, {bool render: true}) =>
      HttpRequest.request(
          new Uri(path: dafmanPrefix + '/cfgdb/database').toString() + "?render=${render ? '1' : '0'}",
          method: 'POST',
          mimeType: "application/octet-stream",
          sendData: database,
          requestHeaders: { 'Content-Type': 'application/octet-stream' }
      );

  Future render() => _http.post(dafmanPrefix + "/cfgdb/render");
  
  Future<bool> get isRenderUpToDate => _http.get(dafmanPrefix + "/cfgdb/render").then((http.Response rsp) => _json(rsp));
}
