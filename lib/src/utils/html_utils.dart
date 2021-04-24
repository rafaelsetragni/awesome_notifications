class HtmlUtils {
  static String? removeAllHtmlTags(String? htmlText) {
    if (htmlText == null) return null;
    RegExp exp =
        RegExp(r"<[a-zA-Z\/][^>]*>", multiLine: true, caseSensitive: false);

    return htmlText.replaceAll(exp, '');
  }
}
