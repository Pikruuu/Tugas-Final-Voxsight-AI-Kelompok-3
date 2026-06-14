import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../service/auth_service.dart';
import '../service/location_service.dart';

class LocationHistory {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime time;

  LocationHistory({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.time,
  });
}

String formatTime(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')} '
      '${_monthName(dt.month)} ${dt.year}, '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String _monthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  return months[month - 1];
}

Future<String> getAddress(double lat, double lng) async {
  try {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    final place = placemarks.first;
    return '${place.street}, ${place.subLocality}, ${place.locality}';
  } catch (_) {
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}

class TrackingScreen extends StatefulWidget {
  final String deviceId;

  const TrackingScreen({super.key, required this.deviceId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? mapController;
  bool isLoading = true;
  String? errorMessage;
  String currentAddress = 'Memuat alamat...';
  DateTime? lastUpdated;
  double? latitude;
  double? longitude;
  List<LocationHistory> locationHistory = [];

  @override
  void initState() {
    super.initState();
    fetchLocationData();
  }

Future<void> fetchLocationData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    if (widget.deviceId.isEmpty) {
      setState(() {
        errorMessage = 'Pilih device terlebih dahulu dari Dashboard.';
        isLoading = false;
      });
      return;
    }

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Mohon login ulang.');
      }

      final data = await LocationService.getLocation(token, widget.deviceId);
      final history = await LocationService.getLocationHistory(token, widget.deviceId);

      final double lat = double.tryParse(data['latitude']?.toString() ?? '') ?? 0.0;
      final double lng = double.tryParse(data['longitude']?.toString() ?? '') ?? 0.0;
      final DateTime updatedAt = DateTime.tryParse(data['recorded_at']?.toString() ?? '') ?? DateTime.now();
      final address = await getAddress(lat, lng);

      setState(() {
        latitude = lat;
        longitude = lng;
        lastUpdated = updatedAt;
        currentAddress = address;
        locationHistory = history.map<LocationHistory>((item) {
          final itemLat = double.tryParse(item['latitude']?.toString() ?? '') ?? 0.0;
          final itemLng = double.tryParse(item['longitude']?.toString() ?? '') ?? 0.0;
          final recordedAt = DateTime.tryParse(item['recorded_at']?.toString() ?? '') ?? DateTime.now();

          return LocationHistory(
            latitude: itemLat,
            longitude: itemLng,
            address: '${itemLat.toStringAsFixed(5)}, ${itemLng.toStringAsFixed(5)}',
            time: recordedAt,
          );
        }).toList();
        isLoading = false;
      });

      // Hindari pakai mapController lama yang sudah disposed
      // (terjadi kalau GoogleMap sempat dilepas dari tree saat error sebelumnya)
      if (mapController != null) {
        try {
          await mapController!.animateCamera(
            CameraUpdate.newLatLng(LatLng(lat, lng)),
          );
        } catch (_) {
          // Controller lama sudah disposed, GoogleMap akan rebuild
          // dan dapat controller baru lewat onMapCreated.
          mapController = null;
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        // Reset controller karena GoogleMap akan dilepas dari tree
        // saat tampilan error ditampilkan.
        mapController = null;
      });
    }
  }

  @override
  void dispose() {
    mapController = null;
    super.dispose();
  }

  LatLng get initialPosition {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return const LatLng(-7.310887753118097, 112.72894337595493);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 128,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16.0),
            bottomRight: Radius.circular(16.0),
          ),
        ),
        title: const Text('Tracker Location'),
        backgroundColor: const Color(0xFF223148),
        foregroundColor: const Color(0xFFF3EAE0),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Lokasi',
            onPressed: () {
              if (locationHistory.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(history: locationHistory),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: fetchLocationData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: fetchLocationData,
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: initialPosition,
                          zoom: 15,
                        ),
                        markers: latitude != null && longitude != null
                            ? {
                                Marker(
                                  markerId: MarkerId(widget.deviceId),
                                  position: LatLng(latitude!, longitude!),
                                  infoWindow: InfoWindow(
                                    title: widget.deviceId,
                                    snippet: currentAddress,
                                  ),
                                )
                              }
                            : {},
                        onMapCreated: (controller) {
                          mapController = controller;
                        },
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF223148),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.deviceId,
                            style: const TextStyle(
                              color: Color(0xFFF3EAE0),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentAddress,
                            style: const TextStyle(color: Color(0xFFF3EAE0), fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastUpdated != null
                                ? 'Diperbarui: ${formatTime(lastUpdated!)}'
                                : 'Memuat waktu...',
                            style: const TextStyle(color: Color(0xCCF3EAE0), fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Riwayat lokasi: ${locationHistory.length} entri',
                            style: const TextStyle(color: Color(0xFFF3EAE0), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  final List<LocationHistory> history;

  const HistoryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Lokasi'),
        backgroundColor: const Color(0xFF223148),
      ),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          return ListTile(
            title: Text(item.address),
            subtitle: Text(formatTime(item.time)),
            trailing: Text(
              '${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}