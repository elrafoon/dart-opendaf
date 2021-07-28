part of opendaf;

class Provider extends StackInstantiation {
  final OpenDAF _opendaf;

  Provider(this._opendaf, { String name, String stackName, Map<String, String> vars, String wdtMeasurementName, Map<String, dynamic> properties }) :
    super(_opendaf, name: name, stackName: stackName, vars: vars, wdtMeasurementName: wdtMeasurementName, properties: properties);

  Provider.fromCfgJson(this._opendaf, Map<String, dynamic> cfg) : super(_opendaf) { super.updateConfigurationJson(cfg); }

  /* Getters */
  String get className => "Provider";
}