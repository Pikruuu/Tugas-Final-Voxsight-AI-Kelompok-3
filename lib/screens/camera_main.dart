import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../service/camera_service.dart';
import '../utils/app_theme.dart';

class CameraMain extends StatefulWidget {
  final String deviceId;

  const CameraMain({super.key, required this.deviceId});

  @override
  State<CameraMain> createState() => _CameraMainState();
}

class _CameraMainState extends State<CameraMain> {
  final CameraService _cameraService = CameraService(
    url: 'wss://voxsight-demo.ngonsul.web.id/watch/PERVOX-0001-22526',
  );

  bool get _isConnected => _cameraService.isConnected;
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? cameraStatus;
  List<dynamic> cameraHistory = [];

  String get displayStatus {
    if (cameraStatus == null) return _isConnected ? 'Online' : 'Offline';
    return cameraStatus!['is_streaming'] == true ? 'Online' : 'Offline';
  }

  String valueOrFallback(dynamic value, String fallback) {
    if (value == null) return fallback;
    return value.toString();
  }

  Future<void> startStream() async {
    await _cameraService.connect();
    setState(() {});
  }

  Future<void> stopStream() async {
    await _cameraService.disconnect();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchCameraData();
  }

  Future<void> fetchCameraData() async {
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

      final status = await CameraService.getCameraStatus(token, widget.deviceId);
      final history = await CameraService.getCameraHistory(token, widget.deviceId);

      setState(() {
        cameraStatus = status;
        cameraHistory = history;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 128,
        backgroundColor: const Color(0xFF223148),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16.0),
            bottomRight: Radius.circular(16.0),
          ),
        ),
        title: const Text(
          "Camera Tracking",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF223148),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: !_isConnected
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.videocam_off_outlined,
                                    color: Colors.white38, size: 48),
                                Text(
                                  'Stream berhenti',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          )
                        : StreamBuilder<String>(
                            stream: _cameraService.stream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Center(
                                  child: Text(
                                    snapshot.data!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error: ${snapshot.error}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              } else {
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                );
                              }
                            },
                          ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: GestureDetector(
                      onTap: () {
                        if (_isConnected) {
                          stopStream();
                        } else {
                          startStream();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isConnected
                              ? AppColors.accentRed.withValues(alpha: 0.85)
                              : AppColors.accentGreen.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.white54),
                        ),
                        child: Text(
                          _isConnected ? 'Stop' : 'Start',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: fetchCameraData,
                      child: const Text('Muat Ulang'),
                    ),
                  ],
                ),
              )
            else ...[
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(left: 16),
                child: Text(
                  'Sensor Details',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam, color: Colors.black, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Status Camera',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      displayStatus,
                      style: TextStyle(
                        color: displayStatus == 'Online' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _buildInfoRow('FPS', valueOrFallback(cameraStatus?['fps'], 'N/A')),
              _buildInfoRow('Focus', valueOrFallback(cameraStatus?['values_focus'], 'N/A')),
              _buildInfoRow('Lens clarity', valueOrFallback(cameraStatus?['value_clarity'], 'N/A')),
              _buildInfoRow('Latency', valueOrFallback(cameraStatus?['latency'], 'N/A')),
              if (cameraHistory.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.black, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Riwayat Kamera',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${cameraHistory.length} entri',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(_getIconForTitle(title), color: Colors.black, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'FPS':
        return Icons.speed;
      case 'Focus':
        return Icons.center_focus_strong;
      case 'Lens clarity':
        return Icons.lens_blur;
      case 'Latency':
        return Icons.network_cell;
      default:
        return Icons.info_outline;
    }
  }
}