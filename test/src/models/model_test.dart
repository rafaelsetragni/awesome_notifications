import 'package:awesome_notifications/src/models/model.dart';
import 'package:flutter_test/flutter_test.dart';

class TestModel extends Model {
  int id;
  String name;

  TestModel({required this.id, required this.name});

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  TestModel? fromMap(Map<String, dynamic> mapData) {
    if (mapData.isEmpty) return null;

    return TestModel(
      id: mapData['id'],
      name: mapData['name'],
    );
  }

  @override
  void validate() {
    if (id <= 0) throw ArgumentError('Invalid id');
    if (name.isEmpty) throw ArgumentError('Invalid name');
  }
}

void main() {
  group('Model tests', () {
    test('toMap method', () {
      TestModel model = TestModel(id: 1, name: 'Test');
      Map<String, dynamic> expectedMap = {'id': 1, 'name': 'Test'};

      expect(model.toMap(), expectedMap);
    });

    test('fromMap method', () {
      TestModel model = TestModel(id: 1, name: 'Test');
      Map<String, dynamic> mapData = {'id': 1, 'name': 'Test'};

      TestModel? fromMapModel = model.fromMap(mapData);

      expect(fromMapModel?.id, model.id);
      expect(fromMapModel?.name, model.name);
    });

    test('toString method', () {
      TestModel model = TestModel(id: 1, name: 'Test');
      String expectedString = "{\n  \"id\": 1,\n  \"name\": \"Test\"\n}";

      expect(model.toString(), expectedString);
    });

    test('validate method', () {
      TestModel validModel = TestModel(id: 1, name: 'Test');
      TestModel invalidModel1 = TestModel(id: 0, name: 'Test');
      TestModel invalidModel2 = TestModel(id: 1, name: '');

      expect(validModel.validate, returnsNormally);
      expect(() => invalidModel1.validate(), throwsA(isA<ArgumentError>()));
      expect(() => invalidModel2.validate(), throwsA(isA<ArgumentError>()));
    });
  });
}