import 'dart:async';

import 'package:bluebubbles/app/components/avatars/contact_avatar_widget.dart';
import 'package:bluebubbles/app/layouts/settings/dialogs/custom_headers_dialog.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/layout/settings_section.dart';
import 'package:bluebubbles/app/layouts/setup/pages/page_template.dart';
import 'package:bluebubbles/app/layouts/setup/setup_view.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:get/get.dart' hide Response;
import 'package:url_launcher/url_launcher.dart';

class AppleIdLogin extends StatefulWidget {
  @override
  State<AppleIdLogin> createState() => _AppleIdLoginState();
}

class _AppleIdLoginState extends OptimizedState<AppleIdLogin> {
  final TextEditingController appleIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final controller = Get.find<SetupViewController>();
  final FocusNode focusNode = FocusNode();
  final FocusNode pwFocusNode = FocusNode();
  final FocusNode backFocusNode = FocusNode();
  final FocusNode signInFocusNode = FocusNode();
  bool loading = false;

  bool obscureText = true;

  String? availableUser;

  bool get showSignInButton => ((appleIdController.text != "" && passwordController.text != "") || controller.currentPhoneUsers.isEmpty) && availableUser == null;

  Color focusOutlineColor(BuildContext context) => context.theme.brightness == Brightness.dark ? Colors.white : Colors.black;

  void focusPrimaryButton() {
    if (showSignInButton) {
      signInFocusNode.requestFocus();
    } else {
      backFocusNode.requestFocus();
    }
  }

