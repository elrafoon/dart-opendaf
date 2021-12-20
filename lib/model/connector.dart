part of opendaf;

class Connector extends StackInstantiation {
  final OpenDAF _opendaf;

  Connector(this._opendaf, { String name, String stackName, Map<String, String> vars, String wdtMeasurementName, Map<String, dynamic> properties }) :
    super(_opendaf, name: name, stackName: stackName, vars: vars, wdtMeasurementName: wdtMeasurementName, properties: properties != null ? new Map<String, dynamic>.from(properties) : new Map<String, dynamic>());

  Connector.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) : super(_opendaf) { super.updateConfigurationJson(cfg); }
  Connector.empty(this._opendaf) : super(_opendaf,
    vars: new Map<String, String>(),
    properties: new Map<String, String>()
  );

	void updateConfigurationJson(Map<String, dynamic> cfg){
		super.updateConfigurationJson(cfg);
		_opendaf.ctrl.connector._ls.objectsLoadedCounter++;
	}

  /* Getters */
  String get className => "Connector";
}