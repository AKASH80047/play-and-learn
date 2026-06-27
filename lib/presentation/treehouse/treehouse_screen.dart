import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_button.dart';

class PipsTreehouseScreen extends StatefulWidget {
  const PipsTreehouseScreen({super.key});

  @override
  State<PipsTreehouseScreen> createState() => _PipsTreehouseScreenState();
}

enum TimeOfDayCycle { day, sunset, night }

class MusicalNote {
  final int id;
  double x;
  double y;
  double opacity;
  final double scale;
  final String noteChar;
  final double speed;
  final double wiggleSpeed;

  MusicalNote({
    required this.id,
    required this.x,
    required this.y,
    required this.opacity,
    required this.scale,
    required this.noteChar,
    required this.speed,
    required this.wiggleSpeed,
  });
}

class CookieParticle {
  final int id;
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double opacity;
  final String emoji;

  CookieParticle({
    required this.id,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.opacity,
    required this.emoji,
  });
}

class _PipsTreehouseScreenState extends State<PipsTreehouseScreen>
    with TickerProviderStateMixin {
  // Time of Day state
  TimeOfDayCycle _timeOfDay = TimeOfDayCycle.day;

  // Interactive states
  bool _isLanternOn = false;
  bool _isRadioOn = false;
  int _selectedHatIndex = 0; // 0: None, 1: Explorer, 2: Wizard, 3: Crown
  int _happinessPoints = 0;
  bool _isPipWiggling = false;
  String _pipSpeech = "Hoot! Welcome to my Treehouse! 🏡🌳";
  bool _showSpeechBubble = true;

  // Animation Controllers
  late AnimationController _pipWiggleController;
  late AnimationController _cloudFloatController;
  late AnimationController _ambientNoteController;
  
  // Lists for particle animations
  final List<MusicalNote> _notes = [];
  final List<CookieParticle> _cookieParticles = [];
  final Random _random = Random();

  final List<String> _pipSpeeches = [
    "Hoot hoot! I love when you visit! 🦉💚",
    "Did you know treehouses are the best for star gazing? 🌟🔭",
    "Tap the window to watch the day change! ☀️🌇🌙",
    "I'm feeling very cozy today! 🥰🌲",
    "Can you feed me a delicious cookie? 🍪😋",
    "Music makes me want to dance! 🎵🕺",
    "Hoot! Look at my awesome hat! 👒🧙‍♂️👑",
    "You are an amazing explorer! ⭐👍",
  ];

  final List<String> _notesChars = ['🎵', '🎶', '♩', '𝅘𝅥𝅯', '🎷', '🎸'];

  @override
  void initState() {
    super.initState();

    // Pip wiggle animation
    _pipWiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Floating background elements
    _cloudFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // Game loops for notes/particles
    _ambientNoteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateParticles);
    _ambientNoteController.repeat();
  }

  @override
  void dispose() {
    _pipWiggleController.dispose();
    _cloudFloatController.dispose();
    _ambientNoteController.dispose();
    super.dispose();
  }

  void _triggerPipWiggle({String? customSpeech}) {
    if (_isPipWiggling) {
      if (customSpeech != null) {
        setState(() {
          _pipSpeech = customSpeech;
          _showSpeechBubble = true;
        });
      }
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _isPipWiggling = true;
      _showSpeechBubble = true;
      _pipSpeech = customSpeech ?? _pipSpeeches[_random.nextInt(_pipSpeeches.length)];
    });
    _pipWiggleController.forward(from: 0.0).then((_) {
      setState(() {
        _isPipWiggling = false;
      });
    });
  }

  void _toggleLantern() {
    HapticFeedback.lightImpact();
    setState(() {
      _isLanternOn = !_isLanternOn;
      _triggerPipWiggle(
        customSpeech: _isLanternOn
            ? "Ooh, so bright and warm! 💡✨"
            : "Ah, the stars look brighter in the dark! 🌌🌙",
      );
    });
  }

  void _toggleRadio() {
    HapticFeedback.lightImpact();
    setState(() {
      _isRadioOn = !_isRadioOn;
      _triggerPipWiggle(
        customSpeech: _isRadioOn
            ? "Let's groove! Hoot! 🎶🦉"
            : "Shh... quiet time in the forest. 🤫🌲",
      );
    });
  }

  void _cycleTimeOfDay() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_timeOfDay == TimeOfDayCycle.day) {
        _timeOfDay = TimeOfDayCycle.sunset;
        _pipSpeech = "Wow! Look at the beautiful sunset! 🌇🧡";
      } else if (_timeOfDay == TimeOfDayCycle.sunset) {
        _timeOfDay = TimeOfDayCycle.night;
        _pipSpeech = "Time to count the stars! 🌙🌟";
      } else {
        _timeOfDay = TimeOfDayCycle.day;
        _pipSpeech = "Good morning! Time to play! ☀️🦅";
      }
      _showSpeechBubble = true;
    });
  }

  void _changeHat(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedHatIndex = index;
      String hatMsg = "No hat for now! 🦉";
      if (index == 1) hatMsg = "I'm ready for a forest expedition! 🤠🌲";
      if (index == 2) hatMsg = "Alakazam! I can cast spells now! 🧙‍♂️✨";
      if (index == 3) hatMsg = "Bow down to King Pip! Hoot! 👑🦉";
      _triggerPipWiggle(customSpeech: hatMsg);
    });
  }

  void _feedCookie() {
    HapticFeedback.heavyImpact();
    setState(() {
      _happinessPoints += 10;
      _triggerPipWiggle(
        customSpeech: _happinessPoints % 30 == 0
            ? "Mmmm! Crunchy crunch! I'm super happy! 🍪🤤❤️"
            : "Chomp chomp! Best cookie ever! 🍪😋",
      );
      // Spawn crumb particles
      final size = MediaQuery.of(context).size;
      final px = size.width / 2;
      final py = size.height * 0.42;
      for (int i = 0; i < 12; i++) {
        final angle = _random.nextDouble() * pi * 2;
        final speed = _random.nextDouble() * 5 + 3;
        _cookieParticles.add(
          CookieParticle(
            id: _random.nextInt(999999),
            x: px,
            y: py,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed - 2, // slightly upwards
            rotation: _random.nextDouble() * pi,
            opacity: 1.0,
            emoji: _random.nextBool() ? '✨' : '🍪',
          ),
        );
      }
    });
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      // Update music notes
      if (_isRadioOn && _random.nextDouble() < 0.1) {
        final size = MediaQuery.of(context).size;
        // Radio is positioned near the bottom shelf (left side)
        _notes.add(
          MusicalNote(
            id: _random.nextInt(999999),
            x: size.width * 0.22,
            y: size.height * 0.65,
            opacity: 1.0,
            scale: _random.nextDouble() * 0.5 + 0.7,
            noteChar: _notesChars[_random.nextInt(_notesChars.length)],
            speed: _random.nextDouble() * 2 + 1.5,
            wiggleSpeed: _random.nextDouble() * 0.1 + 0.05,
          ),
        );
      }

      for (final note in _notes) {
        note.y -= note.speed;
        note.x += sin(_ambientNoteController.value * note.wiggleSpeed * 100) * 1.2;
        note.opacity = max(0.0, note.opacity - 0.015);
      }
      _notes.removeWhere((n) => n.opacity <= 0.0 || n.y < 0);

      // Update cookie crumbs
      for (final cp in _cookieParticles) {
        cp.x += cp.vx;
        cp.y += cp.vy;
        cp.vy += 0.3; // gravity
        cp.rotation += 0.1;
        cp.opacity = max(0.0, cp.opacity - 0.03);
      }
      _cookieParticles.removeWhere((cp) => cp.opacity <= 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Get background colors based on Day cycle
    List<Color> bgColors;
    String skyEmoji;
    if (_timeOfDay == TimeOfDayCycle.day) {
      bgColors = [const Color(0xffd0e6ff), const Color(0xfff0f7ff)];
      skyEmoji = '☀️';
    } else if (_timeOfDay == TimeOfDayCycle.sunset) {
      bgColors = [const Color(0xfff08d49), const Color(0xff6e3c75)];
      skyEmoji = '🌇';
    } else {
      bgColors = [const Color(0xff0b0e14), const Color(0xff18223c)];
      skyEmoji = '🌙';
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Sky Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Twinkling stars / sun wiggles
          if (_timeOfDay == TimeOfDayCycle.night) ...[
            const Positioned(top: 80, left: 50, child: Text('⭐', style: TextStyle(fontSize: 16))),
            const Positioned(top: 130, right: 80, child: Text('⭐', style: TextStyle(fontSize: 20))),
            const Positioned(top: 220, left: 100, child: Text('⭐', style: TextStyle(fontSize: 14))),
            const Positioned(top: 60, right: 150, child: Text('⭐', style: TextStyle(fontSize: 18))),
          ],

          // Floating background clouds/elements
          AnimatedBuilder(
            animation: _cloudFloatController,
            builder: (context, child) {
              final val = _cloudFloatController.value;
              return Stack(
                children: [
                  Positioned(
                    top: 100,
                    left: (size.width + 120) * val - 120,
                    child: Opacity(
                      opacity: _timeOfDay == TimeOfDayCycle.night ? 0.2 : 0.6,
                      child: const Text('☁️', style: TextStyle(fontSize: 50)),
                    ),
                  ),
                  Positioned(
                    top: 180,
                    right: (size.width + 160) * val - 160,
                    child: Opacity(
                      opacity: _timeOfDay == TimeOfDayCycle.night ? 0.15 : 0.4,
                      child: const Text('☁️', style: TextStyle(fontSize: 70)),
                    ),
                  ),
                ],
              );
            },
          ),

          // Sky Celestial Body (Sun/Moon)
          Positioned(
            top: 70,
            right: 40,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.8, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Text(
                    skyEmoji,
                    style: const TextStyle(fontSize: 60),
                  ),
                );
              },
            ),
          ),

          // 2. Treehouse Structure & Forest Canopy
          Positioned.fill(
            child: CustomPaint(
              painter: TreehouseBackgroundPainter(timeOfDay: _timeOfDay),
            ),
          ),

          // Floating Music Notes
          ..._notes.map((note) {
            return Positioned(
              left: note.x,
              top: note.y,
              child: Opacity(
                opacity: note.opacity,
                child: Transform.scale(
                  scale: note.scale,
                  child: Text(
                    note.noteChar,
                    style: TextStyle(
                      fontSize: 24,
                      color: _timeOfDay == TimeOfDayCycle.night ? Colors.purpleAccent : AppTheme.primary,
                      shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Cookie Crumbs/Sparkle particles
          ..._cookieParticles.map((cp) {
            return Positioned(
              left: cp.x,
              top: cp.y,
              child: Opacity(
                opacity: cp.opacity,
                child: Transform.rotate(
                  angle: cp.rotation,
                  child: Text(
                    cp.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            );
          }),

          // 3. Treehouse Room & Interactive Items Layout
          SafeArea(
            child: Column(
              children: [
                // Custom Top Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BouncyButton(
                        padding: const EdgeInsets.all(12),
                        color: Colors.white,
                        borderColor: AppTheme.borderLight,
                        radius: 20,
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textDark, size: 24),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: AppTheme.playfulCardDecoration(
                          color: Colors.white,
                          borderColor: AppTheme.success,
                          radius: 20,
                        ),
                        child: Row(
                          children: [
                            const Text('❤️', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Text(
                              'Happiness: $_happinessPoints',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final height = constraints.maxHeight;

                      // Treehouse interactive zone positions
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Cozy Wooden Floor & Pillars Visual inside Treehouse
                          Positioned(
                            bottom: height * 0.25,
                            width: min(width * 0.95, 480),
                            height: height * 0.45,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.amber[900]!.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.amber[900]!.withValues(alpha: 0.15), width: 3),
                              ),
                            ),
                          ),

                          // A: Tappable Window (on the wall)
                          Positioned(
                            top: height * 0.34,
                            right: width * 0.16,
                            child: BouncyButton(
                              padding: const EdgeInsets.all(8),
                              color: Colors.brown[300]!,
                              borderColor: Colors.brown[700]!,
                              radius: 12,
                              borderWidth: 3.5,
                              onTap: _cycleTimeOfDay,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: bgColors.first.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Stack(
                                  children: [
                                    const Center(child: Text('🖼️', style: TextStyle(fontSize: 24))),
                                    if (_timeOfDay == TimeOfDayCycle.night)
                                      Container(
                                        color: Colors.indigo.withValues(alpha: 0.3),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // B: Tappable Hanging Lantern (top middle-left)
                          Positioned(
                            top: height * 0.26,
                            left: width * 0.18,
                            child: GestureDetector(
                              onTap: _toggleLantern,
                              child: Column(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 40,
                                    color: Colors.brown[800],
                                  ),
                                  Transform.scale(
                                    scale: _isLanternOn ? 1.15 : 1.0,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _isLanternOn ? Colors.yellow[100] : Colors.grey[700],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isLanternOn ? Colors.yellow[600]! : Colors.grey[900]!,
                                          width: 3.5,
                                        ),
                                        boxShadow: _isLanternOn
                                            ? [
                                                BoxShadow(
                                                  color: Colors.yellow[400]!.withValues(alpha: 0.8),
                                                  blurRadius: 18,
                                                  spreadRadius: 4,
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        _isLanternOn ? '💡' : '🔌',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // C: Tappable Music Radio (bottom-left)
                          Positioned(
                            bottom: height * 0.26,
                            left: width * 0.12,
                            child: BouncyButton(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              color: _isRadioOn ? Colors.red[300] : Colors.grey[400],
                              borderColor: _isRadioOn ? Colors.red[700]! : Colors.grey[600]!,
                              radius: 16,
                              onTap: _toggleRadio,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_isRadioOn ? '📻' : '📻', style: const TextStyle(fontSize: 26)),
                                  if (_isRadioOn) ...[
                                    const SizedBox(width: 6),
                                    const Text(
                                      '⚡',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.yellow,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ),

                          // D: Pip the Owl (Center Stage)
                          Positioned(
                            bottom: height * 0.32,
                            child: DragTarget<String>(
                              onAcceptWithDetails: (details) {
                                if (details.data == 'cookie') {
                                  _feedCookie();
                                }
                              },
                              builder: (context, candidateData, rejectedData) {
                                final isOver = candidateData.isNotEmpty;
                                return GestureDetector(
                                  onTap: () => _triggerPipWiggle(),
                                  child: TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 300),
                                    tween: Tween(begin: 1.0, end: _isPipWiggling ? 0.9 : (isOver ? 1.12 : 1.0)),
                                    curve: Curves.elasticOut,
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          clipBehavior: Clip.none,
                                          children: [
                                            // Pip body layout
                                            _buildPipBody(),
                                            // Hat overlay
                                            if (_selectedHatIndex > 0)
                                              Positioned(
                                                top: -46,
                                                child: _buildHatWidget(_selectedHatIndex),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                          // E: Speech Bubble (Floating above Pip)
                          if (_showSpeechBubble)
                            Positioned(
                              bottom: height * 0.54,
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 400),
                                tween: Tween(begin: 0.0, end: 1.0),
                                curve: Curves.elasticOut,
                                builder: (context, val, child) {
                                  return Opacity(
                                    opacity: min(1.0, val),
                                    child: Transform.scale(
                                      scale: val,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 16),
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                        constraints: BoxConstraints(maxWidth: min(size.width * 0.75, 280)),
                                        decoration: AppTheme.playfulCardDecoration(
                                          color: Colors.white,
                                          borderColor: AppTheme.primary,
                                          radius: 20,
                                          borderWidth: 3.5,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _pipSpeech,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textDark,
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

                          // F: Shelf with Cookie drawer (bottom tray)
                          Positioned(
                            bottom: height * 0.16,
                            width: min(width * 0.9, 400),
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.brown[600],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.brown[800]!, width: 2.5),
                              ),
                            ),
                          ),

                          // Shelf Cookies
                          Positioned(
                            bottom: height * 0.08,
                            width: min(width * 0.9, 360),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Left side: Cookie feeding bowl / jar
                                _buildDraggableCookie(),
                                
                                // Right side: Hats selector tray
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: AppTheme.playfulCardDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderColor: Colors.brown[400]!,
                                    radius: 18,
                                    borderWidth: 2.5,
                                    showShadow: false,
                                  ),
                                  child: Row(
                                    children: [
                                      _buildHatButton(0, '❌'),
                                      const SizedBox(width: 8),
                                      _buildHatButton(1, '🤠'),
                                      const SizedBox(width: 8),
                                      _buildHatButton(2, '🧙‍♂️'),
                                      const SizedBox(width: 8),
                                      _buildHatButton(3, '👑'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Dark Overlay if Lantern is OFF & Night mode
          if (!_isLanternOn && _timeOfDay == TimeOfDayCycle.night)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.indigo[900]!.withValues(alpha: 0.4),
                ),
              ),
            ),

          // Warm Ambient Glow Overlay if Lantern is ON
          if (_isLanternOn)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber[100]!.withValues(alpha: 0.25),
                        Colors.transparent
                      ],
                      center: const Alignment(-0.5, -0.2), // aligned with lantern
                      radius: 0.9,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Draggable Cookie Item
  Widget _buildDraggableCookie() {
    final cookieWidget = Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xfffbe9e7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.brown[400]!, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(0, 3), blurRadius: 2)
        ],
      ),
      alignment: Alignment.center,
      child: const Text('🍪', style: TextStyle(fontSize: 32)),
    );

    return Draggable<String>(
      data: 'cookie',
      feedback: Transform.scale(
        scale: 1.15,
        child: Material(
          color: Colors.transparent,
          child: cookieWidget,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: cookieWidget,
      ),
      child: cookieWidget,
    );
  }

  // Hat Selector Button
  Widget _buildHatButton(int index, String hatEmoji) {
    final isSelected = _selectedHatIndex == index;
    return GestureDetector(
      onTap: () => _changeHat(index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          hatEmoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  // Build the detailed, vector-like Pip Owl
  Widget _buildPipBody() {
    return Container(
      width: 120,
      height: 130,
      decoration: BoxDecoration(
        color: AppTheme.primary, // Soft purple body
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(55),
          topRight: Radius.circular(55),
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        border: Border.all(color: const Color(0xff4a3fff), width: 4.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tufts/Ears (Left & Right top corners)
          Positioned(
            top: -2,
            left: 10,
            child: Transform.rotate(
              angle: -0.2,
              child: _buildEarTuft(),
            ),
          ),
          Positioned(
            top: -2,
            right: 10,
            child: Transform.rotate(
              angle: 0.2,
              child: _buildEarTuft(),
            ),
          ),

          // Big cute white belly
          Positioned(
            bottom: 6,
            child: Container(
              width: 82,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xfffff9db),
                borderRadius: BorderRadius.circular(38),
                border: Border.all(color: Colors.amber[200]!, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFeatherPattern(),
                      const SizedBox(width: 8),
                      _buildFeatherPattern(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildFeatherPattern(),
                ],
              ),
            ),
          ),

          // Wing Left
          Positioned(
            left: -12,
            top: 40,
            child: Transform.rotate(
              angle: 0.25,
              child: Container(
                width: 26,
                height: 55,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xff4a3fff), width: 3.5),
                ),
              ),
            ),
          ),

          // Wing Right
          Positioned(
            right: -12,
            top: 40,
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 26,
                height: 55,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xff4a3fff), width: 3.5),
                ),
              ),
            ),
          ),

          // Big eyes container row
          Positioned(
            top: 22,
            child: Row(
              children: [
                _buildEye(),
                const SizedBox(width: 6),
                _buildEye(),
              ],
            ),
          ),

          // Beak (in the center)
          Positioned(
            top: 48,
            child: CustomPaint(
              size: const Size(20, 16),
              painter: OrangeBeakPainter(),
            ),
          ),

          // Tiny orange feet (peeking out bottom)
          Positioned(
            bottom: -8,
            left: 28,
            child: _buildFoot(),
          ),
          Positioned(
            bottom: -8,
            right: 28,
            child: _buildFoot(),
          ),
        ],
      ),
    );
  }

  Widget _buildEarTuft() {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFeatherPattern() {
    return Text(
      '^',
      style: TextStyle(
        fontSize: 16,
        color: Colors.amber[700]!,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xff4a3fff), width: 3.5),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AppTheme.textDark,
          shape: BoxShape.circle,
        ),
        alignment: const Alignment(-0.35, -0.35),
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildFoot() {
    return Container(
      width: 18,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.orange[600],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange[800]!, width: 2),
      ),
    );
  }

  // Draw customized hats to overlay
  Widget _buildHatWidget(int type) {
    if (type == 1) {
      // Explorer Hat
      return Column(
        children: [
          Container(
            width: 90,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.yellow[800],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.brown[900]!, width: 2.5),
            ),
          ),
          Container(
            width: 58,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.yellow[700],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: Colors.brown[900]!, width: 2.5),
            ),
          ),
        ],
      );
    } else if (type == 2) {
      // Wizard Hat
      return SizedBox(
        width: 80,
        height: 58,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Hat Brim
            Container(
              width: 90,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.indigo[800],
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.indigo[900]!, width: 2.5),
              ),
            ),
            // Cone
            Positioned(
              bottom: 4,
              child: CustomPaint(
                size: const Size(60, 48),
                painter: WizardConePainter(),
              ),
            ),
            // Glowing star
            const Positioned(
              bottom: 22,
              child: Text(
                '⭐',
                style: TextStyle(fontSize: 14, color: Colors.yellow),
              ),
            )
          ],
        ),
      );
    } else if (type == 3) {
      // Crown
      return SizedBox(
        width: 80,
        height: 38,
        child: CustomPaint(
          size: const Size(70, 32),
          painter: CrownPainter(),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// Custom Painter to draw Beak
class OrangeBeakPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange[600]!
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.orange[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter to draw Wizard cone
class WizardConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.indigo[800]!
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.indigo[900]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter to draw Golden Crown
class CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber[500]!
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.amber[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.9, size.height * 0.2)
      ..lineTo(size.width * 0.7, size.height * 0.65)
      ..lineTo(size.width * 0.5, size.height * 0.1)
      ..lineTo(size.width * 0.3, size.height * 0.65)
      ..lineTo(size.width * 0.1, size.height * 0.2)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Gem stones
    final gemPaint1 = Paint()..color = Colors.redAccent;
    final gemPaint2 = Paint()..color = Colors.blueAccent;
    final gemPaint3 = Paint()..color = Colors.greenAccent;

    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 3, gemPaint1);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.1), 3.5, gemPaint2);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 3, gemPaint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for beautiful cartoon Treehouse Background
class TreehouseBackgroundPainter extends CustomPainter {
  final TimeOfDayCycle timeOfDay;

  TreehouseBackgroundPainter({required this.timeOfDay});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw large green canopy behind the room
    final leafPaint = Paint();
    if (timeOfDay == TimeOfDayCycle.day) {
      leafPaint.color = Colors.green[600]!;
    } else if (timeOfDay == TimeOfDayCycle.sunset) {
      leafPaint.color = const Color(0xff537a44);
    } else {
      leafPaint.color = const Color(0xff1d3019);
    }



    // Drawing multiple cloud-like green bubbles for leaves
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.35), size.width * 0.32, leafPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.35), size.width * 0.32, leafPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.24), size.width * 0.36, leafPaint);
    
    // 2. Draw thick wooden branches w/ trunk
    final branchPaint = Paint();
    if (timeOfDay == TimeOfDayCycle.day) {
      branchPaint.color = Colors.brown[700]!;
    } else if (timeOfDay == TimeOfDayCycle.sunset) {
      branchPaint.color = const Color(0xff573e33);
    } else {
      branchPaint.color = const Color(0xff2b201a);
    }

    final trunkPath = Path()
      ..moveTo(size.width * 0.4, size.height)
      ..lineTo(size.width * 0.44, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.58, size.width * 0.1, size.height * 0.62)
      ..lineTo(size.width * 0.08, size.height * 0.68)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.63, size.width * 0.42, size.height * 0.73)
      ..lineTo(size.width * 0.42, size.height)
      ..close();
    canvas.drawPath(trunkPath, branchPaint);

    final trunkPathRight = Path()
      ..moveTo(size.width * 0.58, size.height)
      ..lineTo(size.width * 0.54, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.54, size.width * 0.92, size.height * 0.58)
      ..lineTo(size.width * 0.94, size.height * 0.64)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.59, size.width * 0.56, size.height * 0.71)
      ..lineTo(size.width * 0.56, size.height)
      ..close();
    canvas.drawPath(trunkPathRight, branchPaint);

    // 3. Draw cozy ladder w/ rungs
    final ladderPaint = Paint()
      ..color = Colors.amber[900]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    final ladderLeftX = size.width * 0.45;
    final ladderRightX = size.width * 0.53;
    final ladderTopY = size.height * 0.72;
    final ladderBottomY = size.height;

    canvas.drawLine(Offset(ladderLeftX, ladderTopY), Offset(ladderLeftX, ladderBottomY), ladderPaint);
    canvas.drawLine(Offset(ladderRightX, ladderTopY), Offset(ladderRightX, ladderBottomY), ladderPaint);

    // Ladder rungs
    final rungPaint = Paint()
      ..color = Colors.amber[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    double currentRungY = ladderTopY + 18;
    while (currentRungY < ladderBottomY - 10) {
      canvas.drawLine(Offset(ladderLeftX, currentRungY), Offset(ladderRightX, currentRungY), rungPaint);
      currentRungY += 24;
    }
  }

  @override
  bool shouldRepaint(covariant TreehouseBackgroundPainter oldDelegate) =>
      oldDelegate.timeOfDay != timeOfDay;
}
