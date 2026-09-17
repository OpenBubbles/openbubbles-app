import 'dart:math' as math;

import 'package:bluebubbles/app/components/avatars/contact_avatar_group_widget.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/typing/typing_clipper.dart';
import 'package:bluebubbles/app/components/avatars/contact_avatar_widget.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    this.visible,
    this.controller,
    this.scale = 1.0,
  });

  final bool? visible;
  final ConversationViewController? controller;
  final double scale;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends OptimizedState<TypingIndicator> {

  @override
  Widget build(BuildContext context) {
    // Both of these can be null (const TypingIndicator()), and the old `!` on the result threw.
    final visible = widget.controller?.showTypingIndicatorFor.isNotEmpty ?? widget.visible ?? false;
    // The chat list tiles are the call sites that pass no controller, so branch on that instead of
    // on cm.activeChat. cm.activeChat is also non-null whenever a chat is open in the other pane
    // (tablet mode, unfolded foldable), which made the list tiles fall into the avatar branch and
    // render an empty ContactAvatarGroupWidget next to the dots.
    final inChatList = widget.controller == null;
    return AnimatedSize(
      // Grow and shrink from the leading edge. The default centre alignment slid the dots sideways
      // for the whole 200ms as the indicator appeared and disappeared.
      alignment: Alignment.centerLeft,
      duration: const Duration(milliseconds: 200),
      child: visible ? (iOS || inChatList ? ClipPath(
        clipper: const TypingClipper(),
        child: Container(
          height: 50,
          color: context.theme.colorScheme.properSurface,
          padding: const EdgeInsets.fromLTRB(30, 10, 14, 20),
          child: Row(
            children: [
              if (widget.controller != null && widget.controller!.showTypingIndicatorFor.length == 1 && widget.controller!.typingIndicatorData[widget.controller!.showTypingIndicatorFor.first.address]?.$2 != null)
              Container(
                child: ClipRRect(child: Image.memory(widget.controller!.typingIndicatorData[widget.controller!.showTypingIndicatorFor.first.address]!.$2!), borderRadius: BorderRadius.circular(99),),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                // The bubble is 50 tall with 10 top and 20 bottom padding, so the row has 20 to give.
                // Without a height the decoded icon lays out at its intrinsic pixel size and overflows
                // the row, which is what the matching branch below already guards against with 25.
                height: 20,
              ),
              AnimatedDot(index: 2),
              AnimatedDot(index: 1),
              AnimatedDot(index: 0),
            ],
            mainAxisSize: MainAxisSize.min,
          ),
        ),
      ) : Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: ContactAvatarGroupWidget(
              participants: [...(widget.controller?.showTypingIndicatorFor ?? [])],
              size: 25,
              editable: false,
            ),
          ),
          if (widget.controller != null && widget.controller!.showTypingIndicatorFor.length == 1 && widget.controller!.typingIndicatorData[widget.controller!.showTypingIndicatorFor.first.address]?.$2 != null)
          Container(
            child: ClipRRect(child: Image.memory(widget.controller!.typingIndicatorData[widget.controller!.showTypingIndicatorFor.first.address]!.$2!), borderRadius: BorderRadius.circular(99),),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: 25,
          ),
          AnimatedDot(index: 2),
          AnimatedDot(index: 1),
          AnimatedDot(index: 0),
        ],
        mainAxisSize: MainAxisSize.min,
      )) : const SizedBox.shrink(),
    );
  }
}

class AnimatedDot extends StatefulWidget {
  final int index;
  AnimatedDot({required this.index});

  @override
  State<AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends OptimizedState<AnimatedDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700), animationBehavior: AnimationBehavior.preserve);

    animation = Tween(
      begin: 0.0,
      end: math.pi,
    ).animate(_controller);

    // repeat() drives the whole loop off one continuous ticker. Restarting with forward(from: 0)
    // from a status listener stopped and restarted the ticker on every cycle, and the first frame
    // after a restart reports zero elapsed time, so the dots stalled for a frame every 700ms.
    // It also removes the listener that could call forward() on a controller being torn down.
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (iOS) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final amt = (math.sin(animation.value + (widget.index) * math.pi / 4).abs() * 20).clamp(1, 20).toDouble();
          return Container(
            decoration: BoxDecoration(
              color: ts.inDarkMode(context)
                  ? context.theme.colorScheme.properSurface.lightenPercent(amt)
                  : context.theme.colorScheme.properSurface.darkenPercent(amt),
              shape: BoxShape.circle,
            ),
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          );
        },
      );
    } else {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Padding(
            padding: EdgeInsets.only(bottom: (math.sin(animation.value + (widget.index) * math.pi / 4).abs() * 20).clamp(1, 20).toDouble()),
            child: Container(
              decoration: BoxDecoration(
                color: context.theme.colorScheme.properSurface,
                shape: BoxShape.circle,
              ),
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
            ),
          );
        },
      );
    }
  }
}