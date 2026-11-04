import 'package:bluebubbles/app/layouts/setup/pages/page_template.dart';
import 'package:bluebubbles/app/layouts/setup/setup_view.dart';
import 'package:bluebubbles/helpers/ui/theme_helpers.dart';
import 'package:bluebubbles/main.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectionModePage extends StatefulWidget {
  @override
  State<ConnectionModePage> createState() => _ConnectionModePageState();
}

class _ConnectionModePageState extends State<ConnectionModePage> {
  final SetupViewController controller = Get.find<SetupViewController>();
  late bool isDirect;

  @override
  void initState() {
    super.initState();
    isDirect = ss.settings.useRustPush.value;
  }

  @override
  Widget build(BuildContext context) {
    return SetupPageTemplate(
      title: "Connection Method",
      subtitle: "Choose how OpenBubbles connects to the iMessage network.",
      customMiddle: Column(
        children: [
          _buildOptionCard(
            context: context,
            title: "BlueBubbles Server (Mac Bridge)",
            badge: "Recommended",
            badgeColor: Colors.green,
            subtitle:
                "Connect to an existing Mac running BlueBubbles Server. Provides maximum stability, full SMS relay, and Contact Key Verification (CKV) support.",
            icon: CupertinoIcons.desktopcomputer,
            selected: !isDirect,
            onTap: () {
              setState(() {
                isDirect = false;
              });
              ss.settings.useRustPush.value = false;
              usingRustPush = false;
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context: context,
            title: "Direct Apple Connection (Experimental)",
            badge: "No Mac Needed",
            badgeColor: Colors.orange,
            subtitle:
                "Connect directly to Apple push notification servers using an Apple ID. Experimental standalone mode without requiring a dedicated Mac.",
            icon: CupertinoIcons.bolt_fill,
            selected: isDirect,
            onTap: () {
              setState(() {
                isDirect = true;
              });
              ss.settings.useRustPush.value = true;
              usingRustPush = true;
            },
          ),
        ],
      ),
      onNextPressed: () async {
        ss.settings.useRustPush.value = isDirect;
        usingRustPush = isDirect;
        await ss.saveSettings();
        return true;
      },
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String badge,
    required Color badgeColor,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = context.theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.properSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3),
            width: selected ? 2.0 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0, right: 14.0),
              child: Icon(
                icon,
                size: 28,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: selected ? theme.colorScheme.primary : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Icon(
                selected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.5),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
