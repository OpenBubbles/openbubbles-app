import 'dart:async';
import 'dart:math';

import 'package:bluebubbles/app/animations/balloon_classes.dart';
import 'package:bluebubbles/app/animations/balloon_rendering.dart';
import 'package:bluebubbles/app/animations/celebration_class.dart';
import 'package:bluebubbles/app/animations/celebration_rendering.dart';
import 'package:bluebubbles/app/animations/fireworks_classes.dart';
import 'package:bluebubbles/app/animations/fireworks_rendering.dart';
import 'package:bluebubbles/app/animations/laser_classes.dart';
import 'package:bluebubbles/app/animations/laser_rendering.dart';
import 'package:bluebubbles/app/animations/love_classes.dart';
import 'package:bluebubbles/app/animations/love_rendering.dart';
import 'package:bluebubbles/app/animations/spotlight_classes.dart';
import 'package:bluebubbles/app/animations/spotlight_rendering.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ScreenEffectsWidget extends StatefulWidget {
  const ScreenEffectsWidget();

  @override
  State<StatefulWidget> createState() {
    return _ScreenEffectsWidgetState();
  }
}

class _ScreenEffectsWidgetState extends OptimizedState<ScreenEffectsWidget> with TickerProviderStateMixin {
  late final FireworkController fireworkController;
  late final CelebrationController celebrationController;
  late final ConfettiController confettiController;
  late final BalloonController balloonController;
  late final LoveController loveController;
  late final SpotlightController spotlightController;
  late final LaserController laserController;
  String screenSelected = "";
  StreamSubscription? _effectSubscription;
  bool _controllersInitialized = false;
  int _effectGeneration = 0;

  bool _isEffectActive(int generation) => mounted && generation == _effectGeneration;

  void _clearEffect(int generation) {
    if (!_isEffectActive(generation)) return;
    setState(() {
      screenSelected = "";
    });
  }

  @override
  void initState() {
    super.initState();

    _effectSubscription = eventDispatcher.stream.listen((event) async {
      if (event.item1 == 'play-effect' && mounted && _controllersInitialized && screenSelected.isEmpty) {
        final generation = ++_effectGeneration;
        setState(() {
          screenSelected = event.item2['type'];
        });
        final rect = event.item2['size'];
        if (screenSelected == "fireworks" && !fireworkController.isPlaying) {
          fireworkController.windowSize = Size(ns.width(context), context.height);
          fireworkController.start();
          await Future.delayed(const Duration(seconds: 1));
          if (!_isEffectActive(generation)) return;
          fireworkController.stop(onStop: () {
            _clearEffect(generation);
          });
        } else if (screenSelected == "celebration" && !celebrationController.isPlaying) {
          celebrationController.windowSize = Size(ns.width(context), context.height);
          celebrationController.start();
          await Future.delayed(const Duration(seconds: 1));
          if (!_isEffectActive(generation)) return;
          celebrationController.stop(onStop: () {
            _clearEffect(generation);
          });
        } else if (screenSelected == "balloons" && !balloonController.isPlaying) {
          balloonController.windowSize = Size(ns.width(context), context.height);
          balloonController.start();
          await Future.delayed(const Duration(seconds: 1));
          if (!_isEffectActive(generation)) return;
          balloonController.stop(onStop: () {
            _clearEffect(generation);
          });
        } else if (screenSelected == "love" && !loveController.isPlaying) {
          if (rect != null) {
            loveController.windowSize = Size(ns.width(context), context.height);
            loveController.start(Point((rect!.left + rect!.right) / 2, (rect!.top + rect!.bottom) / 2));
            await Future.delayed(const Duration(seconds: 1));
            if (!_isEffectActive(generation)) return;
            loveController.stop(onStop: () {
              _clearEffect(generation);
            });
          } else {
            _clearEffect(generation);
          }
        } else if (screenSelected == "spotlight" && !spotlightController.isPlaying) {
          if (rect != null) {
            spotlightController.windowSize = Size(ns.width(context), context.height);
            spotlightController.start(rect!);
            await Future.delayed(const Duration(seconds: 1));
            if (!_isEffectActive(generation)) return;
            spotlightController.stop(onStop: () {
              _clearEffect(generation);
            });
          } else {
            _clearEffect(generation);
          }
        } else if (screenSelected == "lasers" && !laserController.isPlaying) {
          if (rect != null) {
            laserController.windowSize = Size(ns.width(context), context.height);
            laserController.start(rect!);
            await Future.delayed(const Duration(seconds: 1));
            if (!_isEffectActive(generation)) return;
            laserController.stop(onStop: () {
              _clearEffect(generation);
            });
          } else {
            _clearEffect(generation);
          }
        } else if (screenSelected == "confetti") {
          confettiController.play();
          await Future.delayed(const Duration(seconds: 1));
          _clearEffect(generation);
        } else {
          _clearEffect(generation);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) return;
    final windowSize = Size(ns.width(context), context.height);
    fireworkController = FireworkController(vsync: this, windowSize: windowSize);
    celebrationController = CelebrationController(vsync: this, windowSize: windowSize);
    confettiController = ConfettiController(duration: const Duration(seconds: 1));
    balloonController = BalloonController(vsync: this, windowSize: windowSize);
    loveController = LoveController(vsync: this, windowSize: windowSize);
    spotlightController = SpotlightController(vsync: this, windowSize: windowSize);
    laserController = LaserController(vsync: this, windowSize: windowSize);
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _effectGeneration++;
    _effectSubscription?.cancel();
    if (_controllersInitialized) {
      fireworkController.dispose();
      celebrationController.dispose();
      confettiController.dispose();
      balloonController.dispose();
      loveController.dispose();
      spotlightController.dispose();
      laserController.dispose();
    }
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: screenSelected == "fireworks"
          || screenSelected == "celebration"
          || screenSelected == "spotlight"
          || screenSelected == "lasers"
        ? Colors.black : Colors.transparent,
      child: screenSelected.isEmpty ? null : Stack(
        children: [
          Fireworks(controller: fireworkController),
          Celebration(controller: celebrationController),
          Balloons(controller: balloonController),
          Love(controller: loveController),
          Spotlight(controller: spotlightController),
          Laser(controller: laserController),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.35,
            ),
          ),
        ]
      ),
    );
  }
}
