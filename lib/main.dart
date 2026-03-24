import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/mode_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const SvoyaIgraApp());
}

class SvoyaIgraApp extends StatelessWidget {
  const SvoyaIgraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Своя Игра',
      theme: ThemeData(
        fontFamily: '.SF Pro Display',
        fontFamilyFallback: const [
          'SF Pro Display',
          'SF Pro',
          '-apple-system',
          'Helvetica Neue',
          'Roboto',
          'sans-serif',
        ],
      ),
      home: const ModeSelectionScreen(),
    );
  }
}
