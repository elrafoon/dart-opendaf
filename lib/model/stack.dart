part of opendaf;

class StackModule {
	String name;
	int id;
	bool _enabled;
	
	CommunicationObject parent;
	
	bool get enabled => _enabled;
	void set enabled(bool en) {
		if (en)
			parent?.stackUmask |= id;
		else
			parent?.stackUmask &= ~id;
		_enabled = en;
	}
	
	StackModule(this.name, this.id, [this._enabled = false]);
}

class Stack {
	final OpenDAF _opendaf;

	Stack _original;

	String name;
	StackDescription stackDescription;
	Map<String, dynamic> description = new Map<String, dynamic>();
	Map<String, String> defaults = new Map<String, String>();
	Map<String, dynamic> defaultPreload = new Map<String, dynamic>();
	
	Stack(this._opendaf, {this.name, this.description, this.defaults});
	Stack.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) { updateConfigurationJson(cfg); }
	Stack dup() => new Stack(_opendaf,
		name:         name,
		description:  new Map<String, dynamic>.from(description),
		defaults:     new Map<String, dynamic>.from(defaults)
	);

	Stack get original => _original;
	String get id => this.name;
	String get className => "Stack";
	String toString() => id;

	Map<String, dynamic> get parameters => description["parameters"];
	Map<String, dynamic> get measurement => description["measurement"];
	Map<String, dynamic> get command => description["command"];
	bool get measurementEnabled => measurement != null && measurement["enabled"] == true;
	bool get commandEnabled => command != null && command["enabled"] == true;

	void updateConfigurationJson(Map<String, dynamic> cfg){
		if(cfg == null)
			return;

		if(cfg["name"] != null)               this.name               = cfg["name"];
		if(cfg["description"] != null)        this.description        = cfg["description"];
		if(cfg["description"] != null)        this.stackDescription   = new StackDescription.fromJson(cfg["description"]);
		if(cfg["defaults"] != null)           this.defaults           = cfg["defaults"];

		if(parameters != null) {
			parameters.forEach((String name, Map<String, dynamic> value) {
				defaultPreload[name] = value["default"];
			});
		}
	}

	static Map<String, String> parseDefaults(String rawDefaults) {
		Map<String, String> m = new Map<String, String>();
		rawDefaults.split("\n").where((line) => line.isNotEmpty).forEach((String line) {
			List<String> p = line.split("=");
			m[p[0]] = p[1];
		});
		return m;
	}
}



class StackDescription {
	String title;
	Map<String, StackParameter> parameters = new Map<String, StackParameter>();
	StackCODesc measurement;
	StackCODesc command;

	StackDescription.fromJson(Map<String, dynamic> js) {
		this.title		= js["title"];
		if(js["parameters"] != null){
			js["parameters"].forEach((String name, Map<String, dynamic> value) {
				parameters[name] = new StackParameter.fromJson(name, value);
			});
		}

		if(js["measurement"] != null)
			this.measurement = new StackCODesc.fromJson(js["measurement"]);
		if(js["command"] != null)
			this.command = new StackCODesc.fromJson(js["command"]);
	}

	List<String> get parameterNames => parameters.keys;
}

class StackParameter {
	static const String TYPE_REGEX = "regex",
					TYPE_ENUM = "enum",
					TYPE_STRING = "string",
					TYPE_BOOLEAN = "boolean",
					TYPE_INT = "int",
					TYPE_INTEGER = "integer",
					TYPE_FLOAT = "float",
					TYPE_TTY = "tty",
					TYPE_HOSTNAME = "hostname",
					TYPE_LIST_OF_INET_ADDR = "list_of_inet_addr";


	String key;	// DEBUG | DUMP | ...

	// @see StackParameter.TYPE_*
	String type;
	String title;

	List<dynamic> enum_ = new List<dynamic>();
	dynamic default_;
	List<dynamic> range = new List<dynamic>();
	String regex;
	int min_length;
	String connectionClass;

	StackParameter.fromJson(String key, Map<String, dynamic> js){
		this.key			= key;
		this.title			= js["title"];
		this.type			= js["type"];

		if(js["enum"] != null)
			this.enum_		= js["enum"];
		this.default_		= js["default"];
		if(js["range"] != null)
			this.range		= js["range"];
		this.regex			= js["regex"];
		this.min_length		= js["min_length"];
		this.connectionClass= js["connection-class"];
	}


}

class StackCODesc {
	static const String TYPE_REGEX = "regex",
						TYPE_REGEX_LITERAL = "regex-literal",
						TYPE_ENUM = "enum",
						TYPE_STRING = "string",
						TYPE_JAVASCRIPT = "javascript",
						TYPE_ASN1 = "ASN.1";

	bool enabled;

	// @see StackCODesc.TYPE_*
	String type;

	String regex;
	List<String> doc = new List<String>();
	List<String> doc_html = new List<String>();
	List<String> examples = new List<String>();
	List<String> examples_html = new List<String>();
	List<dynamic> enum_ = new List<dynamic>();

	StackCODesc.fromJson(Map<String, dynamic> js){
		this.enabled		= js["enabled"];

		this.type			= js["type"];
		this.regex			= js["regex"];
		if(js["doc"] != null)
			this.doc			= new List<String>.from(js["doc"]);
		if(js["doc_html"] != null)
			this.doc_html		= new List<String>.from(js["doc_html"]);
		if(js["examples"] != null)
			this.examples		= new List<String>.from(js["examples"]);
		if(js["examples_html"] != null)
			this.examples_html	= new List<String>.from(js["examples_html"]);
		if(js["enum"] != null)
			this.enum_			= new List<dynamic>.from(js["enum"]);
	}

	bool get isDocInMarkdown => (doc.isNotEmpty && doc?.first?.toLowerCase()?.startsWith("# markdown"));
	bool get isExamplesInMarkdown => (examples.isNotEmpty && examples?.first?.toLowerCase()?.startsWith("# markdown"));
	bool get hasDocumentation => doc?.isNotEmpty || doc_html?.isNotEmpty;
	bool get hasExamples => examples?.isNotEmpty || examples_html?.isNotEmpty;
}