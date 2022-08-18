part of opendaf;

class AlarmGroup {
	final OpenDAF _opendaf;

	AlarmGroup _original;
	AlarmGroup get original => _original;

	// Runtime 
	bool runtimeLoaded;

	// Configuration
	String name;
	String parentName;
	String description;

	Map<String, dynamic> properties = new Map<String, dynamic>();
	bool configurationLoaded;


	AlarmGroup(this._opendaf, {this.name, this.parentName, this.description, this.properties = const {}});

	AlarmGroup.empty(this._opendaf);

	AlarmGroup.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) {
		updateConfigurationJson(cfg);
	}

	void updateConfigurationJson(Map<String, dynamic> cfg){
		if(cfg == null)
			return;

		if(cfg["name"] != null)
			this.name = cfg["name"];
		if(cfg["parentName"] != null)
			this.parentName = cfg["parentName"];
		if(cfg["description"] != null)
			this.description = cfg["description"];

		if(cfg["properties"] != null)
			this.properties = cfg["properties"];

		this.configurationLoaded = true;
		this.cfg_stash();
		_opendaf.ctrl.alarmGroup._ls.objectsLoadedCounter++;
	}

	AlarmGroup dup() => new AlarmGroup(_opendaf,
		name: name,
		parentName: parentName,
		description: description,
		properties: new Map<String, dynamic>.from(properties)
	);


	void cfg_assign(AlarmGroup other) {
		if(other == null)
			return;
		
		this.name         = other.name;
		this.parentName   = other.parentName;
		this.description  = other.description;
		this.properties   = new Map<String, dynamic>.from(other.properties);

		this.cfg_stash();
	}

	bool cfg_compare(AlarmGroup other){
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
			this.parentName   == other.parentName   &&
			this.description  == other.description  ;
	}

	void cfg_stash() {
		this.configurationLoaded = true;
		_original = this.dup();
	}
	void cfg_revert() => this.cfg_assign(_original);
	bool cfg_changed() => !cfg_compare(_original);
	bool cfg_name_changed() => this.name != this._original?.name;

	Map<String, dynamic> toCfgJson() => {
		"name": name,
		"parentName": parentName,
		"description": description,
		"properties": properties
	};



	bool get isEditable => this.name != "root" && this.original != null;

	String get id => this.name;
	String toString() => id;

	bool hasMatch(RegExp regex) => 
		regex.hasMatch(name ?? "")
		|| regex.hasMatch(parentName ?? "")
		|| regex.hasMatch(description ?? "")
	;

	dynamic operator[](String key) {
		switch(key){
			case "name": 		return this.name;
			case "parentName":	return this.parentName;
			case "description":	return this.description;
			default:			return this.properties[key];
		}
	}
}