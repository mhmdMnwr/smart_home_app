class SensorHistoryItem {
  const SensorHistoryItem({required this.value, required this.createdAt});

  final double value;
  final DateTime createdAt;

  factory SensorHistoryItem.fromApi(Map<String, dynamic> json) {
    final rawValue = json['value'];
    final parsedValue = rawValue is num
        ? rawValue.toDouble()
        : double.tryParse(rawValue?.toString() ?? '') ?? 0;

    final rawCreatedAt = json['createdAt']?.toString();
    final parsedCreatedAt = rawCreatedAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.tryParse(rawCreatedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);

    return SensorHistoryItem(
      value: parsedValue,
      createdAt: parsedCreatedAt,
    );
  }
}

class SensorHistoryPage {
  const SensorHistoryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<SensorHistoryItem> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory SensorHistoryPage.fromApi(Map<String, dynamic> json) {
    final rawItems = json['data'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(SensorHistoryItem.fromApi)
              .toList(growable: false)
        : const <SensorHistoryItem>[];

    int parseInt(dynamic value, int fallback) {
      if (value is int) {
        return value;
      }
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return SensorHistoryPage(
      items: items,
      total: parseInt(json['total'], 0),
      page: parseInt(json['page'], 1),
      limit: parseInt(json['limit'], 10),
      totalPages: parseInt(json['totalPages'], 1),
    );
  }
}
