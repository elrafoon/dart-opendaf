part of opendaf;

class Provider extends StackInstantiation {
  final OpenDAF _opendaf;

  Provider(this._opendaf, { String name, String stackName, Map<String, String> vars, String wdtMeasurementName, Map<String, dynamic> properties }) :
    super(_opendaf, name: name, stackName: stackName, vars: vars, wdtMeasurementName: wdtMeasurementName, properties: properties != null ? new Map<String, dynamic>.from(properties) : new Map<String, dynamic>());

  Provider.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) : super(_opendaf) { 
		super.updateConfigurationJson(cfg); 
		_opendaf.ctrl.provider._ls.objectsLoadedCounter++;
	}
  Provider.empty(this._opendaf) : super(_opendaf,
      vars: new Map<String, String>(),
      properties: new Map<String, String>()
    );

  /* Getters */
  String get className => "Provider";
}