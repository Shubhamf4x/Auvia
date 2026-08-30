import 'package:flutter_test/flutter_test.dart';
import 'package:ai_life_utility/data/models.dart';

void main() {
  test('LifeItem serializes and restores', () {
    final item = LifeItem(
      id: 't1',
      type: ItemType.document,
      title: 'Electricity Bill',
      category: 'Bills',
      content: 'Amount due 2,340.00',
      createdAt: DateTime(2026, 8, 22),
    );
    final json = item.toJson();
    final restored = LifeItem.fromJson(json);
    expect(restored.title, 'Electricity Bill');
    expect(restored.type, ItemType.document);
    expect(restored.matches('electricity'), isTrue);
  });

  test('malformed JSON does not crash decoding helpers', () {
    final restored = LifeItem.fromJson({
      'id': 'x',
      'type': 0,
      'title': 'T',
      'category': 'C',
      'content': 'B',
      'createdAt': 0,
    });
    expect(restored.important, isFalse);
    expect(restored.keyPoints, isEmpty);
  });
}
