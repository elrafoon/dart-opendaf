part of opendaf;

class OpenDAFDispatcher {
	static String prefix = "/opendaf/dispatcher/";
	final OpenDAF _opendaf;
	final http.Client _http;

	OpenDAFDispatcher(this._opendaf, this._http);

	Future reconfigure() =>
		_http.post("$prefix/management/reconfigure");

	Future<int> get pid =>
		_http.get("$prefix/management/pid")
		.then((http.Response rsp) => OpenDAF._parsePid(rsp.body));
}