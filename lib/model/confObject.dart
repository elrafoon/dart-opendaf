part of opendaf;

abstract class ConfObject {
	Map<String, dynamic> rawModel = new Map<String, dynamic>();
	Descriptor descriptor;

	ConfObject(){}
	ConfObject.fromJson(Map<String, dynamic> js){
		if(js == null)
			return;
		if (js != null)	this.rawModel = new Map<String, dynamic>.from(js);

		this.descriptor	= new Descriptor.fromJson(js);
	}

	Map<String, dynamic> toCfgJson() {
		return new Map<String, dynamic>.from(rawModel);
	}

	void attachRuntime(OpenDAF _opendaf);

	dynamic get id;
	String get identification;
	@override toString() => identification;

	static emptyToNull(String x) => (x is String && x.isEmpty) ? null : x;
	static toJsIfNotNull(Map<String, dynamic> js, String key, dynamic value){
		if(value != null)
			js[key] = value;
	}

	static toJsIfNotEmpty(Map<String, dynamic> js, String key, dynamic value){
		if(value != null && ConfObject.emptyToNull(value) != null)
			js[key] = value;
	}
}