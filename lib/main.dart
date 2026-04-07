import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/mode_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ProviderScope(child: ViktorinaApp()));
}

class ViktorinaApp extends StatelessWidget {
  const ViktorinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Викторина',
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
      ),
    );
  }
}
