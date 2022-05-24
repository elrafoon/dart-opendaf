part of opendaf;

class Datatype {
	static const int DT_EMPTY = 0;
	static const int DT_BINARY = 1;
	static const int DT_QUATERNARY = 2;
	static const int DT_INTEGER = 3;
	static const int DT_LONG = 4;
	static const int DT_FLOAT = 5;
	static const int DT_DOUBLE = 6;
	static const int DT_STRING = 7;
	
	static int fromPrefix(String prefix) {
		if(prefix == null)
			return DT_EMPTY;
		
		switch(prefix) {
			case 'b': return DT_BINARY;
			case 'q': return DT_QUATERNARY;
			case 'i': return DT_INTEGER;
			case 'l': return DT_LONG;
			case 'f': return DT_FLOAT;
			case 'd': return DT_DOUBLE;
			case 's': return DT_STRING;
			default:  return null;
		}
	}

	static String fromDescription(String description) {
		if(description == null)
			return null;

		switch(description) {
			case 'binary':      return 'b';
			case 'quaternary':  return 'q';
			case 'integer':     return 'i';
			case 'long':        return 'l';
			case 'float':       return 'f';
			case 'double':      return 'd';
			case 'string':      return 's';
			default:            return null;
		}
	}

	static List<String> get descriptions => new List.from(["(empty)", "binary", "quaternary", "integer", "long", "float", "double", "string"]);

	static String toPrefix(int datatype) {
		switch(datatype) {
			case DT_BINARY:     return 'b';
			case DT_QUATERNARY: return 'q';
			case DT_INTEGER:    return 'i';
			case DT_LONG:       return 'l';
			case DT_FLOAT:      return 'f';
			case DT_DOUBLE:     return 'd';
			case DT_STRING:     return 's';
			default:            return null;
		}
	}

	static String getDescription(int datatype) {
		switch(datatype) {
			case DT_BINARY:     return 'binary';
			case DT_QUATERNARY: return 'quaternary';
			case DT_INTEGER:    return 'integer';
			case DT_LONG:       return 'long';
			case DT_FLOAT:      return 'float';
			case DT_DOUBLE:     return 'double';
			case DT_STRING:     return 'string';
			default:            return null;
		}
	}
}
