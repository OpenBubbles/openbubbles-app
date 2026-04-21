import 'dart:ui';

import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/global/settings.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/ui/navigator/navigator_service.dart';
import 'package:bluebubbles/services/ui/theme/themes_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:get/get.dart';

/// Maps attachment picker item names to their icons.
const Map<String, IconData> _iconMap = {
  "Polls": Icons.how_to_vote,
  "Files": Icons.folder_open_outlined,
  "Location": Icons.location_on_outlined,
  "Send Later": Icons.lock_clock,
  "Handwritten": Icons.draw,
  "Stickers": Icons.emoji_emotions_outlined,
};

const Map<String, IconData> _iosIconMap = {
  "Files": CupertinoIcons.folder_open,
  "Location": CupertinoIcons.location,
  "Send Later": CupertinoIcons.clock_solid,
  "Handwritten": CupertinoIcons.pencil_outline,
  "Stickers": CupertinoIcons.smiley,
};

class AttachmentPickerOrderPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AttachmentPickerOrderPanelState();
}

class _AttachmentPickerOrderPanelState extends OptimizedState<AttachmentPickerOrderPanel> {
  final RxList<String> orderList = RxList();

  @override
  void initState() {
    super.initState();
    orderList.value = List.from(ss.settings.attachmentPickerOrder);
  }

  @override
  Widget build(BuildContext context) {
    final Rx<Color> _backgroundColor =
        (kIsDesktop && ss.settings.windowEffect.value != WindowEffect.disabled ? Colors.transparent : context.theme.colorScheme.background).obs;

    final Color tileColor = (ts.inDarkMode(context) ? context.theme.colorScheme.properSurface : context.theme.colorScheme.background)
        .withAlpha(ss.settings.windowEffect.value != WindowEffect.disabled ? 100 : 255);

    if (kIsDesktop) {
      ss.settings.windowEffect.listen((WindowEffect effect) =>
          _backgroundColor.value = effect != WindowEffect.disabled ? Colors.transparent : context.theme.colorScheme.background);
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: ss.settings.immersiveMode.value ? Colors.transparent : context.theme.colorScheme.background,
        systemNavigationBarIconBrightness: context.theme.colorScheme.brightness.opposite,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: context.theme.colorScheme.brightness.opposite,
      ),
      child: Obx(
        () => Scaffold(
          backgroundColor: _backgroundColor.value,
          appBar: PreferredSize(
            preferredSize: Size(ns.width(context), 80),
            child: ClipRRect(
              child: BackdropFilter(
                child: AppBar(
                  systemOverlayStyle: ThemeData.estimateBrightnessForColor(context.theme.colorScheme.background) == Brightness.dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark,
                  toolbarHeight: kIsDesktop ? 80 : 50,
                  elevation: 0,
                  scrolledUnderElevation: 3,
                  surfaceTintColor: context.theme.colorScheme.primary,
                  leading: buildBackButton(context),
                  backgroundColor: _backgroundColor.value,
                  centerTitle: ss.settings.skin.value == Skins.iOS,
                  title: Text(
                    "Attachment Picker Order",
                    style: context.theme.textTheme.titleLarge,
                  ),
                  actions: [
                    TextButton(
                      child: Text("Reset", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                      onPressed: () {
                        orderList.value = List.from(Settings.defaultAttachmentPickerOrder);
                        ss.settings.attachmentPickerOrder.value = List.from(Settings.defaultAttachmentPickerOrder);
                        ss.saveSettings();
                      },
                    ),
                  ],
                ),
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              ),
            ),
          ),
          body: Container(
            color: tileColor,
            child: Obx(
              () => ReorderableListView.builder(
                shrinkWrap: true,
                onReorder: (start, end) {
                  if (start == end) return;
                  final item = orderList.removeAt(start);
                  orderList.insert(end > start ? end - 1 : end, item);
                  ss.settings.attachmentPickerOrder.value = orderList.toList();
                  ss.saveSettings();
                },
                buildDefaultDragHandles: false,
                itemBuilder: (context, index) {
                  final name = orderList[index];
                  final icon = (iOS ? _iosIconMap[name] : null) ?? _iconMap[name] ?? Icons.help_outline;
                  return Row(
                    key: Key(name),
                    children: [
                      const SizedBox(width: 16),
                      Icon(icon, color: context.theme.colorScheme.properOnSurface),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          name,
                          style: context.theme.textTheme.bodyLarge,
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ReorderableDragStartListener(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Icon(
                              Icons.drag_handle,
                              color: context.theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  );
                },
                itemCount: orderList.length,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
