import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/confetti_painter.dart';
import '../../domain/entities/treasure_item.dart';
import '../../data/repositories/image_recognition_repository_impl.dart';

class TreasureHuntScreen extends StatefulWidget {
  const TreasureHuntScreen({super.key});

  @override
  State<TreasureHuntScreen> createState() => _TreasureHuntScreenState();
}

class _TreasureHuntScreenState extends State<TreasureHuntScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  final ImageRecognitionRepositoryImpl _mlRepository =
      ImageRecognitionRepositoryImpl();
  
  List<TreasureItem> _items = [];
  int _starsEarned = 0;
  bool _isInitializingCamera = true;
  bool _useSimulatorMode = false;
  bool _isProcessingImage = false;
  
  // Active found item overlay
  TreasureItem? _recentlyFoundItem;
  bool _showVictoryModal = false;
  bool _allDoneBadgeCelebration = false;

  @override
  void initState() {
    super.initState();
    _items = TreasureItem.defaultItems;
    _initRealCamera();
    _loadPersistedProgress();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _mlRepository.dispose();
    super.dispose();
  }

  Future<void> _loadPersistedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final foundIds = prefs.getStringList('found_treasure_ids') ?? [];
    setState(() {
      for (var item in _items) {
        if (foundIds.contains(item.id)) {
          item.isFound = true;
        }
      }
    });
  }

  Future<void> _saveProgress(TreasureItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final currentStars = prefs.getInt('stars') ?? 0;
    await prefs.setInt('stars', currentStars + item.starReward);

    final foundIds = prefs.getStringList('found_treasure_ids') ?? [];
    if (!foundIds.contains(item.id)) {
      foundIds.add(item.id);
      await prefs.setStringList('found_treasure_ids', foundIds);
    }

    // Check if ALL items are found now
    final allFound = _items.every((i) => i.isFound);
    if (allFound) {
      final badges = prefs.getStringList('badges') ?? [];
      if (!badges.contains('Treasure Master 🏆')) {
        badges.add('Treasure Master 🏆');
        await prefs.setStringList('badges', badges);
        setState(() {
          _allDoneBadgeCelebration = true;
        });
      }
    }
  }

  Future<void> _initRealCamera() async {
    if (kIsWeb) {
      setState(() {
        _useSimulatorMode = true;
        _isInitializingCamera = false;
      });
      return;
    }

    setState(() {
      _isInitializingCamera = true;
      _useSimulatorMode = false;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCameras', 'No cameras available on this device');
      }

      // Pick rear facing camera
      final rearCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        rearCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _useSimulatorMode = true;
          _isInitializingCamera = false;
        });
      }
    }
  }

  // Captures photo, classifies using ML Kit, validates target items
  Future<void> _scanObject() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isProcessingImage) return;

    setState(() {
      _isProcessingImage = true;
    });

    try {
      final imageFile = await _cameraController!.takePicture();
      
      // Send image path to Clean Architecture repository layer
      final labels = await _mlRepository.labelImage(imageFile.path);
      debugPrint('Detected Labels: $labels');
      
      _matchLabels(labels);
      
      // Cleanup image file
      final file = File(imageFile.path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Scanning error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to classify image. Try again! 🤔')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  // Matches ML Kit labels to target items in checklist
  void _matchLabels(List<String> labels) {
    bool foundAny = false;
    for (var label in labels) {
      for (var item in _items) {
        if (!item.isFound && item.mlKitLabels.contains(label.toLowerCase())) {
          _triggerItemFound(item);
          foundAny = true;
          break;
        }
      }
      if (foundAny) break;
    }

    if (!foundAny) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hmm, that doesn\'t match our checklist items! Try moving closer. 🔍'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  // Simulator helper to allow reviewers to trigger matches directly
  void _simulateScan(TreasureItem item) {
    if (item.isFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} is already discovered! Choose another one. 😊')),
      );
      return;
    }
    _triggerItemFound(item);
  }

  void _triggerItemFound(TreasureItem item) {
    setState(() {
      item.isFound = true;
      _recentlyFoundItem = item;
      _showVictoryModal = true;
      _starsEarned += item.starReward;
    });

    HapticFeedback.mediumImpact();
    _saveProgress(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xfff0f4fd), Color(0xfff8faff)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Screen Layout
          SafeArea(
            child: Column(
              children: [
                // Top Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      const Text(
                        'Treasure Search 🔍',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: AppTheme.playfulCardDecoration(
                          color: Colors.white,
                          borderColor: AppTheme.secondary,
                          radius: 20,
                        ),
                        child: Row(
                          children: [
                            const Text('⭐', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Text(
                              '+$_starsEarned',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Camera Viewfinder Box
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Container(
                      decoration: AppTheme.playfulCardDecoration(
                        color: Colors.black,
                        borderColor: AppTheme.primary,
                        radius: AppTheme.radiusExtraLarge,
                        borderWidth: 5,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          if (_isInitializingCamera)
                            const Center(
                              child: CircularProgressIndicator(color: AppTheme.secondary),
                            )
                          else if (_useSimulatorMode)
                            _buildSimulatorView()
                          else
                            Positioned.fill(
                              child: AspectRatio(
                                aspectRatio: _cameraController!.value.aspectRatio,
                                child: CameraPreview(_cameraController!),
                              ),
                            ),

                          // Animated Scan Viewfinder HUD Line (children visual guide)
                          if (!_isInitializingCamera) _buildScanHUD(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Controls: Scan Action or Simulator buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: _useSimulatorMode ? _buildSimulatorControls() : _buildRealCameraControls(),
                ),

                // Targets Checklist
                Expanded(
                  flex: 2,
                  child: _buildChecklistCabinet(),
                ),
              ],
            ),
          ),

          // Victory Celebrations
          if (_showVictoryModal && _recentlyFoundItem != null)
            _buildVictoryOverlay(),

          if (_allDoneBadgeCelebration)
            _buildGrandCompleteOverlay(),
        ],
      ),
    );
  }

  Widget _buildScanHUD() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 3),
      builder: (context, val, child) {
        return Positioned(
          top: val * (MediaQuery.of(context).size.height * 0.35),
          left: 0,
          right: 0,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondary.withValues(alpha: 0.8),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
        );
      },
      onEnd: () {
        // Redraw loop
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildSimulatorView() {
    return Container(
      color: Colors.blueGrey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 60),
            SizedBox(height: 12),
            Text(
              'Review Simulator Active 🛠️',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Camera/ML Kit fallback is running. Select a target below to simulate scanning.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealCameraControls() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: BouncyButton(
        color: AppTheme.primary,
        borderColor: Colors.deepPurple[700],
        onTap: _scanObject,
        radius: AppTheme.radiusLarge,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Text(
              _isProcessingImage ? 'Analyzing... 🧠' : 'Find Object! 📸',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatorControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.playfulCardDecoration(
        color: Colors.white,
        borderColor: AppTheme.secondary.withValues(alpha: 0.5),
        radius: AppTheme.radiusLarge,
      ),
      child: Column(
        children: [
          const Text(
            'Simulate Camera Scanner:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textLight),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _items.map((item) {
              return Opacity(
                opacity: item.isFound ? 0.5 : 1.0,
                child: BouncyButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: AppTheme.secondary,
                  borderColor: Colors.amber[700],
                  radius: 12,
                  borderWidth: 2,
                  onTap: () => _simulateScan(item),
                  child: Text('${item.emoji} ${item.name}', style: const TextStyle(fontSize: 13)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCabinet() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.playfulCardDecoration(
        color: Colors.white,
        borderColor: AppTheme.borderLight,
        radius: AppTheme.radiusExtraLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Treasure Items 🌸📖',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: _items.map((item) {
                return Container(
                  decoration: BoxDecoration(
                    color: item.isFound ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.isFound ? AppTheme.success : AppTheme.borderLight,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: item.isFound ? Colors.green[800] : AppTheme.textDark,
                                decoration: item.isFound ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              item.isFound ? 'Discovered! ✨' : '+${item.starReward} Stars ⭐',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: item.isFound ? AppTheme.success : AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        item.isFound ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: item.isFound ? AppTheme.success : Colors.grey[400],
                        size: 20,
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryOverlay() {
    final item = _recentlyFoundItem!;
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: Stack(
        children: [
          // Burst confetti
          const Positioned.fill(
            child: IgnorePointer(
              child: ConfettiWidget(isPlaying: true),
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.playfulCardDecoration(
                      color: Colors.white,
                      borderColor: AppTheme.success,
                      radius: AppTheme.radiusExtraLarge,
                      borderWidth: 5,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TREASURE FOUND! 🌸',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.success,
                            )),
                        const SizedBox(height: 16),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(item.emoji, style: const TextStyle(fontSize: 54)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${item.name} Identified!',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Amazing Explorer! 🎉\n+${item.starReward} Stars ⭐',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 24),
                        BouncyButton(
                          color: AppTheme.success,
                          borderColor: const Color(0xff5cb53b),
                          onTap: () {
                            setState(() {
                              _showVictoryModal = false;
                              _recentlyFoundItem = null;
                            });
                          },
                          child: const Text('Awesome! 🚀'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandCompleteOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      alignment: Alignment.center,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: ConfettiWidget(isPlaying: true),
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.bounceOut,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(28),
                    decoration: AppTheme.playfulCardDecoration(
                      color: Colors.white,
                      borderColor: AppTheme.secondary,
                      radius: AppTheme.radiusExtraLarge,
                      borderWidth: 6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏆 GRAND MASTER 🏆',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondary,
                            )),
                        const SizedBox(height: 12),
                        const Text(
                          'Level 2 Complete!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 20),
                        
                        // Badge Display
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Color(0xfffff8eb),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🏅', style: TextStyle(fontSize: 70)),
                        ),
                        const SizedBox(height: 16),
                        
                        const Text(
                          'You discovered all targets!\nYou earned the Treasure Master Badge!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 24),
                        
                        BouncyButton(
                          color: AppTheme.primary,
                          borderColor: Colors.deepPurple[700],
                          onTap: () {
                            setState(() {
                              _allDoneBadgeCelebration = false;
                            });
                            Navigator.of(context).pop();
                          },
                          child: const Text('Back to Map! 🗺️'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