  void handleBack() {
    if (loading) return;
    controller.pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void handleSignIn() {
    if (loading) return;
    ss.settings.customHeaders.value = {};
    http.onInit();
    connect(appleIdController.text, passwordController.text);
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

    availableUser = api.getAvailableUser(path: pushService.statePath);

    // Start listening to changes.
    appleIdController.addListener(() {
      setState(() { });
    });

    passwordController.addListener(() {
      setState(() { });
    });
    backFocusNode.addListener(() {
      setState(() { });
    });
    signInFocusNode.addListener(() {
      setState(() { });
      scrollFocusIntoView(signInFocusNode);
    });
  }

  void registerPhoneOnly() async {
    controller.currentAppleUser = null;
    controller.updateConnectError("");
    setState(() {
      loading = true;
    });
    try {
      ss.settings.iCloudAccount.value = "";
      ss.settings.userName.value = "You";
      ss.settings.customHeaders.value = {};
      await ss.settings.saveAsync();
      http.onInit();
      await controller.doRegister();
      if (!controller.success) {
        return;
      }
      controller.goingTo2fa = false;
      controller.pageController.animateToPage(
        controller.pageController.page!.toInt() + 2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      if (e is AnyhowException) {
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

  @override
  Widget build(BuildContext context) {
    return SetupPageTemplate(
      title: "Apple Account",
      subtitle: "",
      customSubtitle: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              style: context.theme.textTheme.bodyLarge!.apply(
                fontSizeDelta: 1.5,
                color: context.theme.colorScheme.outline,
              ).copyWith(height: 2),
              children: [
                const TextSpan(
                  text: "Use OpenBubbles with your Apple Account"
                ),
                if (availableUser == null && controller.currentPhoneUsers.isNotEmpty && !loading) ...[
                  const TextSpan(text: "\nHaving trouble? "),
                  TextSpan(
                    text: "Skip Apple Account login.",
                    style: TextStyle(
                      color: context.theme.colorScheme.primary,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = registerPhoneOnly,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
                        if (availableUser == null)
                        const SizedBox(height: 20),
                        if (availableUser == null)
                        Container(
                          width: context.width * 2 / 3,
                          child: CallbackShortcuts(
                            bindings: {
                              const SingleActivator(LogicalKeyboardKey.arrowDown): () => pwFocusNode.requestFocus(),
                            },
                            child: TextField(
                              cursorColor: context.theme.colorScheme.primary,
                              autocorrect: false,
                              autofocus: true,
                              focusNode: focusNode,
                              controller: appleIdController,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () {
                                FocusScope.of(context).requestFocus(pwFocusNode);
                              },
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: context.theme.colorScheme.outline),
                                    borderRadius: BorderRadius.circular(20)),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: context.theme.colorScheme.primary),
                                    borderRadius: BorderRadius.circular(20)),
                                labelText: "Email or Phone Number",
                              ),
                            ),
                          )
                        ),
                        if (availableUser == null)
                        const SizedBox(height: 20),
                        if (availableUser == null)
                        Container(
                          width: context.width * 2 / 3,
                          child: CallbackShortcuts(
                            bindings: {
                              const SingleActivator(LogicalKeyboardKey.arrowUp): () => focusNode.requestFocus(),
                              const SingleActivator(LogicalKeyboardKey.arrowDown): focusPrimaryButton,
                              const SingleActivator(LogicalKeyboardKey.arrowRight): focusPrimaryButton,
                              const SingleActivator(LogicalKeyboardKey.arrowLeft): () => backFocusNode.requestFocus(),
                            },
                            child: TextField(
                              cursorColor: context.theme.colorScheme.primary,
                              autocorrect: false,
                              autofocus: false,
                              focusNode: pwFocusNode,
                              controller: passwordController,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (pass) => connect(appleIdController.text, pass),
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: context.theme.colorScheme.outline),
                                    borderRadius: BorderRadius.circular(20)),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: context.theme.colorScheme.primary),
                                    borderRadius: BorderRadius.circular(20)),
                                labelText: "Password",
                                contentPadding: const EdgeInsets.fromLTRB(12, 24, 40, 16),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                                  color: context.theme.colorScheme.outline,
                                  onPressed: () {
                                    setState(() {
                                      obscureText = !obscureText;
                                    });
                                  },
                                ),
                              ),
                              obscureText: obscureText,
                            ),
                          ),
                        ),
                        if (availableUser == null)
                        const SizedBox(height: 10),
                        if (availableUser == null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () async {
                                var devInfo = await api.getDeviceInfo(config: controller.config!);
                                await showDialog(
                                  context: Get.context!,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Create Apple Account'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Visit icloud.com to create an Apple Account. You may need to contact Apple support if it states your account cannot be created at this time.",
                                          style: Get.textTheme.bodyLarge,
                                        ),
                                        const SizedBox(height: 20),
                                        Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            "Warning: Do not contact Apple support for help with OpenBubbles. Do not mention OpenBubbles. For assistance, join our Discord from our website.\n\n${RustPushBBUtils.modelToUser(devInfo.name)}\nS/N: ${devInfo.serial}\nmacOS ${devInfo.osVersion}",
                                            textAlign: TextAlign.center,
                                            style: Get.textTheme.bodySmall,
                                          )
                                        ),
                                      ],
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                              onPressed: () => Get.back(),
                                              child: Text("Cancel", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary))),
                                      TextButton(
                                              onPressed: () async {
                                                await launchUrl(Uri.parse("https://getsupport.apple.com"), mode: LaunchMode.externalApplication);
                                              },
                                              child: Text("Get Support", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary))),
                                      TextButton(
                                              onPressed: () async {
                                                await launchUrl(Uri.parse("https://icloud.com"), mode: LaunchMode.externalApplication);
                                              },
                                              child: Text("Open", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary))),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                "Create new Apple Account",
                                style: context.theme.textTheme.bodyMedium!.apply(color: HexColor('2772C3'))
                              )
                            ),
                            TextButton(
                              onPressed: () async {
                                await launchUrl(Uri.parse("https://iforgot.apple.com/password/verify/appleid"), mode: LaunchMode.externalApplication);
                              },
                              child: Text(
                                "Forgot Password",
                                style: context.theme.textTheme.bodyMedium!.apply(color: HexColor('2772C3'))
                              )
                            ),
                          ],
                        ),
                        if (availableUser != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5.0),
                          child: Material(
                            color: tileColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: ListTile(
                              mouseCursor: MouseCursor.defer,
                              leading: ContactAvatarWidget(
                                handle: null,
                                borderThickness: 0.1,
                                editable: false,
                                fontSize: 22,
                                size: 50,
                              ),
                              onTap: () async {
                                if (loading) return;
                                connect(availableUser!, null);
                              },
                              title: RichText(
                                text: TextSpan(
                                  style: context.theme.textTheme.bodyLarge,
                                  children: MessageHelper.buildEmojiText(
                                    ss.settings.redactedMode.value && ss.settings.hideContactInfo.value
                                        ? "User Name" : ss.settings.userName.value,
                                    context.theme.textTheme.bodyLarge!,
                                  ),
                                ),
                              ),
                              subtitle: Text(ss.settings.redactedMode.value && ss.settings.hideContactInfo.value
                                  ? "User iCloud"
                                  : availableUser!, style: context.theme.textTheme.bodyMedium!.apply(color: context.theme.colorScheme.outline)),
                              trailing: loading ? buildProgressIndicator(context, brightness: Brightness.dark) : Icon(Icons.arrow_forward, color: context.theme.colorScheme.onBackground, size: 20),
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
                                  pwFocusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                                if (event.logicalKey == LogicalKeyboardKey.arrowRight && showSignInButton) {
                                  signInFocusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                                if (isActivateKey(event.logicalKey)) {
                                  handleBack();
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
                                onPressed: loading ? null : handleBack,
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
                            if (showSignInButton)
                            Focus(
                              focusNode: signInFocusNode,
                              onKey: (node, event) {
                                if (event is! RawKeyDownEvent) return KeyEventResult.ignored;
                                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                  pwFocusNode.requestFocus();
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
                                  connect(appleIdController.text, passwordController.text);
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
                            if ((!showSignInButton || availableUser != null) && !(availableUser != null && loading))
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
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
                                  backgroundColor: MaterialStateProperty.all(context.theme.colorScheme.background),
                                  shadowColor: MaterialStateProperty.all(context.theme.colorScheme.background),
                                  maximumSize: MaterialStateProperty.all(const Size(200, 36)),
                                  minimumSize: MaterialStateProperty.all(const Size(30, 30)),
                                ),
                                onPressed: loading ? null : () async {
                                  if (availableUser != null) {
                                    setState(() {
                                      availableUser = null;
                                    });
                                    return;
                                  }
                                  registerPhoneOnly();
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Opacity(opacity: loading ? 0 : 1, child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(availableUser != null ? "Change" : "Skip",
                                            style: context.theme.textTheme.bodyLarge!
                                                .apply(fontSizeFactor: 1.1, color: context.theme.colorScheme.onBackground)),
                                        const SizedBox(width: 10),
                                        Icon(Icons.arrow_forward, color: context.theme.colorScheme.onBackground, size: 20),
                                      ],
                                    ),),
                                    if (loading)
                                    buildProgressIndicator(context, brightness: Brightness.dark),
                                  ],
                                )
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

  Future<void> connect(String appleId, String? password) async {
    // apple only takes lowercase
    appleId = appleId.toLowerCase();
    controller.updateConnectError("");
    setState(() {
      loading = true;
    });
    try {
      var (account, result) = await api.tryAuth(
        path: pushService.statePath,
        conf: controller.config!,
        conn: controller.connection!,
        anisette: controller.anisette!, 
        creds: password == null ? null : (appleId, password),
      );
      controller.currentAppleAccount = account;
      controller.currentAppleUser = await api.tryIcloudLogin(path: pushService.statePath, conf: controller.config!, account: account);

      result = await controller.updateLoginState(result);


      // if (result is api.LoginState_NeedsSMS2FA) {
      //   result = api.LoginState.needsSms2FaVerification(api.VerifyBody(

      //   ))
      // }
      // if (result is api.LoginState_NeedsDevice2FA) {
      //   result = const api.LoginState.needs2FaVerification();
      // }

      ss.settings.iCloudAccount.value = appleId;
      if (result is api.LoginState_Needs2FAVerification || result is api.LoginState_NeedsSMS2FAVerification) {
        // we need 2fa
        controller.goingTo2fa = true;
        controller.twoFaCreds = password == null ? null : (appleId, password);
        controller.pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }
      if (result is api.LoginState_LoggedIn) {
        if (!controller.success) {
          return;
        }
        controller.goingTo2fa = false;
        controller.pageController.animateToPage(
          controller.pageController.page!.toInt() + 2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        FocusManager.instance.primaryFocus?.unfocus();
      }
    } catch (e) {
      if (e is AnyhowException) {
        if (e.message.contains("MOBILEME_TERMS_OF_SERVICE_UPDATE")) {
          await controller.updateAccountUi((finished) => setState(() { 
            loading = finished; 
            if (!finished) {
              if (!controller.success) {
                return;
              }
              controller.goingTo2fa = false;
              controller.pageController.animateToPage(
                controller.pageController.page!.toInt() + 2,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
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
