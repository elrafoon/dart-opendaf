part of opendaf;

class FileStat {
	int mode;
	int uid, gid;
	int size;
	DateTime atime, mtime, ctime;
	
	FileStat(this.mode, this.uid, this.gid, this.size, this.atime, this.mtime, this.ctime);
	FileStat.fromJson(Map<String, dynamic> js) :
		this(js['mode'], js['uid'], js['gid'], js['size'],
		new DateTime.fromMillisecondsSinceEpoch(1000 * js['atime']),
		new DateTime.fromMillisecondsSinceEpoch(1000 * js['mtime']),
		new DateTime.fromMillisecondsSinceEpoch(1000 * js['ctime']));
}
enum EFunctionModuleState { STOP, INIT, RUN, FAIL }

class FunctionModule {
	final OpenDAF _opendaf;

	/* Runtime */
	String name;
	EFunctionModuleState state;
	bool runtimeLoaded;

	/* Configuration */
	String executable = "";
	String description = "";
	bool enabled = true;
	int termToKill = 2000;
	int queryTimeout = 5000;
	bool respawn = true;
	bool debug = false; 
	Map<String, dynamic> properties = new Map<String, dynamic>();
	bool configurationLoaded;
	FileStat stat;
	FunctionModule _original;

	/* Constructors */
	FunctionModule(this._opendaf, {this.name, this.executable, this.description, this.enabled, this.termToKill, this.queryTimeout, this.respawn, this.debug, this.properties});
	FunctionModule.empty(this._opendaf);
	FunctionModule.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) { updateConfigurationJson(cfg); }
	FunctionModule.fromRuntimeJson(this._opendaf, Map<String, dynamic> runtime) { updateRuntimeJson(runtime); }

	/* Getters */
	FunctionModule get original => _original;
	String get id => this.name;
	String get className => "Function Module";
	String toString() => id;
	bool get isEditable => this.original != null;

	void cfg_stash() {
		this.configurationLoaded = true;
		_original = this.dup();
	} 
	void cfg_revert()         => this.cfg_assign(_original);
	bool cfg_changed()        => !cfg_compare(_original);
	bool cfg_name_changed()   => this.name != this._original?.name;

	void updateRuntimeJson(Map<String, dynamic> runtime){
		if(runtime == null)
			return;

		if(runtime["name"] != null)
			this.name = runtime["name"];
		if(runtime["state"] != null)
			this.state = stateFromString(runtime["state"]);

		this.runtimeLoaded = true;
		_opendaf.ctrl.fm._ls.wsUpdateCounter++;
	}

	void updateConfigurationJson(Map<String, dynamic> cfg){
		if(cfg == null)
			return;

		if(cfg["name"] != null)           this.name         = cfg["name"];
		if(cfg["executable"] != null)     this.executable   = cfg["executable"];
		if(cfg["description"] != null)    this.description  = cfg["description"];
		if(cfg["enabled"] != null)        this.enabled      = cfg["enabled"];
		if(cfg["termToKill"] != null)     this.termToKill   = cfg["termToKill"];
		if(cfg["queryTimeout"] != null)   this.queryTimeout = cfg["queryTimeout"];
		if(cfg["respawn"] != null)        this.respawn      = cfg["respawn"];
		if(cfg["debug"] != null)          this.debug        = cfg["debug"];
		if(cfg["properties"] != null)     this.properties   = cfg["properties"];

		this.configurationLoaded = true;
		this.cfg_stash();
		_opendaf.ctrl.fm._ls.objectsLoadedCounter++;
	}

	FunctionModule dup() => new FunctionModule(_opendaf, 
		name:         name,
		executable:   executable,
		description:  description,
		enabled:      enabled,
		termToKill:   termToKill,
		queryTimeout: queryTimeout,
		respawn:      respawn,
		debug:        debug,
		properties:   new Map<String, dynamic>.from(properties)
	);


	void cfg_assign(FunctionModule other) {
		if(other == null)
			return;
		
		this.name         = other.name;
		this.executable   = other.executable;
		this.description  = other.description;
		this.enabled      = other.enabled;
		this.termToKill   = other.termToKill;
		this.queryTimeout = other.queryTimeout;
		this.respawn      = other.respawn;
		this.debug        = other.debug;
		this.properties   = other.properties;

		this.cfg_stash();
	}

	bool cfg_compare(FunctionModule other){
		if(other == null)
			return false;

		bool propertiesMatch = true;
		this.properties.forEach((key, value) {
			if(value != other.properties[key]){
				propertiesMatch = false;
			}
		});

		return propertiesMatch &&
			this.name         == other.name         &&
			this.executable   == other.executable   &&
			this.description  == other.description  &&
			this.enabled      == other.enabled      &&
			this.termToKill   == other.termToKill   &&
			this.queryTimeout == other.queryTimeout &&
			this.respawn      == other.respawn      &&
			this.debug        == other.debug
		;
	}

	Map<String, dynamic> toCfgJson() {
		Map<String, dynamic> js = {
			"name":         name,
			"description":  description,
			"enabled":      enabled,
			'termToKill':   termToKill,
			'queryTimeout': queryTimeout,
			'respawn':      respawn,
			'debug':        debug,
			'properties':   properties
		};
		if(executable != null)
			js['executable'] = executable;
		return js;
	}

	static EFunctionModuleState stateFromString(String stateName) {
		switch(stateName) {
			case "STOP": return EFunctionModuleState.STOP;
			case "INIT": return EFunctionModuleState.INIT;
			case "RUN": return EFunctionModuleState.RUN;
			case "FAIL": return EFunctionModuleState.FAIL;
			default: return null;
		}
	}

	String get stateName {
		switch(state) {
			case EFunctionModuleState.STOP:   return "STOP";
			case EFunctionModuleState.INIT:   return "INIT";
			case EFunctionModuleState.RUN:    return "RUN";
			case EFunctionModuleState.FAIL:   return "FAIL";
			default:                          return "--";
		}
	}

	bool hasMatch(RegExp regex) =>
		regex.hasMatch(name ?? "")
		|| regex.hasMatch(executable ?? "")
		|| regex.hasMatch(description ?? "")
		|| regex.hasMatch(stateName ?? "")
	;

	dynamic operator[](String key) {
		switch(key){
			case "name": 		return this.name;
			case "state": 		return this.state;
			case "description":	return this.description;
			case "enabled": 	return this.enabled;
			case "termToKill": 	return this.termToKill;
			case "queryTimeout":return this.queryTimeout;
			case "respawn": 	return this.respawn;
			case "debug": 		return this.debug;
			case "executable": 	return this.executable;
			default:			return this.properties[key];
		}
	}
}
