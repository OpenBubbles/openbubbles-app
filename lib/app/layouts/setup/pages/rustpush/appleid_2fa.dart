import 'dart:async';

import 'package:bluebubbles/app/layouts/settings/dialogs/custom_headers_dialog.dart';
import 'package:bluebubbles/app/layouts/setup/pages/page_template.dart';
import 'package:bluebubbles/app/layouts/setup/setup_view.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:get/get.dart' hide Response;
import 'package:url_launcher/url_launcher.dart';

class AppleId2FA extends StatefulWidget {
  @override
  State<AppleId2FA> createState() => _AppleId2FAState();
}

class _AppleId2FAState extends OptimizedState<AppleId2FA> {
  final TextEditingController codeController = TextEditingController();
  final controller = Get.find<SetupViewController>();
  final FocusNode focusNode = FocusNode();
  final FocusNode resendFocusNode = FocusNode();
  final FocusNode backFocusNode = FocusNode();
  final FocusNode signInFocusNode = FocusNode();
  String currentCode = "";
  String submittedCode = "";

  bool obscureText = true;
  bool loading = false;
  bool appleHelping = false;

  Color focusOutlineColor(BuildContext context) => context.theme.brightness == Brightness.dark ? Colors.white : Colors.black;

  void handleSignIn() {
    if (loading) return;
    ss.settings.customHeaders.value = {};
    http.onInit();
    connect(codeController.text);
  }

  bool isActivateKey(LogicalKeyboardKey key) => key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.space;

