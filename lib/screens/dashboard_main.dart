import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'local_notif.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationHelper.init(); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}