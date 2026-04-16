import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SendButton extends StatefulWidget {
  const SendButton({
    super.key,
    required this.onLongPress,
    required this.sendMessage,
    this.previousFocusNode,
  });

  final Function() onLongPress;
  final Function() sendMessage;
  final FocusNode? previousFocusNode;

  @override
  SendButtonState createState() => SendButtonState();
}

class SendButtonState extends OptimizedState<SendButton> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: ss.settings.sendDelay.value),
      animationBehavior: AnimationBehavior.preserve);

  Color get baseColor => iOS ? context.theme.colorScheme.primary : context.theme.colorScheme.properSurface;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      if (controller.isCompleted) {
        controller.reset();
        widget.sendMessage.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: () {
        if (controller.isAnimating) {
          controller.reset();
        } else {
          widget.onLongPress.call();
        }
      },
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (widget.previousFocusNode != null) {
              widget.previousFocusNode!.requestFocus();
            } else {
              FocusScope.of(context).focusInDirection(TraversalDirection.left);
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: DpadFocusable(
          onFocus: () => print("hi"),
          onSelect: () {
            if (controller.isAnimating) {
              controller.reset();
            } else if (ss.settings.sendDelay.value != 0) {
              controller.forward();
            } else {
              HapticFeedback.lightImpact();
              widget.sendMessage.call();
            }
          },
          child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: iOS ? context.theme.colorScheme.primary : null,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(0),
          maximumSize: const Size(28, 28),
          minimumSize: const Size(28, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, widget) {
            return Container(
              constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
              decoration: BoxDecoration(
                  shape: iOS ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: iOS ? null : BorderRadius.circular(10),
                  gradient: iOS || controller.value != 0
                      ? LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            baseColor,
                            baseColor,
                            context.theme.colorScheme.error,
                            context.theme.colorScheme.error
                          ],
                          stops: [0.0, 1 - controller.value, 1 - controller.value, 1.0],
                        )
                      : null),
              alignment: Alignment.center,
              child: Icon(
                controller.value == 0
                    ? (iOS ? CupertinoIcons.arrow_up : Icons.send_outlined)
                    : (iOS ? CupertinoIcons.xmark : Icons.close),
                color: controller.value == 0
                    ? (iOS ? context.theme.colorScheme.onPrimary : context.theme.colorScheme.secondary)
                    : context.theme.colorScheme.onError,
                size: iOS || controller.value != 0 ? 20 : 28,
              ),
            );
          },
        ),
        onPressed: () {
          if (controller.isAnimating) {
            controller.reset();
          } else if (ss.settings.sendDelay.value != 0) {
            controller.forward();
          } else {
            HapticFeedback.lightImpact();
            widget.sendMessage.call();
          }
        },
        onLongPress: () {
          if (controller.isAnimating) {
            controller.reset();
          } else {
            widget.onLongPress.call();
          }
        },
        ),
      )
      )
    );
  }
}
