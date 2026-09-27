import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/ac_remote_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const AcRemoteApp());
}

class AcRemoteApp extends StatelessWidget {
  const AcRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IR AC Remote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AcRemoteScreen(),
    );
  }
}
