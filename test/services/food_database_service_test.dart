import 'package:fitup/features/diet/domain/entities/food.dart';
import 'package:fitup/services/food_database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetchProductByBarcode parses OFF v2 JSON', () async {
    final http.Client client = MockClient((http.Request request) async {
      expect(request.url.path, contains('product'));
      return http.Response(
        '''
{
  "status": 1,
  "product": {
    "product_name": "Test Bar",
    "brands": "TestBrand",
    "nutriments": {
      "energy-kcal_100g": 500,
      "proteins_100g": 10,
      "carbohydrates_100g": 50,
      "fat_100g": 20
    },
    "categories": "snacks",
    "countries_tags": ["en:india"]
  }
}
''',
        200,
      );
    });

    final FoodDatabaseService svc = FoodDatabaseService(
      httpClient: client,
      database: null,
    );

    final Food? food = await svc.fetchProductByBarcode('8901234567890');
    expect(food, isNotNull);
    expect(food!.name, 'Test Bar');
    expect(food.isIndian, isTrue);
    expect(food.source, FoodSource.openFoodFacts);
    expect(food.caloriesPer100g, 500);
  });
}
