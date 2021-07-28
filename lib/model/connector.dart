part of opendaf;

class Connector extends StackInstantiation {
  final OpenDAF _opendaf;

  Connector(this._opendaf, { String name, String stackName, Map<String, String> vars, String wdtMeasurementName, Map<String, dynamic> properties }) :
    super(_opendaf, name: name, stackName: stackName, vars: vars, wdtMeasurementName: wdtMeasurementName, properties: properties);

  Connector.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) : super(_opendaf) { super.updateConfigurationJson(cfg); }
  
  /* Getters */
  String get className => "Connector";
}