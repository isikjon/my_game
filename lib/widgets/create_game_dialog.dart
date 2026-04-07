import 'package:flutter/material.dart';

Future<String?> showCreateGameDialog(BuildContext context) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 20),
        child: Center(
          child: SingleChildScrollView(
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Создание новой игры',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
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
                                size: 26,
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
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _controller,
                              autofocus: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) =>
                                  Navigator.pop(context, _controller.text.trim()),
                              decoration: InputDecoration(
                                hintText: 'Введите название игры',
                                hintStyle: TextStyle(
                                  color: const Color(0xFF3A1800).withValues(alpha: 0.4),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFFFBF7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF3A1800),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context, _controller.text.trim());
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
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
                                  child: const Center(
                                    child: Text(
                                      'Сохранить',
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.5,
                                        height: 1.0,
                                      ),
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
          ),
        ),
      ),
    );
  }
}
