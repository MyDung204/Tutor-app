import 'package:dio/dio.dart';
import 'package:doantotnghiep/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository(ref.watch(apiClientProvider));
});

class MapRepository {
  final ApiClient _client;

  MapRepository(this._client);

  Future<bool> updateLocation(double latitude, double longitude, {bool? isIncognito}) async {
    try {
      final Map<String, dynamic> data = {
        'latitude': latitude,
        'longitude': longitude,
      };
      if (isIncognito != null) {
        data['is_incognito'] = isIncognito;
      }
      
      await _client.post('/map/update-location', data: data);
      return true;
    } catch (e) {
      print('Error updating location: $e');
      return false;
    }
  }

  Future<List<MapUser>> getNearbyUsers({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    String? role,
    double? minPrice,
    double? maxPrice,
    String? subject,
  }) async {
    try {
      final query = {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        if (role != null) 'role': role,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (subject != null) 'subject': subject,
      };

      final response = await _client.get('/map/nearby', queryParameters: query);

      if (response is List) {
        return response.map((e) => MapUser.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching nearby users: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getRoute(LatLng start, LatLng end) async {
    try {
      final dio = Dio();
      final url = 'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      
      final response = await dio.get(url);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
           final route = data['routes'][0];
           final geometry = route['geometry'];
           final distance = route['distance'] as double; // meters
           
           List<LatLng> points = [];
           if (geometry['coordinates'] != null) {
              points = (geometry['coordinates'] as List).map((e) {
                return LatLng(e[1].toDouble(), e[0].toDouble());
              }).toList();
           }
           
           return {
             'points': points,
             'distance': distance / 1000.0 // km
           };
        }
      }
      return {'points': <LatLng>[], 'distance': 0.0};
    } catch (e) {
      print('Error fetching route: $e');
      return {'points': <LatLng>[], 'distance': 0.0};
    }
  }
}

class MapUser {
  final String id;
  final String name;
  final String role;
  final LatLng position;
  final double distance; // km
  final String avatarUrl;
  final bool isIncognito;

  MapUser({
    required this.id,
    required this.name,
    required this.role,
    required this.position,
    required this.distance,
    required this.avatarUrl,
    this.isIncognito = false,
  });

  factory MapUser.fromJson(Map<String, dynamic> json) {
    return MapUser(
      id: json['id'].toString(),
      name: json['name'],
      role: json['role'],
      position: LatLng(
        double.parse(json['latitude'].toString()), 
        double.parse(json['longitude'].toString())
      ),
      distance: double.parse(json['distance'].toString()),
      avatarUrl: json['avatar_url'] ?? '',
      isIncognito: json['is_incognito'] == 1 || json['is_incognito'] == true,
    );
  }
}
