import 'dart:async';
import 'package:flutter/material.dart';
import 'scoreboard_screen.dart';

class QuestionScreen extends StatefulWidget {
  final String question;

  const QuestionScreen({super.key, required this.question});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int _seconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds > 0) {
        setState(() {
          _seconds--;
        });
      } else {
        _timer?.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ScoreboardScreen(),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    return '00:${_seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final scale = w / 1920;

              return Center(
                child: Container(
                  width: w * 0.78,
                  padding: EdgeInsets.symmetric(
                    horizontal: 120 * scale,
                    vertical: 64 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E4),
                    borderRadius: BorderRadius.circular(60 * scale),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 80 * scale,
                          vertical: 20 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD7B2),
                          borderRadius: BorderRadius.circular(36 * scale),
                        ),
                        child: Text(
                          _formattedTime,
                          style: TextStyle(
                            color: const Color(0xFF3A1800),
                            fontSize: 80 * scale,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.9,
                            height: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(height: 40 * scale),
                      Text(
                        widget.question,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF3A1800),
                          fontSize: 80 * scale,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.9,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
