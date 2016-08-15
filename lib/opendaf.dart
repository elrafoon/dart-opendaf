library opendaf;

import 'dart:async';
import 'package:angular/angular.dart';

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

@Injectable()
class OpenDAF {
  final String prefix = "/";
  final String archPrefix = "/archive/";
  final Http _http;
  
  static const int MAX_NAMES_IN_REQUEST = 2000;
  
  OpenDAF(this._http);
  
  Future<Measurement> measurement(String name) => _http.get(prefix + "measurements/" + name)
      .then((HttpResponse _) => new Measurement.fromJson(_.data));
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
      .then((HttpResponse _) {
        Map<String, Measurement> m = new Map<String, Measurement>();
        Map<String, dynamic> rawM = _.data;
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
      .then((HttpResponse _) => new Command.fromJson(_.data));
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
      .then((HttpResponse _) {
        Map<String, Command> m = new Map<String, Command>();
        Map<String, dynamic> rawM = _.data;
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
      .then((Map<String, VTQ> _) {
        Map<String, dynamic> m = new Map<String, dynamic>();
        _.forEach((String name, VT vt) { m[name] = vt.value; });
        return m;
      });

  Future writeCommand(String command, String valueWithPrefix) => 
      _http.put(prefix + "commands/" + command, null, params : {"value" : valueWithPrefix});
  
  Future<List<VTQ>> measurementHistory(String name, DateTime from, DateTime to, {Duration resample}) {
    Map<String, dynamic> params = new Map<String, dynamic>();
    if(resample != null)
      params["resample"] = resample.inMilliseconds.toDouble() / 1000.0;
    
    return _http.get(archPrefix + "measurements/$name/${from.millisecondsSinceEpoch ~/ 1000}/${to.millisecondsSinceEpoch ~/ 1000}", params: params)
    .then((HttpResponse _) {
      List rawSamples = _.data[name];
      return rawSamples.map((_) => new VTQ.fromJson(_)).toList();
    });
  }
  
  Future<Map<String, List<VTQ>>> measurementsHistory(List<String> names, DateTime from, DateTime to, {Duration resample}) =>
    Future.wait(
      names.map((_) => measurementHistory(_, from, to, resample: resample))
    )
    .then((List<List<VTQ>> l) {
      Map<String, List<VTQ>> m = new Map<String, List<VTQ>>();
      for(int i = 0; i < names.length; ++i)
        m[names[i]] = l[i];
      return m;
    });
  
  Future<List<VT>> commandHistory(String name, DateTime from, DateTime to, {Duration resample}) {
    Map<String, dynamic> params = new Map<String, dynamic>();
    if(resample != null)
      params["resample"] = resample.inMilliseconds.toDouble() / 1000.0;
    
    return _http.get(archPrefix + "commands/$name/${from.millisecondsSinceEpoch ~/ 1000}/${to.millisecondsSinceEpoch ~/ 1000}", params: params)
    .then((HttpResponse _) {
      List rawSamples = _.data[name];
      return rawSamples.map((_) => new VT.fromJson(_)).toList();
    });
  }
  
  Future<Map<String, List<VT>>> commandsHistory(List<String> names, DateTime from, DateTime to, {Duration resample}) =>
    Future.wait(
      names.map((_) => commandHistory(_, from, to, resample: resample))
    )
    .then((List<List<VT>> l) {
      Map<String, List<VT>> m = new Map<String, List<VT>>();
      for(int i = 0; i < names.length; ++i)
        m[names[i]] = l[i];
      return m;
    });
  
  Future _eraseHistory(String coType, String name, DateTime from, DateTime to) {
    if(from == null)
      from = new DateTime.fromMillisecondsSinceEpoch(0);
    
    if(to == null)
      to = new DateTime.now();
    
    return _http.delete(archPrefix + "$coType/$name/${from.millisecondsSinceEpoch ~/ 1000}/${to.millisecondsSinceEpoch ~/ 1000}");    
  }
  
  Future eraseMeasurementHistory(String name, { DateTime from, DateTime to }) =>
      _eraseHistory("measurements", name, from, to);

  Future eraseCommandHistory(String name, { DateTime from, DateTime to }) =>
      _eraseHistory("commands", name, from, to);

  static const int RCFG_OPENDAF = 1, RCFG_ARCHIVE = 2, RCFG_AUTO = 4;
  
  Future reconfigure([int mask = RCFG_AUTO]) {
    print("Reconfiguring with mask $mask");
    if(mask != RCFG_AUTO) {
      Future f = ((mask & RCFG_OPENDAF) != 0) ? _http.post(prefix + "management/reconfigure", "") : new Future.value();
      return ((mask & RCFG_ARCHIVE) != 0) ? f.then((_) => _http.post(archPrefix + "management/reconfigure", "")) : f;
    }
    else {
      return Future.wait([
        pid.catchError((e) => null).then((_) => (_ == null) ? null : _http.post(prefix + "management/reconfigure", "")),
        archivePid.catchError((e) => null).then((_) => (_ == null) ? null : _http.post(archPrefix + "management/reconfigure", ""))
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
      _http.get(prefix + "management/pid").then((HttpResponse rsp) => _parsePid(rsp.data.toString()));

  Future<int> get archivePid =>
      _http.get(archPrefix + "management/pid").then((HttpResponse rsp) => _parsePid(rsp.data.toString()));
}
