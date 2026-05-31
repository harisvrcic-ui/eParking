/// Pretraga bez obzira na č, ć, š, ž, đ (npr. "vijecnica" → "Vijećnica").
class SearchText {
  static String normalize(String value) {
    var s = value.toLowerCase().trim();
    const map = {
      'č': 'c',
      'ć': 'c',
      'š': 's',
      'ž': 'z',
      'đ': 'd',
      'ä': 'a',
      'ö': 'o',
      'ü': 'u',
    };
    for (final entry in map.entries) {
      s = s.replaceAll(entry.key, entry.value);
    }
    return s;
  }

  static bool contains(String haystack, String needle) {
    if (needle.isEmpty) return true;
    return normalize(haystack).contains(normalize(needle));
  }
}
