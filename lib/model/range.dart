part of opendaf;

class Range {
  var lo, hi;
  
  Range(this.lo, this.hi);
  Range.fromJson(List<dynamic> json) :
    this((json == null) ? null : Value.parseValueWithPrefix(json[0]), (json == null) ? null : Value.parseValueWithPrefix(json[1]));
}