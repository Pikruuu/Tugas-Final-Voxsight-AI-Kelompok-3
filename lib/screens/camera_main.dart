import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  // Sesuaikan host & port dengan server kamu
  static const String _wsHost = '10.0.2.2';
  static const int _wsPort = 1235;

  final CameraService _cameraService = CameraService(
    url: 'ws://$_wsHost:$_wsPort',
  );

  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

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
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _videoInitialized = false;
    setState(() {});
  }

  void _initVideo(String videoUrl) {
    // Hindari re-init kalau video sudah jalan
    if (_videoController != null) return;

    final fullUrl = videoUrl.startsWith('http')
        ? videoUrl
        : 'http://$_wsHost:$_wsPort$videoUrl';

    _videoController = VideoPlayerController.networkUrl(Uri.parse(fullUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoInitialized = true);
        _videoController!.setLooping(true);
        _videoController!.play();
      });
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

      final status =
          await CameraService.getCameraStatus(token, widget.deviceId);
      final history =
          await CameraService.getCameraHistory(token, widget.deviceId);

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
    _videoController?.dispose();
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
                                Map<String, dynamic>? data;
                                try {
                                  data = jsonDecode(snapshot.data!)
                                      as Map<String, dynamic>;
                                } catch (_) {
                                  data = null;
                                }

                                final videoUrl = data?['videoUrl'] as String?;

                                if (videoUrl != null) {
                                  _initVideo(videoUrl);
                                }

                                if (_videoController != null &&
                                    _videoInitialized) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: SizedBox.expand(
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _videoController!
                                              .value.size.width,
                                          height: _videoController!
                                              .value.size.height,
                                          child: VideoPlayer(_videoController!),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                // Belum ada videoUrl atau video belum siap
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
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
                        color: displayStatus == 'Online'
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _buildInfoRow(
                'FPS',
                displayStatus == 'Online'
                    ? valueOrFallback(cameraStatus?['fps'], 'N/A')
                    : '',
                isOffline: displayStatus != 'Online',
              ),
              _buildInfoRow(
                'Focus',
                displayStatus == 'Online'
                    ? valueOrFallback(cameraStatus?['values_focus'], 'N/A')
                    : '',
                isOffline: displayStatus != 'Online',
              ),
              _buildInfoRow(
                'Lens clarity',
                displayStatus == 'Online'
                    ? valueOrFallback(cameraStatus?['value_clarity'], 'N/A')
                    : '',
                isOffline: displayStatus != 'Online',
              ),
              _buildInfoRow(
                'Latency',
                displayStatus == 'Online'
                    ? valueOrFallback(cameraStatus?['latency'], 'N/A')
                    : '',
                isOffline: displayStatus != 'Online',
              ),
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
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isOffline = false}) {
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
            style: TextStyle(
              color: isOffline ? Colors.red : Colors.green,
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
