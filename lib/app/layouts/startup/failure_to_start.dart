import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FailureToStart extends StatelessWidget {
  const FailureToStart({super.key, this.e, this.s, this.otherTitle});
  final dynamic e;
  final StackTrace? s;
  final String? otherTitle;

  @override
  Widget build(BuildContext context) {
    final errorText = e?.toString() ?? 'Unknown error';
    final stackText = s?.toString() ?? '';

    return MaterialApp(
      title: 'OpenBubbles',
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.black, // navigation bar color
          systemNavigationBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent, // status bar color
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      otherTitle ?? "Whoops, something went wrong during startup.",
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      errorText.contains('timed out')
                          ? "A startup task timed out. Please restart the app. If this keeps happening, try reinstalling."
                          : "Please restart the app. If this keeps happening, you may need to reinstall.",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: "Error: $errorText\n\nStacktrace: $stackText"));
                    },
                    icon: const Icon(Icons.copy, color: Colors.white70, size: 16),
                    label: const Text("Copy Error Details", style: TextStyle(color: Colors.white70)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white38)),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Text("Error: $errorText", style: const TextStyle(color: Colors.white60, fontSize: 10)),
                    ),
                  ),
                  if (stackText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Center(
                        child: Text("Stacktrace: $stackText", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
