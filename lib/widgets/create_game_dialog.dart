import 'package:flutter/material.dart';

Future<String?> showCreateGameDialog(BuildContext context) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _CreateGameDialogContent();
    },
  );
}

class _CreateGameDialogContent extends StatefulWidget {
  const _CreateGameDialogContent();

  @override
  State<_CreateGameDialogContent> createState() => _CreateGameDialogContentState();
}

class _CreateGameDialogContentState extends State<_CreateGameDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Создание новой игры',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 520,
              padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E4),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          color: Color(0xFF3A1800),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Название игры',
                        style: TextStyle(
                          color: Color(0xFF3A1800),
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Введите название игры',
                          hintStyle: TextStyle(
                            color: const Color(0xFF3A1800).withValues(alpha: 0.4),
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFFFBF7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF3A1800),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context, _controller.text.trim());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 56,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFA35A33),
                                  Color(0xFF863C15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(37.5),
                            ),
                            child: const Text(
                              'Сохранить',
                              style: TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
