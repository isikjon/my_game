import 'package:flutter/material.dart';
import 'host_setup_screen.dart';
import 'player_join_screen.dart';

const _hostCode = '1111';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  Future<void> _onHostTap(BuildContext context) async {
    final controller = TextEditingController();
    final navigator = Navigator.of(context);
    bool hasError = false;

    final accepted = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) {
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            return GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24, 20, 24,
                  MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF7),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Код доступа',
                                  style: TextStyle(
                                    color: Color(0xFF3A1800),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(ctx, false),
                                  behavior: HitTestBehavior.opaque,
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close,
                                        color: Color(0xFF3A1800), size: 26),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: controller,
                              obscureText: true,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Введите код',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF3A1800).withValues(alpha: 0.4),
                                  fontSize: 18,
                                ),
                                errorText: hasError ? 'Неверный код' : null,
                                filled: true,
                                fillColor: const Color(0xFFFFF1E4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 18),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF3A1800),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                              onSubmitted: (value) {
                                if (value.trim() == _hostCode) {
                                  Navigator.pop(ctx, true);
                                } else {
                                  setDlg(() => hasError = true);
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF863C15),
                                      side: const BorderSide(
                                          color: Color(0xFF863C15), width: 1.5),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                    child: const Text(
                                      'Отмена',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (controller.text.trim() == _hostCode) {
                                        Navigator.pop(ctx, true);
                                      } else {
                                        setDlg(() => hasError = true);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF863C15),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                    child: const Text(
                                      'Войти',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/branding/app_icon.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Викторина',
                      style: TextStyle(
                        color: Color(0xFF3A1800),
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeButton(
                              label: 'Режим игры — Ведущий',
                              onTap: () => _onHostTap(context),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _ModeButton(
                              label: 'Режим игры — Игроки',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PlayerJoinScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFA35A33), Color(0xFF863C15)],
          ),
          borderRadius: BorderRadius.circular(37.5),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
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
      ),
    );
  }
}
