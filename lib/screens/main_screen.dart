import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'notif.dart';
import 'local_notif.dart';
import 'notif_logic.dart';
import 'camera_main.dart';
import 'profile_screen.dart';
import 'location_main.dart';
import '../service/api_service.dart';
import '../service/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  int battery = 0;

  int used = 0;

  int remaining = 0;

  bool isOnline = false;

  String lastLocation = '-';

  bool alreadyNotified = false;

  bool isLoading = true;

  String selectedDeviceId = '8a33956f-a87e-491c-8ba4-ad74b9473110';

  List<AppNotification> alertList = [];

  @override
  void initState() {
    super.initState();

    loadData();
  }

  Future<void> loadData() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Mohon login ulang.');
      }

      final dashboardData = await ApiService.getDashboard(token);

      debugPrint("=== DASHBOARD RESPONSE ===");
      debugPrint(dashboardData.toString());

      final devices = dashboardData['data']['devices'] as List;

      debugPrint("=== DEVICES ===");
      debugPrint(devices.toString());

      if (devices.isNotEmpty) {
        final device = devices.first;

        debugPrint("=== DEVICE PERTAMA ===");
        debugPrint(device.toString());

        setState(() {
          battery = double.tryParse(device['battery'].toString())?.toInt() ?? 0;
          selectedDeviceId = device['id_device']?.toString() ?? selectedDeviceId;

          debugPrint("Battery sekarang: $battery");
          debugPrint("Selected device ID: $selectedDeviceId");

          if (battery < 30) {
            debugPrint("BATTERY ALERT TERPICU");

            NotificationHelper.showNotification(
              title: "Baterai Rendah",
              body: "Baterai tersisa $battery%",
            );
          }

          used = double.tryParse(device['paket_data'].toString())?.toInt() ?? 0;

          remaining = 2000 - used;

          isOnline = device['is_active'] ?? false;
        });

        debugPrint("Battery: $battery");
        debugPrint("Used: $used");
        debugPrint("Remaining: $remaining");
        debugPrint("Online: $isOnline");
      }

      // alertnotifikasi
      debugPrint("TOKEN DARI STORAGE = $token");
      final alerts = await ApiService.getAlerts(token);

      debugPrint("Jumlah alert: ${alerts.length}");
      debugPrint(alerts.toString());

      setState(() {
        alertList = alerts
            .map<AppNotification>(
              (e) => AppNotification.fromJson(e),
            )
            .toList();

        debugPrint("Hasil Mapping: ${alertList.length}");
        isLoading = false;
      });

      debugPrint("=== ALERT LIST ===");
      debugPrint(alertList.length.toString());

      showLocalNotifications();
    } catch (e) {
      debugPrint("ERROR LOAD DATA:");
      debugPrint(e.toString());

      setState(() {
        isLoading = false;
      });
    }
  }

  void showLocalNotifications() {
    if (alreadyNotified) return;

    for (var alert in alertList) {
      NotificationHelper.showNotification(
        title: alert.title,
        body: alert.message,
      );
    }

    alreadyNotified = true;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final List<Widget> pages = [
      DashboardScreen(
        deviceId: selectedDeviceId,
        battery: battery,
        used: used,
        remaining: remaining,
        isOnline: isOnline,
      ),
      TrackingScreen(deviceId: selectedDeviceId),
      CameraMain(deviceId: selectedDeviceId),
      NotificationScreen(notifications: alertList),
      ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on), label: "Lokasi"),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt), label: "Camera"),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: "Alert"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
