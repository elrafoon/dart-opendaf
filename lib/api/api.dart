part of opendaf;

class OpendafApi {
	static const int RCFG_OPENDAF = 1, RCFG_ARCHIVE = 2, RCFG_AUTO = 4;
	static String prefix = "/opendaf";
	final OpenDAF _opendaf;
	final http.Client _http;

	OpendafApi(this._opendaf, this._http);

	Future<http.Response> names(String path, {RequestOptions options}) {
		options.fields = ["name"];
		return this.list(path, options: options);
	}

	Future<http.Response> item(String path, String name, {RequestOptions options}) =>
		_http.get("$prefix/$path/$name", headers: OpenDAF._headers);

	Future<http.Response> list(String path, {RequestOptions options}) =>
		_http.get("$prefix/$path/${OpenDAF._formatQuery(options)}", headers: OpenDAF._headers);

	Future<Measurement> measurement(String name) =>
		_http.get("$prefix/measurements/$name")
		.then((http.Response _) => new Measurement.fromRuntimeJson(_opendaf, OpenDAF._json(_)));

	Future<VTQ> vtq(String name) =>
		measurement(name).then((Measurement _) => _.vtq);

	Future<dynamic> value(String name) =>
		vtq(name).then((VTQ _) => _.value);

	/* ----- MEASUREMENTS ----- */
	Future<Map<String, Measurement>> measurements(Iterable<String> names, [Iterable<String> fields = null]) {
		String optNames, optFields;

		if(names.length < OpenDAF.MAX_NAMES_IN_REQUEST)
		optNames = "names=" + names.join(",");

		if(fields != null)
		optFields = "fields=" + fields.join(",");

		final Iterable<String> opts = [optNames, optFields].where((_) => _ != null);
		final String opt = (opts.length > 0) ? ("?" + opts.join("&")) : "";

		return _http.get("$prefix/measurements/$opt")
			.then((http.Response _) {
				Map<String, Measurement> m = new Map<String, Measurement>();
				Map<String, dynamic> rawM = OpenDAF._json(_);
				names.forEach((name) {
					Map<String, dynamic> json = rawM[name];
					if(json != null)
						m[name] = new Measurement.fromRuntimeJson(_opendaf, json);
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

	Future simulateMeasurement(String name, String valueWithPrefix, int quality, {int validFor, int timestamp}) {
		dynamic query = {"value" : valueWithPrefix, "quality" : quality.toString() };
		if(timestamp != null)
			query["timestamp"] = timestamp.toString();
		else
			query["valid-for"] = validFor != null && validFor is num ? validFor.toString() : "60";

		return _http.put(new Uri(path: "$prefix/measurements/$name", queryParameters : query));
	}

	Future stopMeasurementSimulation(String name) =>
		_http.delete(new Uri(path: "$prefix/measurements/$name"));

	/* ----- COMMANDS ----- */
	Future<Command> command(String name) => _http.get("$prefix/commands/$name")
		.then((http.Response _) => new Command.fromRuntimeJson(_opendaf, OpenDAF._json(_)));

	Future<VT> commandVT(String commandName) => command(commandName).then((Command _) => _.vt);
	Future<dynamic> commandValue(String commandName) => vtq(commandName).then((VTQ _) => _.value);

	Future<Map<String, Command>> commands(Iterable<String> names, [Iterable<String> fields = null]) {
		String optNames, optFields;

		if(names.length < OpenDAF.MAX_NAMES_IN_REQUEST)
			optNames = "names=" + names.join(",");

		if(fields != null)
			optFields = "fields=" + fields.join(",");

		final Iterable<String> opts = [optNames, optFields].where((_) => _ != null);
		final String opt = (opts.length > 0) ? ("?" + opts.join("&")) : "";

		return _http.get("$prefix/commands/$opt")
			.then((http.Response _) {
				Map<String, Command> m = new Map<String, Command>();
				Map<String, dynamic> rawM = OpenDAF._json(_);
				rawM.forEach((String name, dynamic json) { m[name] = new Command.fromRuntimeJson(_opendaf, json); });
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

	Future writeCommand(String name, String valueWithPrefix) =>
		_http.put(new Uri(path: "$prefix/commands/$name", queryParameters : {"value" : valueWithPrefix}));

	/* ----- ALARMS ----- */
	Future alarmOperation(String name, String op, { String authority = "webdaf" }) =>
		_http.post("$prefix/alarms/$name/$op?authority=$authority");

	/* ----- MANAGEMENT ----- */
	Future reconfigure() =>
		_http.post("$prefix/management/reconfigure");

	Future<int> get pid =>
		_http.get("$prefix/management/pid")
		.then((http.Response rsp) => OpenDAF._parsePid(rsp.body));
}