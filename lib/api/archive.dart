part of opendaf;

class OpendafArchive {
	static String prefix = "/opendaf/archive/";
	final OpenDAF _opendaf;
	final http.Client _http;

	OpendafArchive(this._opendaf, this._http);
	
	Future<List> _history(String coType, String name, dynamic from, dynamic to, Duration resample, bool warpHead) {
		Map<String, dynamic> params = new Map<String, dynamic>();

		if(resample != null)
			params["resample"] = (resample.inMilliseconds.toDouble() / 1000.0).toString();

		if(warpHead == false)
			params["warp_head"] = "0";

		return _http.get(new Uri(path: "$prefix/$coType/$name" + OpenDAF._fmtQueryTimeRange(from, to), queryParameters: params))
			.then((http.Response _) {
				List rawSamples = OpenDAF._json(_)[name];
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

		return _http.delete("$prefix/$coType/$name" + OpenDAF._fmtQueryTimeRange(from, to));
	}

	Future eraseMeasurementHistory(String name, { DateTime from, DateTime to }) =>
		_eraseHistory("measurements", name, from, to);

	Future eraseCommandHistory(String name, { DateTime from, DateTime to }) =>
		_eraseHistory("commands", name, from, to);

	Future eraseMeasurementHistoryRelative(String name, { dynamic from, dynamic to }) =>
		_eraseHistory("measurements", name, from, to);

	Future eraseCommandHistoryRelative(String name, { dynamic from, dynamic to }) =>
		_eraseHistory("commands", name, from, to);

	Future reconfigure() =>
		_http.post("$prefix/management/reconfigure");

	Future<int> get pid =>
		_http.get("$prefix/management/pid")
		.then((http.Response rsp) => OpenDAF._parsePid(rsp.body));
}