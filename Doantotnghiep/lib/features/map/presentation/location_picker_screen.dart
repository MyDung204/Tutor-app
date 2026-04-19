import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/map/data/map_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    // 1. Try to get saved location from User profile if available?
    // User object in authRepository might have it if we synced it. 
    // Usually authRepository.currentUser is minimal.
    // We'll rely on GPS first.
    
    // Check GPS
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
       _showError('Vui lòng bật dịch vụ vị trí (GPS)');
       setState(() => _isLoading = false);
       return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Quyền vị trí bị từ chối');
        setState(() => _isLoading = false);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showError('Quyền vị trí bị từ chối vĩnh viễn');
      setState(() => _isLoading = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      _showError('Không thể lấy vị trí: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveLocation() async {
    if (_currentPosition == null) return;
    setState(() => _isSaving = true);

    try {
      await ref.read(mapRepositoryProvider).updateLocation(
        _currentPosition!.latitude, 
        _currentPosition!.longitude
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật vị trí thành công!'))
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Lỗi lưu vị trí: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật vị trí'),
        actions: [
          TextButton(
            onPressed: (_currentPosition != null && !_isSaving) ? _saveLocation : null,
            child: _isSaving 
               ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
               : const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _currentPosition == null 
            ? const Center(child: Text('Không xác định được vị trí'))
            : Stack(
                children: [
                   FlutterMap(
                     mapController: _mapController,
                     options: MapOptions(
                       initialCenter: _currentPosition!,
                       initialZoom: 15.0,
                       onPositionChanged: (position, hasGesture) {
                          if (hasGesture) {
                            setState(() {
                              _currentPosition = position.center;
                            });
                          }
                       },
                     ),
                     children: [
                       TileLayer(
                         urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                         userAgentPackageName: 'com.antigravity.midon',
                       ),
                       // Fixed center marker in Stack instead of MarkerLayer for smoother dragging
                     ],
                   ),
                   const Center(
                     child: Icon(Icons.location_on, size: 50, color: Colors.red),
                   ),
                   Positioned(
                     bottom: 40,
                     left: 20,
                     right: 20,
                     child: Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                       child: const Text(
                         'Di chuyển bản đồ để ghim đúng vị trí của bạn.',
                         textAlign: TextAlign.center,
                       ),
                     ),
                   )
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
