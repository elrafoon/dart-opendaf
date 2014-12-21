library opendaf;

import 'dart:async';
import 'package:angular/angular.dart';

part 'model/value.dart';
part 'model/range.dart';
part 'model/vt.dart';
part 'model/vtq.dart';
part 'model/measurement.dart';

@Injectable()
class OpenDAF {
  final String prefix = "/";
  final String archPrefix = "/archive/";
  final Http _http;
  
  OpenDAF(this._http);
  
  Future<Measurement> measurement(String name) => _http.get(prefix + "measurements/" + name)
      .then((HttpResponse _) => new Measurement.fromJson(_.data));
  Future<VTQ> vtq(String measurementName) => measurement(measurementName).then((Measurement _) => _.vtq);
  Future<dynamic> value(String measurementName) => vtq(measurementName).then((VTQ _) => _.value);
  
  Future<Map<String, Measurement>> measurements(Iterable<String> names) => _http.get(prefix + "measurements/?names=" + names.join(","))
      .then((HttpResponse _) {
        Map<String, Measurement> m = new Map<String, Measurement>();
        Map<String, dynamic> rawM = _.data;
        rawM.forEach((String name, dynamic json) { m[name] = new Measurement.fromJson(json); });
        return m;
      });
  Future<Map<String, VTQ>> vtqs(Iterable<String> names) => measurements(names)
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
  
  Future writeCommand(String command, String valueWithPrefix) => 
      _http.put(prefix + "commands/" + command, null, params : {"value" : valueWithPrefix});
  
  Future<List<VTQ>> measurementHistory(String name, DateTime from, DateTime to) =>
      _http.get(archPrefix + "measurements/$name/${from.millisecondsSinceEpoch ~/ 1000}/${to.millisecondsSinceEpoch ~/ 1000}")
      .then((HttpResponse _) {
        List rawSamples = _.data[name];
        List<VTQ> samples = rawSamples.map((_) => new VTQ.fromJson(_)).toList();
        if(samples.length > 0) {
          if(samples.last.timestamp.compareTo(to) != 0)
            samples.add(new VTQ(samples.last.value, to, samples.last.quality, samples.last.dataType));
        }
        return samples;
      });
  
  Future<Map<String, List<VTQ>>> measurementsHistory(List<String> names, DateTime from, DateTime to) =>
    Future.wait(
      names.map((_) => measurementHistory(_, from, to))
    )
    .then((List<List<VTQ>> l) {
      Map<String, List<VTQ>> m = new Map<String, List<VTQ>>();
      for(int i = 0; i < names.length; ++i)
        m[names[i]] = l[i];
      return m;
    });
}
