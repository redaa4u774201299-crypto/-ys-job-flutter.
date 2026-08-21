class HomeSearchCriteria {
  const HomeSearchCriteria({required this.query});

  final String query;

  String get normalizedQuery => query.trim();

  bool get isEmpty => normalizedQuery.isEmpty;

  String? get jobsPath {
    if (isEmpty) return null;
    return Uri(
      path: '/jobs',
      queryParameters: {if (normalizedQuery.isNotEmpty) 'q': normalizedQuery},
    ).toString();
  }
}
