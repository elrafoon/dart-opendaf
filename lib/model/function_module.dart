part of opendaf;

enum EFunctionModuleState { STOP, INIT, RUN, FAIL }

class FunctionModule {
  final String name;
  EFunctionModuleState state;
  
  FunctionModule(this.name, this.state);
  FunctionModule.fromJson(Map<String, dynamic> json) : this(json["name"], stateFromString(json["state"]));
  
  static EFunctionModuleState stateFromString(String stateName) {
    switch(stateName) {
      case "STOP": return EFunctionModuleState.STOP;
      case "INIT": return EFunctionModuleState.INIT;
      case "RUN": return EFunctionModuleState.RUN;
      case "FAIL": return EFunctionModuleState.FAIL;
      default: return null;
    }
  }
}
