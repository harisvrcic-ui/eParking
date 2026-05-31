import '../core/api_client.dart';
import '../models/lookup_item.dart';

class LookupService {
  final ApiClient _api = ApiClient();

  Future<List<LookupItem>> getBrands() async {
    final data = await _api.getList('/Lookups/brands');
    return data
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LookupItem>> getColors() async {
    final data = await _api.getList('/Lookups/colors');
    return data
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LookupItem>> getCities() async {
    final data = await _api.getList('/Lookups/cities');
    return data
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LookupItem>> getGenders() async {
    final data = await _api.getList('/Lookups/genders');
    return data
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
