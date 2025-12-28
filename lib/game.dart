import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAfKnSzI9hvxYChHVvdjLMw8im13f1yTi4",
      authDomain: "zenly-acaec.firebaseapp.com",
      projectId: "zenly-acaec",
      storageBucket: "zenly-acaec.appspot.com",
      messagingSenderId: "628716450868",
      appId: "1:628716450868:web:a5b5cb5f94bc3c003d4661",
      measurementId: "G-0TLZQDDYS6",
    ),
  );
  runApp(const ZenlyApp());
}

class ZenlyApp extends StatelessWidget {
  const ZenlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4A90E2),
        // Default background is now dark for the entry screens
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const SplashScreen(),
    );
  }
}

// --- SPLASH & LOGIN (BLACK BACKGROUND) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ZenGardenScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black, // Dark background
      body: Center(
        child: Text(
          "Zenly",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white, // White text on black
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white, // White button
            foregroundColor: Colors.black, // Black text on button
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: () async {
            await FirebaseAuth.instance.signInAnonymously();
            if (!context.mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ZenGardenScreen()));
          },
          child: const Text("Enter Zen Space", style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

// --- ZEN GARDEN ENGINE ---
class ZenGardenScreen extends StatefulWidget {
  const ZenGardenScreen({super.key});
  @override
  State<ZenGardenScreen> createState() => _ZenGardenScreenState();
}

enum ZenMode { water, sand }

class _ZenGardenScreenState extends State<ZenGardenScreen> with TickerProviderStateMixin {
  ZenMode _currentMode = ZenMode.water;
  final List<RippleModel> _ripples = [];
  final List<SandLine> _sandLines = [];

  final AudioPlayer _waterPlayer = AudioPlayer();
  final AudioPlayer _sandPlayer = AudioPlayer();
  Timer? _waterCutTimer;

  @override
  void initState() {
    super.initState();
    _sandPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _waterCutTimer?.cancel();
    _waterPlayer.dispose();
    _sandPlayer.dispose();
    super.dispose();
  }

  void _toggleMode(ZenMode mode) {
    try {
      _sandPlayer.stop();
    } catch (_) {}
    setState(() {
      _currentMode = mode;
      _ripples.clear();
      _sandLines.clear();
    });
  }

  void _handlePointer(PointerEvent details) {
    if (_currentMode == ZenMode.water) {
      if (details is PointerDownEvent) {
        _addRipple(details.localPosition);
        _playWaterSound();
      }
    } else {
      if (details is PointerMoveEvent) {
        _addSandPoint(details.localPosition);
        _playSandSound(true);
      } else if (details is PointerUpEvent || details is PointerCancelEvent) {
        _playSandSound(false);
        _finishSandLine();
      }
    }
  }

  // Plays sound and stops after first droplet (Clipped to ~500ms)
  Future<void> _playWaterSound() async {
    try {
      _waterCutTimer?.cancel();
      await _waterPlayer.stop();
      await _waterPlayer.play(AssetSource('audio/water.mp3'), volume: 0.5);

      _waterCutTimer = Timer(const Duration(milliseconds: 500), () async {
        await _waterPlayer.stop();
      });
    } catch (e) {
      debugPrint("Water sound error: $e");
    }
  }

  Future<void> _playSandSound(bool playing) async {
    try {
      if (playing) {
        if (_sandPlayer.state != PlayerState.playing) {
          await _sandPlayer.play(AssetSource('audio/sand.mp3'), volume: 0.3);
        }
      } else {
        if (_sandPlayer.state == PlayerState.playing) {
          await _sandPlayer.pause();
        }
      }
    } catch (e) {
      debugPrint("Sand sound handled: $e");
    }
  }

  void _addRipple(Offset pos) {
    final controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    final ripple = RippleModel(position: pos, animation: controller);
    setState(() => _ripples.add(ripple));
    controller.forward().then((_) {
      if (!mounted) return;
      setState(() => _ripples.remove(ripple));
      controller.dispose();
    });
  }

  void _addSandPoint(Offset pos) {
    setState(() {
      if (_sandLines.isEmpty || _sandLines.last.isFinished) {
        _sandLines.add(SandLine(points: [pos]));
      } else {
        _sandLines.last.points.add(pos);
      }
    });
  }

  void _finishSandLine() {
    if (_sandLines.isNotEmpty && !_sandLines.last.isFinished) {
      final lastLine = _sandLines.last;
      lastLine.isFinished = true;
      Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() {
          lastLine.opacity -= 0.02;
          if (lastLine.opacity <= 0) {
            _sandLines.remove(lastLine);
            t.cancel();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We override the scaffold background here for the Garden Screen
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text("Zenly Garden", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Listener(
            onPointerDown: _handlePointer,
            onPointerMove: _handlePointer,
            onPointerUp: _handlePointer,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              color: _currentMode == ZenMode.water ? const Color(0xFFB2EBF2) : const Color(0xFFE6D5B8),
              child: AnimatedBuilder(
                animation: Listenable.merge(_ripples.map((r) => r.animation).toList()),
                builder: (context, _) {
                  return CustomPaint(
                    painter: ZenPainter(mode: _currentMode, ripples: _ripples, lines: _sandLines),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 50,
            right: 50,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _modeButton("🌊 Water", ZenMode.water),
                  _modeButton("⏳ Sand", ZenMode.sand),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String label, ZenMode mode) {
    final bool active = _currentMode == mode;
    return GestureDetector(
      onTap: () => _toggleMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// --- PAINTER & MODELS ---
class ZenPainter extends CustomPainter {
  final ZenMode mode;
  final List<RippleModel> ripples;
  final List<SandLine> lines;
  ZenPainter({required this.mode, required this.ripples, required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    if (mode == ZenMode.water) {
      for (final r in ripples) {
        final double p = r.animation.value;
        final Paint paint = Paint()
          ..color = Colors.blue.withOpacity((1 - p) * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(r.position, p * 150, paint);
      }
    } else {
      for (final line in lines) {
        final Paint paint = Paint()
          ..color = const Color(0xFFBCA37F).withOpacity(line.opacity.clamp(0, 1))
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 20
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        for (int i = 0; i < line.points.length - 1; i++) {
          canvas.drawLine(line.points[i], line.points[i + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RippleModel {
  final Offset position;
  final AnimationController animation;
  RippleModel({required this.position, required this.animation});
}

class SandLine {
  final List<Offset> points;
  double opacity = 1.0;
  bool isFinished = false;
  SandLine({required this.points});
}