import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  final String deviceId;
  final int battery;
  final int used;
  final int remaining;
  final bool isOnline;

  const DashboardScreen({
    super.key,
    required this.deviceId,
    required this.battery,
    required this.used,
    required this.remaining,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              height: 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0XFF223148),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Dashboard",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "VoxSight AI Monitoring",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0XFF223148),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.remove_red_eye,
                          color: Colors.white),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "VoxSight AI-001",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Smart Glasses • ID: VS2024-001",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color:
                                    isOnline ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline ? "Connected" : "Offline",
                                style: TextStyle(
                                  color: isOnline
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildCard(
                        child: _buildPieChart(
                          battery.toDouble(),
                          Colors.green,
                          "$battery%",
                          "Battery",
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildCard(
                        child: _buildInternetChart(
                          used: used.toDouble(),
                          remaining: remaining.toDouble(),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildPieChart(
      double value, Color color, String text, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 140,
              width: 140,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 45,
                  sections: [
                    PieChartSectionData(
                      value: value,
                      color: color,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 100 - value,
                      color: Colors.grey.shade300,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
            ),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(label),
      ],
    );
  }

  Widget _buildInternetChart({
    required double used,
    required double remaining,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 140,
              width: 140,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 45,
                  sections: [
                    PieChartSectionData(
                      value: used,
                      color: Colors.grey.shade300,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: remaining,
                      color: Colors.blue,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
            ),
            Text(
              "${remaining.toInt()} MB",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text("Internet used 1000"),
      ],
    );
  }
}