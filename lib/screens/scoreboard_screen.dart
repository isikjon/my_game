import 'dart:math';
import 'package:flutter/material.dart';
import 'mode_selection_screen.dart';

class ScoreboardScreen extends StatefulWidget {
  final List<String>? teams;
  final Map<String, int>? scores;

  const ScoreboardScreen({super.key, this.teams, this.scores});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen>
    with TickerProviderStateMixin {
  late final List<String> _teamNames;
  late final List<int> _scores;
  late final int _winnerIndex;
  late final AnimationController _mainController;
  late final AnimationController _crownController;
  late final List<Animation<double>> _entryAnims;
  late final Animation<double> _countAnim;
  late final Animation<double> _crownAnim;

  @override
  void initState() {
    super.initState();

    final rng = Random();
    if (widget.teams != null && widget.scores != null) {
      _teamNames = widget.teams!;
      _scores = _teamNames.map((t) => widget.scores![t] ?? 0).toList();
    } else {
      _teamNames = ['Команда 1', 'Команда 2', 'Команда 3', 'Команда 4'];
      _scores = List.generate(4, (_) => (rng.nextInt(46) + 5) * 100);
    }
    _winnerIndex = _scores.isEmpty
        ? 0
        : _scores.indexOf(_scores.reduce((a, b) => a > b ? a : b));

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _crownController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _entryAnims = List.generate(
      _teamNames.length,
      (i) => CurvedAnimation(
        parent: _mainController,
        curve: Interval(
          i * 0.04,
          0.18 + i * 0.04,
          curve: Curves.easeOut,
        ),
      ),
    );

    _countAnim = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.20, 1.0, curve: Curves.easeOutCubic),
    );

    _crownAnim = CurvedAnimation(
      parent: _crownController,
      curve: Curves.elasticOut,
    );

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _crownController.forward();
        });
      }
    });

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _crownController.dispose();
    super.dispose();
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
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.06,
                  vertical: constraints.maxHeight * 0.04,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTeamsRow(),
                        const SizedBox(height: 50),
                        GestureDetector(
                          onTap: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ModeSelectionScreen(),
                            ),
                            (_) => false,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 64, vertical: 22),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFA35A33), Color(0xFF863C15)],
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Text(
                              'На главную',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.6,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_teamNames.length, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < _teamNames.length - 1 ? 70.0 : 0),
          child: AnimatedBuilder(
            animation: _entryAnims[i],
            builder: (context, child) {
              return Opacity(
                opacity: _entryAnims[i].value,
                child: Transform.translate(
                  offset: Offset(0, 50 * (1 - _entryAnims[i].value)),
                  child: child,
                ),
              );
            },
            child: _buildTeamColumn(i),
          ),
        );
      }),
    );
  }

  Widget _buildTeamColumn(int index) {
    final isWinner = index == _winnerIndex;

    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 110,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildScoreBadge(index, isWinner),
            ),
          ),
          const SizedBox(height: 24),
          _buildIconCardWithCrown(isWinner),
          const SizedBox(height: 26),
          _buildNamePill(index),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(int index, bool isWinner) {
    return AnimatedBuilder(
      animation: Listenable.merge([_countAnim, _crownAnim]),
      builder: (context, _) {
        final displayed = (_countAnim.value * _scores[index]).round();
        final goldProgress = isWinner ? _crownAnim.value : 0.0;
        final bgColor = Color.lerp(
          const Color(0xFFFFF1E4),
          const Color(0xFFFFD566),
          goldProgress,
        )!;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWinner ? 52 : 40,
            vertical: isWinner ? 24 : 18,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            displayed.toString(),
            style: TextStyle(
              color: const Color(0xFF3A1800),
              fontSize: isWinner ? 60 : 48,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.9,
              height: 1.0,
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconCardWithCrown(bool isWinner) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        _buildIconCard(),
        if (isWinner)
          Positioned(
            left: (280 - 107) / 2,
            bottom: -30,
            child: ScaleTransition(
              scale: _crownAnim,
              child: Image.asset(
                'assets/images/crown.png',
                width: 107,
                height: 107,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIconCard() {
    return Container(
      width: 280,
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E4),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/users.png',
          width: 130,
          height: 130,
        ),
      ),
    );
  }

  Widget _buildNamePill(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E4),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Text(
        _teamNames[index],
        style: const TextStyle(
          color: Color(0xFF3A1800),
          fontSize: 45,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.9,
          height: 1.0,
        ),
      ),
    );
  }
}
