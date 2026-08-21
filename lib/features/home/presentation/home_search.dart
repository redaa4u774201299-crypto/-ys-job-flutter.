class HomeSearchCriteria {
  const HomeSearchCriteria({required this.query, required this.city});

  final String query;
  final String city;

  String get normalizedQuery => query.trim();
  String get normalizedCity => city.trim();

  bool get isEmpty => normalizedQuery.isEmpty && normalizedCity.isEmpty;

  String? get jobsPath {
    if (isEmpty) return null;
    return Uri(
      path: '/jobs',
      queryParameters: {
        if (normalizedQuery.isNotEmpty) 'q': normalizedQuery,
        if (normalizedCity.isNotEmpty) 'city': normalizedCity,
      },
    ).toString();
  }
}
