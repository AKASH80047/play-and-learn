import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_button.dart';
import '../balloon_pop/balloon_pop_screen.dart';
import '../treasure_hunt/treasure_hunt_screen.dart';
import '../treehouse/treehouse_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _stars = 0;
  List<String> _badges = [];
  late AnimationController _cloudController;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stars = prefs.getInt('stars') ?? 0;
      _badges = prefs.getStringList('badges') ?? [];
    });
  }

  Future<void> _resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _loadProgress();
  }

  void _showParentGate() {
    final num1 = Random().nextInt(7) + 3;
    final num2 = Random().nextInt(6) + 3;
    final correctAnswer = num1 + num2;
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            side: const BorderSide(color: AppTheme.secondary, width: 4),
          ),
          title: Row(
            children: const [
              Text('🔒 Parents Only!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please solve to enter:\nWhat is $num1 + $num2?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Answer',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                final val = int.tryParse(textController.text);
                if (val == correctAnswer) {
                  Navigator.of(context).pop();
                  _showSettingsMenu();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Oops! That is not correct. Try again! 🤔'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Enter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusExtraLarge)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Parent Control Center ⚙️',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Reset child statistics, view metrics, and manage screen timeouts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLight),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.redAccent, size: 28),
                title: const Text('Reset Game Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Clears all stars and badges earned'),
                onTap: () {
                  Navigator.of(context).pop();
                  _resetProgress();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progress has been reset! 🧹')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                title: const Text('Add 50 Stars (Testing)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Instantly awards 50 stars to unlock Level 3'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final prefs = await SharedPreferences.getInstance();
                  final currentStars = prefs.getInt('stars') ?? 0;
                  await prefs.setInt('stars', currentStars + 50);
                  if (!context.mounted) return;
                  _loadProgress();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Awarded 50 Stars! 🏡⭐')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.analytics_outlined, color: AppTheme.primary, size: 28),
                title: const Text('Task 3 Insights: Retention Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('View the 2-minute drop-off dashboard metrics'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAnalyticsReport();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showAnalyticsReport() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          title: const Text('Retention Hack Dashboard 📊'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Goal: Reduce 2-min drop-offs',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                SizedBox(height: 8),
                Text('• D1 Target: 45% (was 15%)\n• Touch Targets: 48dp+ for motor success\n• Gamified Session Gate: 5-minute soft shutoff to fuel curiosity and anticipation for the next day.'),
                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 8),
                Text('Active Stats:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• Current Session Stars: Saved in memory\n• Target Onboarding Flow: 0-Text Tutorial'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Soft playful sky gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffe3edff), Color(0xfff5f8ff)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Cloud layers scrolling automatically
          AnimatedBuilder(
            animation: _cloudController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: 80,
                    left: (size.width + 150) * _cloudController.value - 150,
                    child: Opacity(
                      opacity: 0.5,
                      child: const Text('☁️', style: TextStyle(fontSize: 60)),
                    ),
                  ),
                  Positioned(
                    top: 220,
                    right: (size.width + 200) * _cloudController.value - 200,
                    child: Opacity(
                      opacity: 0.4,
                      child: const Text('☁️', style: TextStyle(fontSize: 80)),
                    ),
                  ),
                ],
              );
            },
          ),

          // Scrollable adventure map
          SafeArea(
            child: Column(
              children: [
                // Redesigned Top Header Card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: AppTheme.playfulCardDecoration(
                      color: Colors.white,
                      borderColor: const Color(0xffc5d3f0),
                      radius: AppTheme.radiusLarge,
                      borderWidth: 3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Side: Child profile / Star tracker
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('🐼', style: TextStyle(fontSize: 26)),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pip\'s Friend', style: TextStyle(fontSize: 14, color: AppTheme.textLight, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    const Text('⭐', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_stars Stars',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Center: App title
                        const Text(
                          'Sprout Land 🌳',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),

                        // Right: Parents Gate Button
                        BouncyButton(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          color: AppTheme.secondary,
                          borderColor: Colors.amber[800],
                          radius: 18,
                          borderWidth: 3,
                          onTap: _showParentGate,
                          child: Row(
                            children: const [
                              Icon(Icons.security, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Parents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Scrollable Map
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          const Text(
                            'Tiny Explorer Trail 🗺️',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textLight, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 24),

                          // Node 1: Magic Balloon Pop (Gradient, Material Icon)
                          _buildLevelNode(
                            title: 'Level 1: Balloon Pop',
                            subtitle: 'Pop color bubbles & win stars!',
                            icon: Icons.games_rounded,
                            iconColor: const Color(0xffff5a5f),
                            cardGradient: const LinearGradient(
                              colors: [AppTheme.primary, Color(0xff8a82ff)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderColor: const Color(0xff574eff),
                            isUnlocked: true,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MagicBalloonPopScreen(),
                                ),
                              );
                              _loadProgress();
                            },
                          ),

                          _buildPathDots(leftBias: true),

                          // Node 2: Treasure Hunt Kids
                          _buildLevelNode(
                            title: 'Level 2: Camera Search',
                            subtitle: 'Identify target items around you!',
                            icon: Icons.camera_alt_rounded,
                            iconColor: const Color(0xff3bb3ab),
                            cardGradient: const LinearGradient(
                              colors: [AppTheme.accent, Color(0xff67e5dd)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderColor: const Color(0xff36b3ab),
                            isUnlocked: true,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TreasureHuntScreen(),
                                ),
                              );
                              _loadProgress();
                            },
                          ),

                          _buildPathDots(leftBias: false),

                          // Node 3: Locked sandbox
                          _buildLevelNode(
                            title: 'Level 3: Pip\'s Treehouse',
                            subtitle: _stars >= 50
                                ? 'Welcome back to the treehouse! 🏡🌳'
                                : 'Requires 50 Stars to open!',
                            icon: _stars >= 50
                                ? Icons.cabin_rounded
                                : Icons.lock_rounded,
                            iconColor: _stars >= 50
                                ? const Color(0xff5cb53b)
                                : Colors.grey[600]!,
                            cardGradient: _stars >= 50
                                ? const LinearGradient(
                                    colors: [Color(0xff4caf50), Color(0xff81c784)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [Colors.grey[400]!, Colors.grey[300]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderColor: _stars >= 50
                                ? const Color(0xff3d8b40)
                                : Colors.grey[500]!,
                            isUnlocked: _stars >= 50,
                            onTap: () async {
                              if (_stars >= 50) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PipsTreehouseScreen(),
                                  ),
                                );
                                _loadProgress();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Collect 50 stars to unlock Pip\'s Treehouse! 🏡⭐'),
                                    backgroundColor: AppTheme.primary,
                                  ),
                                );
                              }
                            },
                          ),
                          
                          const SizedBox(height: 36),
                          _buildBadgeCabinet(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelNode({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Gradient cardGradient,
    required Color borderColor,
    required bool isUnlocked,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      width: min(440, MediaQuery.of(context).size.width - 48),
      child: BouncyButton(
        color: cardGradient.colors.first, // Fallback color
        borderColor: borderColor,
        radius: AppTheme.radiusLarge,
        borderWidth: 4,
        padding: EdgeInsets.zero, // Padding handled inside Container for gradients
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: cardGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 4),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Avatar circle with reliable Material Icon
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      offset: const Offset(0, 4),
                      blurRadius: 0,
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 2,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPathDots({required bool leftBias}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment:
            leftBias ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.28,
            ),
            child: Column(
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCabinet() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(22),
      width: min(440, MediaQuery.of(context).size.width - 48),
      decoration: AppTheme.playfulCardDecoration(
        borderColor: const Color(0xffc5d3f0),
        radius: AppTheme.radiusLarge,
        borderWidth: 3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Text(
                'My Badge Album 🏆',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_badges.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No badges collected yet. Finish activities to unlock stickers! 🏅',
                  style: TextStyle(color: AppTheme.textLight, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _badges.map((badgeName) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xfffff4e6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.secondary, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondary.withValues(alpha: 0.2),
                        offset: const Offset(0, 3),
                        blurRadius: 0,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏅', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        badgeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
