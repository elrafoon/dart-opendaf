part of opendaf;

class OpendafDafman {
	static String prefix = "/dafman/v2/";
	final OpenDAF _opendaf;
	final http.Client _http;

	OpendafDafman(this._opendaf, this._http);

	Future<List<String>> names(String path) =>
		_http.get("$prefix/$path/names", headers: OpenDAF._headers)
		.then((http.Response response) => OpenDAF._json(response));

	Future create(String path, String name, Map<String, dynamic> js) => 
		_http.put(
			new Uri(path: "$prefix/$path/$name"),
			body: JSON.encode(js),
			headers: OpenDAF._headers
		).then((http.Response response) {
			switch(response.statusCode){
				case 204:
					return null;
				default:
					return new Future.error("Cannot create $name: ${response.statusCode}");
			}
		});

	Future update(String path, String name, Map<String, dynamic> js) =>
		_http.put(
			new Uri(path: "$prefix/$path/$name"),
			body: JSON.encode(js),
			headers: OpenDAF._headers
		).then((http.Response response) {
			switch(response.statusCode){
				case 204:
					return null;
				default:
					return new Future.error("Cannot update $name: ${response.statusCode}");
			}
		});

	Future delete(String path, String name) =>
		_http.delete("$prefix/$path/$name")
		.then((http.Response response) {
			switch(response.statusCode){
				case 204:
					return null;
				default:
					return new Future.error("Cannot delete $name: ${response.statusCode}");
			}
		});

	Future<http.Response> item(String path, String name, {RequestOptions options}) =>
		_http.get("$prefix/$path/$name", headers: OpenDAF._headers);

	Future<http.Response> list(String path, {RequestOptions options}) =>
		_http.get("$prefix/$path/${OpenDAF._formatQuery(options)}", headers: OpenDAF._headers);

	Future uploadExecutable(String fmName, File executable) =>
		HttpRequest.request(
			new Uri(path: "$prefix/function-modules/$fmName/executable").toString(), 
			method: 'PUT',
			mimeType: "application/octet-stream",
			sendData: executable, 
			requestHeaders: { 'Content-Type': 'application/octet-stream' }
	);

	Future<FileStat> statExecutable(String fmName) =>
		_http.get("$prefix/function-modules/$fmName/executable-stat")
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

	Future downloadDatabase() =>
		_http.get("$prefix/cfgdb/database")
		.then((rsp) => OpenDAF._json(rsp));

	Future uploadDatabase(File database, {bool render: true}) =>
		HttpRequest.request(
			new Uri(path: "$prefix/cfgdb/database").toString() + "?render=${render ? '1' : '0'}",
			method: 'POST',
			mimeType: "application/octet-stream",
			sendData: database,
			requestHeaders: { 'Content-Type': 'application/octet-stream' }
		);

	Future render() => _http.post("$prefix/cfgdb/render");
	Future<bool> get isRenderUpToDate => _http.get("$prefix/cfgdb/render").then((http.Response rsp) => OpenDAF._json(rsp));
}