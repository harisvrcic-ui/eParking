import '../core/api_client.dart';
import '../models/car.dart';

class CarService {
  final ApiClient _api = ApiClient();

  Future<List<Car>> getMyCars() async {
    final data = await _api.getList('/Cars');
    return data
        .map((e) => Car.fromJson(e as Map<String, dynamic>))
        .where((c) => c.isActive)
        .toList();
  }

  Future<Car> getCar(int id) async {
    final data = await _api.get('/Cars/$id');
    return Car.fromJson(data as Map<String, dynamic>);
  }

  Future<Car> createCar({
    required int userId,
    required int brandId,
    required int colorId,
    required String model,
    required String licensePlate,
  }) async {
    final data = await _api.post('/Cars', {
      'userId': userId,
      'brandId': brandId,
      'colorId': colorId,
      'model': model,
      'licensePlate': licensePlate,
      'yearOfManufacture': DateTime.now().year,
      'isActive': true,
    });
    return Car.fromJson(data as Map<String, dynamic>);
  }

  Future<Car> updateCar({
    required int id,
    required int userId,
    required int brandId,
    required int colorId,
    required String model,
    required String licensePlate,
    required bool isActive,
  }) async {
    final data = await _api.put('/Cars/$id', {
      'id': id,
      'userId': userId,
      'brandId': brandId,
      'colorId': colorId,
      'model': model,
      'licensePlate': licensePlate,
      'isActive': isActive,
    });
    return Car.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteCar(int id) async {
    await _api.delete('/Cars/$id');
  }
}
