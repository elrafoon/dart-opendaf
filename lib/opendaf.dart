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
part 'model/descriptor.dart';

part 'controller/alarm.dart';
part 'controller/measurement.dart';
part 'controller/command.dart';
part 'controller/provider.dart';
part 'controller/connector.dart';
part 'controller/connectorStack.dart';
part 'controller/providerStack.dart';
part 'controller/function_module.dart';
part 'controller/controller.dart';

part 'api/api.dart';
part 'api/archive.dart';
part 'api/dafman.dart';
part 'api/websocket.dart';


@Injectable()
class OpenDAF {
	static Map<String, String> _headers = { "Content-Type" : "application/json; charset=UTF-8" };
	static const int MAX_NAMES_IN_REQUEST = 500;
	static const int RCFG_OPENDAF = 1, RCFG_ARCHIVE = 2, RCFG_AUTO = 4;

	final http.Client _http;


	OpendafController ctrl;
	OpendafRoot root;

	OpendafApi api;
	OpendafDafman dafman;
	OpendafArchive archive;
	OpendafWS ws;
	bool DEFAULT_VIA_WS = false;

	OpenDAF(this._http) {
		// Configuration
		root	= new OpendafRoot(this);
		ctrl	= new OpendafController(this, this._http);

		// Communication
		api		= new OpendafApi(this, this._http);
		dafman	= new OpendafDafman(this, this._http);
		archive	= new OpendafArchive(this, this._http);
		ws		= new OpendafWS(this, this._http);
	}

	void log(String message, [String origin]){
		print("[OpenDAF${origin == null ? '' : '.' + origin}]: $message");
	}

	void useWebSocket(){
		DEFAULT_VIA_WS = true;

		ws.reconnect();
	}

	/* ----- REST API Function ----- */
	Future<List<http.Response>> item(String prefix, String name, {RequestOptions options}) =>
		Future.wait([
			options.fetchConfiguration	? this.dafman.item(prefix, name, options: options) : new Future.value(),
			options.fetchRuntime		? this.api.item(prefix, name, options: options) : new Future.value()
		]);

	Future<List<http.Response>> list(String prefix, {RequestOptions options}) {
		return Future.wait([
			options.fetchConfiguration	? this.dafman.list(prefix, options: options) : new Future.value(),
			options.fetchRuntime		? this.api.list(prefix, options: options) : new Future.value()
		]);
	}

	Future reconfigure([int mask = RCFG_AUTO]) {
		print("Reconfiguring with mask $mask");
		if(mask != RCFG_AUTO) {
			Future f = ((mask & RCFG_OPENDAF) != 0) ? api.reconfigure() : new Future.value();
			return ((mask & RCFG_ARCHIVE) != 0) ? f.then((_) => archive.reconfigure()) : f;
		}
		else {
			return Future.wait([
				pid.catchError((e) => null).then((_) => (_ == null) ? null : api.reconfigure()),
				archivePid.catchError((e) => null).then((_) => (_ == null) ? null : archive.reconfigure())
			]);
		}
	}

	Future<int> get pid => api.pid;
	Future<int> get archivePid => archive.pid;

	Future downloadDatabase() => dafman.downloadDatabase();
	Future uploadDatabase(File database, {bool render: true}) => dafman.uploadDatabase(database, render: render);

	Future render() => dafman.render();
	Future<bool> get isRenderUpToDate => dafman.isRenderUpToDate;

	/* ----- HELPERS ----- */
	static dynamic _json(http.Response rsp) => rsp != null ? JSON.decode(new Utf8Decoder().convert(rsp.bodyBytes)) : {};

	static String _formatQuery(RequestOptions options){
		String optNames, optFields;

		if(options.names != null && options.names.length <= MAX_NAMES_IN_REQUEST)
			optNames = "names=" + options.names.join(",");

		if(options.fields != null)
			optFields = "fields=" + options.fields.join(",");

		final Iterable<String> opts = [optNames, optFields].where((_) => _ != null);
		return (opts.length > 0) ? ("?" + opts.join("&")) : "";
	}

	static String _fmtQueryTime(dynamic t) {
		if(t is DateTime)
			return "${t.millisecondsSinceEpoch ~/ 1000}";
		else if(t is num && t <= 0)
			return "${t.toStringAsFixed(6)}";
		else
			throw new ArgumentError();
	}

	static String _fmtQueryTimeRange(dynamic from, dynamic to) => "/${_fmtQueryTime(from)}/${_fmtQueryTime(to)}";

	static int _parsePid(String sPid) {
		try {
			return int.parse(sPid);
		} catch(e) {
			return null;
		}
	}
}
