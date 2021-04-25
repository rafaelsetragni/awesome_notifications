class StringUtils {
  static RegExp _emptyRegex = RegExp(r'^\s*$');
  static bool isNullOrEmpty(String? value,
      {bool considerWhiteSpaceAsEmpty = false}) {
    if (considerWhiteSpaceAsEmpty)
      return value == null || _emptyRegex.hasMatch(value);
    return value?.isEmpty ?? true;
  }
}
