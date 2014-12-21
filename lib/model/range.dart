part of opendaf;

class Range {
  var lo, hi;
  
  Range(this.lo, this.hi);
  Range.fromJson(List<dynamic> json) :
    this(Value.parseValueWithPrefix(json[0]), Value.parseValueWithPrefix(json[1]));
}