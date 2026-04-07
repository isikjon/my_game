import 'package:flutter/material.dart';

/// Shows the "Получить очки" dialog.
/// Returns the name of the team that answered (or null if closed without selection).
Future<String?> showScoreAssignmentDialog(
  BuildContext context, {
  required List<String> teams,
  required int scoreValue,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (_, anim, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
    pageBuilder: (ctx, _, __) => _ScoreAssignmentDialog(
      teams: teams,
      scoreValue: scoreValue,
    ),
  );
}

class _ScoreAssignmentDialog extends StatefulWidget {
  final List<String> teams;
  final int scoreValue;

  const _ScoreAssignmentDialog({
    required this.teams,
    required this.scoreValue,
  });

  @override
  State<_ScoreAssignmentDialog> createState() => _ScoreAssignmentDialogState();
}

class _ScoreAssignmentDialogState extends State<_ScoreAssignmentDialog> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1E4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Получить очки',
                        style: TextStyle(
                          color: Color(0xFF3A1800),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${widget.scoreValue} очков',
                        style: const TextStyle(
                          color: Color(0xFFE8841A),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, null),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close,
                          color: Color(0xFF3A1800), size: 26),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Teams row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.teams.map((team) {
                    final isSelected = _selected == team;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = team),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE8841A)
                                    : const Color(0xFFFFFBF7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/users.png',
                                  width: 64,
                                  height: 64,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              team,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFE8841A)
                                    : const Color(0xFF3A1800),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              // Далее button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF863C15),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Далее',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
