import 'package:flutter/material.dart';
import 'host_setup_screen.dart';
import 'game_board_screen.dart';

const _hostCode = '1111';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  Future<void> _onHostTap(BuildContext context) async {
    final controller = TextEditingController();
    final navigator = Navigator.of(context);

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFBF7),
          title: const Text(
            'Введите код доступа',
            style: TextStyle(color: Color(0xFF3A1800)),
          ),
          content: TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Код',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (value.trim() == _hostCode) {
                navigator.pop(true);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim() == _hostCode) {
                  navigator.pop(true);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Неверный код')),
                  );
                }
              },
              child: const Text('Войти'),
            ),
          ],
        );
      },
    );

    if (accepted == true && context.mounted) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => const HostSetupScreen(),
        ),
      );
    }
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
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ModeButton(
                  label: 'Режим игры — Ведущий',
                  onTap: () => _onHostTap(context),
                ),
                const SizedBox(width: 80),
                _ModeButton(
                  label: 'Режим игры — Игроки',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GameBoardScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ModeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFA35A33), Color(0xFF863C15)],
          ),
          borderRadius: BorderRadius.circular(37.5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.9,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