  void scrollFocusIntoView(FocusNode node) {
    if (!node.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = node.context;
      if (context == null) return;
      Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 200), alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
    });
  }

  @override
  void initState() {
    super.initState();

    // Start listening to changes.
    codeController.addListener(() {
      setState(() {
        currentCode = codeController.text;
      });
      if (codeController.text.length == 6 && submittedCode != codeController.text) {
        submittedCode = codeController.text;
        connect(codeController.text);
      }
    });
    focusNode.addListener(() {
      setState(() { });
    });
    resendFocusNode.addListener(() {
      setState(() { });
    });
    backFocusNode.addListener(() {
      setState(() { });
    });
    signInFocusNode.addListener(() {
      setState(() { });
      scrollFocusIntoView(signInFocusNode);
    });
    if (controller.goingTo2fa) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SetupPageTemplate(
      title: "2fa Code",
      subtitle: "Enter the code sent to your ${controller.isSms.value ? "phone" : "Apple devices"}",
      customButton: Column(
        children: [
          ErrorText(parentController: controller),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: Theme(
                    data: context.theme.copyWith(
                      inputDecorationTheme: InputDecorationTheme(
                        labelStyle: TextStyle(color: context.theme.colorScheme.outline),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          width: context.width * 2 / 3,
                          child: CallbackShortcuts(
                            bindings: {
                              const SingleActivator(LogicalKeyboardKey.arrowDown): () => resendFocusNode.requestFocus(),
                            },
                            child: Stack(
                              children: [
                                Row(
                                  children: List.generate(6, (index) {
                                    var text = index < currentCode.length ? currentCode[index] : "";
                                    return Expanded(child: 
                                      Container(
                                        decoration: index == currentCode.length ? 
                                          BoxDecoration(
                                            border: Border.all(
                                              color: context.theme.colorScheme.primary,
                                              width: 2
                                            ),
                                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                                          )
                                        : BoxDecoration(
                                          border: Border.all(
                                            color: context.theme.colorScheme.outline,
                                          ),
                                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                                        ),
                                        margin: const EdgeInsets.all(3),
                                        height: 50,
                                        child: Center(
                                          child: Text(
                                            text,
                                            style: context.theme.textTheme.titleLarge
                                          ),
                                        )
                                      )
                                    );
                                  }),
                                ),
                                Opacity(
                                  opacity: 0,
                                  child: TextField(
                                    cursorColor: context.theme.colorScheme.primary,
                                    autocorrect: false,
                                    autofocus: controller.goingTo2fa, // if we're not going don't pop up the keyboard for a transitive state
                                    focusNode: focusNode,
                                    controller: codeController,
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.number,
                                  )),
                              ],
                            )
                          ),
                        ),
                        const SizedBox(height: 20),
                        Focus(
                          focusNode: resendFocusNode,
                          onKey: (node, event) {
                            if (event is! RawKeyDownEvent) return KeyEventResult.ignored;
                            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                              focusNode.requestFocus();
                              return KeyEventResult.handled;
                            }
                            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                              signInFocusNode.requestFocus();
                              return KeyEventResult.handled;
                            }
                            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                              backFocusNode.requestFocus();
                              return KeyEventResult.handled;
                            }
                            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                              signInFocusNode.requestFocus();
                              return KeyEventResult.handled;
                            }
                            if (isActivateKey(event.logicalKey) && !appleHelping) {
                              appleHelp();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: resendFocusNode.hasFocus ? Border.all(color: focusOutlineColor(context), width: 2) : null,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextButton(
                              onPressed: appleHelping ? null : () async {
                                appleHelp();
                              },
                              child: Text(
                                controller.isSms.value ? "Resend code" : "Resend to Phone #",
                                style: context.theme.textTheme.bodyLarge!.apply(fontSizeFactor: 1.1, color: appleHelping ? HexColor('777777') : HexColor('2772C3'))
                              )
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Focus(
                              focusNode: backFocusNode,
                              onKey: (node, event) {
                                if (event is! RawKeyDownEvent) return KeyEventResult.ignored;
                                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                  resendFocusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                                if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                  signInFocusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                                if (isActivateKey(event.logicalKey)) {
                                  goBack();
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: backFocusNode.hasFocus ? Border.all(color: focusOutlineColor(context), width: 2) : null,
                                gradient: LinearGradient(
                                  begin: AlignmentDirectional.topStart,
                                  colors: [HexColor('2772C3'), HexColor('5CA7F8').darkenPercent(5)],
                                ),
                              ),
                              height: 40,
                              padding: const EdgeInsets.all(2),
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                  backgroundColor: MaterialStateProperty.all(context.theme.colorScheme.background),
                                  shadowColor: MaterialStateProperty.all(context.theme.colorScheme.background),
                                  maximumSize: MaterialStateProperty.all(const Size(200, 36)),
                                  minimumSize: MaterialStateProperty.all(const Size(30, 30)),
                                ),
                                onPressed: loading ? null : () async {
                                  goBack();
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_back, color: context.theme.colorScheme.onBackground, size: 20),
                                    const SizedBox(width: 10),
                                    Text("Back",
                                        style: context.theme.textTheme.bodyLarge!
                                            .apply(fontSizeFactor: 1.1, color: context.theme.colorScheme.onBackground)),
                                  ],
                                ),
                              ),
                              ),
                            ),
                            Focus(
                              focusNode: signInFocusNode,
                              onKey: (node, event) {
                                if (event is! RawKeyDownEvent) return KeyEventResult.ignored;
                                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                  resendFocusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                  backFocusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                                if (isActivateKey(event.logicalKey)) {
                                  handleSignIn();
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                border: signInFocusNode.hasFocus ? Border.all(color: focusOutlineColor(context), width: 2) : null,
                                gradient: LinearGradient(
                                  begin: AlignmentDirectional.topStart,
                                  colors: loading ? [HexColor('777777'), HexColor('777777')] : [HexColor('2772C3'), HexColor('5CA7F8').darkenPercent(5)],
                                ),
                              ),
                              height: 40,
                              padding: const EdgeInsets.all(2),
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                  shadowColor: MaterialStateProperty.all(Colors.transparent),
                                  maximumSize: MaterialStateProperty.all(const Size(200, 36)),
                                  minimumSize: MaterialStateProperty.all(const Size(30, 30)),
                                ),
                                onPressed: loading ? null : handleSignIn,
                                onLongPress: () async {
                                  await showCustomHeadersDialog(context);
                                  connect(codeController.text);
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Opacity(opacity: loading ? 0 : 1, child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("Sign In",
                                            style: context.theme.textTheme.bodyLarge!
                                                .apply(fontSizeFactor: 1.1, color: Colors.white)),
                                        const SizedBox(width: 10),
                                        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                      ],
                                    ),),
                                    if (loading)
                                    buildProgressIndicator(context, brightness: Brightness.dark),
                                  ],
                                )
                              ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> appleHelp() async {
    setState(() {
      appleHelping = true;
    });
    try {
      await controller.updateLoginState(const api.LoginState.needsSms2Fa());
    } catch (e) {
      controller.updateConnectError("$e");
      rethrow;
    } finally {
      setState(() {
        appleHelping = false;
      });
    }
  }

  void goBack() {
    controller.currentAppleAccount?.dispose();
    controller.currentAppleAccount = null;

    controller.twoFaCreds = null;
    controller.pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> connect(String code) async {
    controller.updateConnectError("");
    setState(() {
      loading = true;
    });
    try {
      if (await controller.submitCode(code) is api.LoginState_LoggedIn) {
        if (controller.success) {
          controller.pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          controller.pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        FocusManager.instance.primaryFocus?.unfocus();
      }
    } catch (e) {
      if (e is AnyhowException) {
        if (e.message.contains("MOBILEME_TERMS_OF_SERVICE_UPDATE")) {
          await controller.updateAccountUi((finished) => setState(() { 
            loading = finished; 
            if (!finished) {
              if (controller.success) {
                controller.pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                controller.pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              FocusManager.instance.primaryFocus?.unfocus();  
            }
            }));
        }
        controller.updateConnectError(e.message);
      }
      if (e is PanicException) {
        controller.updateConnectError(e.message);
      }
      rethrow;
    } finally {
      setState(() {
        loading = false;
      });
    }
  }
}
