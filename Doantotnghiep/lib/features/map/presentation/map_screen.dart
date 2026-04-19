import 'package:cached_network_image/cached_network_image.dart';
import 'package:doantotnghiep/features/auth/data/auth_repository.dart';
import 'package:doantotnghiep/features/map/data/map_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:doantotnghiep/features/tutor/data/tutor_repository.dart';
import 'package:go_router/go_router.dart';

class MapScreen extends ConsumerStatefulWidget {
  final LatLng? targetLocation;
  const MapScreen({super.key, this.targetLocation});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  List<MapUser> _nearbyUsers = [];
  bool _isLoading = true;
  double _radius = 10.0; // km
  List<LatLng> _routePoints = [];
  double? _routeDistance;

  // Features State
  double? _filterMinPrice;
  double? _filterMaxPrice;
  String? _filterSubject;

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quyền vị trí bị từ chối')));
           setState(() => _isLoading = false);
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quyền vị trí bị từ chối vĩnh viễn')));
         setState(() => _isLoading = false);
       }
       return;
    }

    // Get position
    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentPosition = latLng;
      });

      // Update to backend
      await ref.read(mapRepositoryProvider).updateLocation(
        position.latitude, 
        position.longitude,
        // isIncognito removed.
      );
      
      // Fetch nearby
      await _fetchNearbyUsers(latLng);

      // Move map logic
      if (widget.targetLocation != null) {
          // Priority to target
          if (_nearbyUsers.isEmpty && _routePoints.isEmpty) { 
             _mapController.move(widget.targetLocation!, 15);
          }
      } else {
          // Priority to Me
          if (_nearbyUsers.isEmpty && _routePoints.isEmpty) { 
             _mapController.move(latLng, 14);
          }
      }

    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lấy vị trí: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNearbyUsers(LatLng center) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    // If I am Tutor -> find Students (or Tutors? Usually Students to find Tutors)
    String? targetRole;
    if (user?.role == 'student') targetRole = 'tutor';
    if (user?.role == 'tutor') targetRole = 'student';

    final users = await ref.read(mapRepositoryProvider).getNearbyUsers(
      latitude: center.latitude,
      longitude: center.longitude,
      radius: _radius,
      role: targetRole,
      minPrice: _filterMinPrice,
      maxPrice: _filterMaxPrice,
      subject: _filterSubject,
    );

    setState(() {
      _nearbyUsers = users;
    });
  }

  Future<void> _fetchRoute(LatLng destination) async {
    if (_currentPosition == null) return;
    Navigator.pop(context); 
    setState(() => _isLoading = true);
    
    final result = await ref.read(mapRepositoryProvider).getRoute(_currentPosition!, destination);
    
    setState(() {
      _routePoints = result['points'] as List<LatLng>;
      _routeDistance = result['distance'] as double?;
      _isLoading = false;
    });
    
    if (_routePoints.isNotEmpty) {
       final bounds = LatLngBounds.fromPoints(_routePoints);
       _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
       
       if (mounted) {
         showModalBottomSheet(
           context: context,
           builder: (context) => Container(
             padding: const EdgeInsets.all(20),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text('Thông tin đường đi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                     IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                   ],
                 ),
                 const SizedBox(height: 10),
                 ListTile(
                   leading: const Icon(Icons.directions_car, color: Colors.blue, size: 30),
                   title: Text('Khoảng cách lái xe: ${_routeDistance?.toStringAsFixed(1)} km'),
                   subtitle: const Text('Dữ liệu lấy từ OpenStreetMap'),
                 ),
               ],
             ),
           ),
         );
       }
    } else {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy đường đi')));
      }
    }
  }
  
  void _showDistanceInfo(MapUser user) {
     showModalBottomSheet(
       context: context,
       builder: (context) => Container(
         padding: const EdgeInsets.all(16),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             ListTile(
               leading: CircleAvatar(
                 backgroundImage: (user.avatarUrl.isNotEmpty && !user.isIncognito)
                   ? CachedNetworkImageProvider(user.avatarUrl)
                   : null,
                 child: (user.avatarUrl.isEmpty || user.isIncognito) ? const Icon(Icons.person) : null,
               ),
               title: Text(user.isIncognito ? 'Người dùng ẩn danh' : user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
               subtitle: Text(user.role == 'tutor' ? 'Gia sư' : 'Học viên'),
               trailing: Text('${user.distance.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
             ),
             if (user.isIncognito)
               const Padding(
                 padding: EdgeInsets.only(bottom: 8.0),
                 child: Text('(Vị trí chỉ mang tính chất tương đối)', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
               ),
             const SizedBox(height: 10),
             const SizedBox(height: 10),
             if (user.role == 'tutor')
               SizedBox(
                 width: double.infinity,
                 child: OutlinedButton.icon(
                   onPressed: () => _navigateToTutorDetail(user.id),
                   icon: const Icon(Icons.person),
                   label: const Text('Xem hồ sơ'),
                 ),
               ),
           ],
         ),
       ),
     );
  }

  void _showSharedLocationInfo(LatLng position) {
     showModalBottomSheet(
       context: context,
       builder: (context) => Container(
         padding: const EdgeInsets.all(16),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const ListTile(
               leading: Icon(Icons.location_on, color: Colors.redAccent, size: 40),
               title: Text('Vị trí được chia sẻ', style: TextStyle(fontWeight: FontWeight.bold)),
               subtitle: Text('Từ tin nhắn'),
             ),
             const SizedBox(height: 10),
             SizedBox(
               width: double.infinity,
               child: FilledButton.icon(
                 onPressed: () {
                   _fetchRoute(position);
                 }, 
                 icon: const Icon(Icons.directions),
                 label: const Text('Chỉ đường'),
               ),
             )
           ],
         ),
       ),
     );
  }

  Future<void> _navigateToTutorDetail(String tutorId) async {
    Navigator.pop(context); // Close bottom sheet
    
    // Show loading
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator())
    );

    try {
      // Import this: import 'package:doantotnghiep/features/tutor/data/tutor_repository.dart';
      final tutor = await ref.read(tutorRepositoryProvider).getTutorById(tutorId);
      
      if (mounted) {
        Navigator.pop(context); // Hide loading
        if (tutor != null) {
          context.push('/tutor-detail', extra: tutor);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể tải thông tin gia sư')));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }  

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        double tempRadius = _radius;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bộ lọc Tìm kiếm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Bán kính: ${tempRadius.toInt()} km', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    Slider(
                      value: tempRadius,
                      min: 1.0,
                      max: 25.0,
                      divisions: 24,
                      label: '${tempRadius.toInt()} km',
                      onChanged: (value) {
                         setModalState(() => tempRadius = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(labelText: 'Môn học (VD: Toán)', prefixIcon: Icon(Icons.book)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Giá từ', prefixIcon: Icon(Icons.attach_money)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Đến', prefixIcon: Icon(Icons.attach_money)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _radius = tempRadius;
                            _filterSubject = _subjectController.text.isNotEmpty ? _subjectController.text : null;
                            _filterMinPrice = _minPriceController.text.isNotEmpty ? double.tryParse(_minPriceController.text) : null;
                            _filterMaxPrice = _maxPriceController.text.isNotEmpty ? double.tryParse(_maxPriceController.text) : null;
                          });
                          Navigator.pop(context);
                          if (_currentPosition != null) _fetchNearbyUsers(_currentPosition!);
                        },
                        child: const Text('Áp dụng'),
                      ),
                    ),
                    TextButton(
                       onPressed: () {
                          _subjectController.clear();
                          _minPriceController.clear();
                          _maxPriceController.clear();
                          setState(() {
                            _radius = 10.0; // Reset radius default
                            _filterSubject = null;
                            _filterMinPrice = null;
                            _filterMaxPrice = null;
                          });
                          Navigator.pop(context);
                          if (_currentPosition != null) _fetchNearbyUsers(_currentPosition!);
                       },
                       child: const Center(child: Text('Xóa bộ lọc')),
                    )
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_currentPosition != null) _fetchNearbyUsers(_currentPosition!);
            },
          )
        ],
      ),
      body: _currentPosition == null 
         ? Center(child: _isLoading ? const CircularProgressIndicator() : const Text('Chưa có vị trí'))
         : FlutterMap(
             mapController: _mapController,
             options: MapOptions(
               initialCenter: _currentPosition!,
               initialZoom: 14.0,
             ),
             children: [
               TileLayer(
                 urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                 userAgentPackageName: 'com.antigravity.midon',
               ),
               PolylineLayer(
                 polylines: [
                   Polyline(
                     points: _routePoints,
                     strokeWidth: 4.0,
                     color: Colors.blue,
                   ),
                 ],
               ),
               MarkerLayer(
                 markers: [
                   // Me
                   Marker(
                     point: _currentPosition!,
                     width: 80,
                     height: 80,
                     child: _buildMyMarker(),
                   ),
                   // Others
                   ..._nearbyUsers.map((u) => Marker(
                      point: u.position,
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _showDistanceInfo(u),
                        child: _buildUserMarker(u),
                      ),
                   )),
                   // Shared Location Marker
                   if (widget.targetLocation != null)
                      Marker(
                        point: widget.targetLocation!,
                        width: 80, 
                        height: 80,
                        child: GestureDetector(
                          onTap: () => _showSharedLocationInfo(widget.targetLocation!),
                          child: Column(
                            children: [
                               const Icon(Icons.location_on, color: Colors.redAccent, size: 50),
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.redAccent)),
                                 child: const Text('Vị trí đã chia sẻ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.redAccent)),
                               )
                            ],
                          ),
                        ),
                      ),
                 ],
               ),
             ],
           ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
           FloatingActionButton(
            heroTag: "filterBtn",
            onPressed: _showFilterModal,
            backgroundColor: Colors.white,
            child: Icon(Icons.filter_list, color: (_filterSubject != null || _filterMinPrice != null) ? Colors.blue : Colors.black),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "locationBtn",
            onPressed: _getCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  Widget _buildMyMarker() {
     return Column(
       children: [
         const Icon(Icons.location_on, color: Colors.blue, size: 40),
         Container(
           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
           decoration: const BoxDecoration(
             color: Colors.white, 
             borderRadius: BorderRadius.all(Radius.circular(8))
           ),
           child: const Text('Tôi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
         )
       ],
     );
  }

  Widget _buildUserMarker(MapUser user) {
     return Column(
       children: [
          Container(
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               border: Border.all(color: user.isIncognito ? Colors.grey : Colors.red, width: 2),
             ),
             child: CircleAvatar(
               radius: 18,
               backgroundColor: Colors.white,
               backgroundImage: (user.avatarUrl.isNotEmpty && !user.isIncognito) ? CachedNetworkImageProvider(user.avatarUrl) : null,
               child: (user.avatarUrl.isEmpty || user.isIncognito) ? const Icon(Icons.person, size: 20) : null,
             ),
          ),
          Container(
             margin: const EdgeInsets.only(top: 2),
             padding: const EdgeInsets.symmetric(horizontal: 4),
             decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(4)),
             child: Text(
               '${user.distance.toStringAsFixed(1)}km', 
               style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
             ),
          )
       ],
     );
  }
}
