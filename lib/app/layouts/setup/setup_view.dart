import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:bluebubbles/app/layouts/conversation_list/pages/conversation_list.dart';
import 'package:bluebubbles/app/layouts/setup/pages/rustpush/appleid_2fa.dart';
import 'package:bluebubbles/app/layouts/setup/pages/rustpush/appleid_login.dart';
import 'package:bluebubbles/app/layouts/setup/pages/rustpush/finalize.dart';
import 'package:bluebubbles/app/layouts/setup/pages/rustpush/hw_inp.dart';
import 'package:bluebubbles/app/layouts/setup/pages/rustpush/phone_number.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/app/layouts/setup/pages/setup_checks/battery_optimization.dart';
import 'package:bluebubbles/app/layouts/setup/dialogs/failed_to_connect_dialog.dart';
import 'package:bluebubbles/app/layouts/setup/pages/sync/sync_settings.dart';
import 'package:bluebubbles/app/layouts/setup/pages/sync/server_credentials.dart';
import 'package:bluebubbles/app/layouts/setup/pages/contacts/request_contacts.dart';
import 'package:bluebubbles/app/layouts/setup/pages/bluetooth/request_bluetooth.dart';
import 'package:bluebubbles/app/layouts/setup/pages/setup_checks/mac_setup_check.dart';
import 'package:bluebubbles/app/layouts/setup/pages/sync/sync_progress.dart';
import 'package:bluebubbles/app/layouts/setup/pages/welcome/welcome_page.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/main.dart';
import 'package:bluebubbles/services/rustpush/rustpush_service.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/src/rust/frb_generated.dart';
import 'package:bluebubbles/src/rust/lib.dart';
import 'package:bluebubbles/utils/crypto_utils.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:dio/dio.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:permission_handler/permission_handler.dart';
import 'package:bluebubbles/src/rust/api/api.dart' as api;
import 'package:url_launcher/url_launcher.dart';
import 'package:convert/convert.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

class SetupViewController extends StatefulController {
  final pageController = PageController(initialPage: 0);
  int currentPage = 1;
  int numberToDownload = 25;
  bool skipEmptyChats = true;
  bool saveToDownloads = false;
  String error = "";
  bool obscurePass = true;
  RxBool isSms = false.obs;

  RxBool supportsPhoneReg = false.obs;

  final GlobalKey<HwInpState> _childKey = GlobalKey<HwInpState>();

  bool goingTo2fa = true;
  bool success = false;
  bool triedBattery = false;

  api.LoginState state = const api.LoginState.needsLogin();
  api.IdsUser? currentAppleUser;
  ArcMutexAppleAccountDefaultAnisetteProvider? currentAppleAccount;
  Map<int, api.IdsUser> currentPhoneUsers = {};


  api.ReceiverApsMessage? connReceiver;
  ArcIdmsAuthListener? connListener;

  ApsConnection? connection;
  api.JoinedOsConfig? config;
  api.IdsngmIdentity? identity;
  ApsState? cachedState;
  ArcAnisetteClientDefaultAnisetteProvider? anisette;


  api.CircleClientSessionDefaultAnisetteProvider? circleSession;

  @override
  void dispose() {
    super.dispose();
    destroyConnection();
  }

  RxBool phoneValidating = false.obs;
  Rxn<SubscriptionOfferDetailsWrapper> availableIAP = Rxn();
  bool hasDanglingSubscription = false;
  String? token;
  DateTime tokenExpiry = DateTime.fromMillisecondsSinceEpoch(0);

  String? currentWaitlist;
  RxString noCapErrorMsg = "Currently full. If you got an invite, enter your code from your email. Otherwise, sign up to get notified!".obs;

  bool errorIsProblem() {
    return error.isNotEmpty && !error.contains("Enter the correct password") && !error.contains("Your account information was entered incorrectly") && !error.contains("Sorry, your hosted device is currently offline!") && (!error.contains("Relay device offline") || !ss.settings.deviceIsHosted.value);
  }

  bool hasValidToken() {
    return !tokenExpiry.isBefore(DateTime.now());
  }

  Future<String> ensureToken() async {
    if (!hasValidToken()) {
      var headers = <String, dynamic>{};
      if (currentWaitlist != null) {
        headers["X-OpenBubbles-Waitlist"] = currentWaitlist;
      }
      // we need to refresh tokens
      final response2 = await http.dio.post(
        "https://hw.openbubbles.app/ticket",
        options: Options(headers: headers)
      );

      if (response2.statusCode == 429) {
        throw Exception("Too many reserved tickets!");
      }
      if (response2.statusCode != 200) {
        throw Exception(response2.data);
      }

      token = response2.data["code"];
      tokenExpiry = DateTime.fromMillisecondsSinceEpoch(response2.data["expiry"] * 1000, isUtc: true);
    }

    return token!;
  }

  bool fetchedReferrer = false;

  Future<void> updateIAPState() async {
    hasDanglingSubscription = false;
    if (currentWaitlist == null && !fetchedReferrer) {
      try {
        ReferrerDetails referrerDetails = await AndroidPlayInstallReferrer.installReferrer;
        var referrer = referrerDetails.installReferrer;
        if (referrer != null && referrer.startsWith("WL") && currentWaitlist == null) {
          currentWaitlist = referrer.replaceFirst("WL", "");
        }
        if (referrer != null && referrer.startsWith("CD")) {
          await cacheCode(referrer.replaceFirst("CD", ""));
        }
      } catch (e, s) {
        Logger.error("failed to fetch referrer ", error: e, trace: s);
      }
      fetchedReferrer = true;
    }

    if (!hasValidToken()) {
      var details = (await pushService.getPurchaseDetails())?.purchaseToken;
      details ??= ss.settings.hostedToken.value;
      if (details != null) {
        final status = await http.dio.post("https://hw.openbubbles.app/restore", data: {"purchase_token": details});
        if (status.statusCode == 200) {
          var ticket = status.data["code"];
          await restoreTicket(ticket, const Duration(days: 7));
          return;
        } else if (status.statusCode == 404) {
          // we have a valid token, but no subscription
          hasDanglingSubscription = true;
        }
      }

      var headers = <String, dynamic>{};
      if (currentWaitlist != null) {
        headers["X-OpenBubbles-Waitlist"] = currentWaitlist;
      }
      final status = await http.dio.get("https://hw.openbubbles.app/status", options: Options(headers: headers));   
      var hasCapacity = status.data["available"];
      if (!hasCapacity) {
        availableIAP.value = null;
        noCapErrorMsg.value = status.data["message"];
        return;
      }
    }
    var details = await pushService.client.runWithClient((client) => client.queryProductDetails(productList: [const ProductWrapper(productId: 'monthly_hosted', productType: ProductType.subs)]));
    if (details.productDetailsList.isEmpty) {
      Logger.warn("Product not found!");
      availableIAP.value = null;
      return;
    }

    print(details);

    availableIAP.value = details.productDetailsList.first.subscriptionOfferDetails?.first;
  }

  void updateSucceeded(Function finish, api.UpdateAccountFinish updateFinish) async {
    finish(true);
    updateConnectError('');
    try {
      currentAppleUser = await api.doLogin(path: pushService.statePath, account: currentAppleAccount!, osConfig: config!, finish: updateFinish);
      ss.settings.userName.value = await api.getUserName(state: currentAppleAccount!);
      await doRegister();
    } catch (e) {
      if (e is AnyhowException) {
        updateConnectError(e.message);
      }
      if (e is PanicException) {
        updateConnectError(e.message);
      }
      rethrow;
    } finally {
      finish(false);
    }
  }

  Future<void> updateAccountUi(Function finish) async {
    var (data, finalI) = await api.updateAccountHeaders(account: currentAppleAccount!, config: config!);
    var request = URLRequest(url: WebUri("https://inappwebview.dev/"));
    
    double height = min(400, MediaQuery.sizeOf(Get.context!).height - 200);
    showDialog(
      context: Get.context!,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: height,
                child: InAppWebView(
                  initialUrlRequest: request,
                  initialData: InAppWebViewInitialData(data: data, baseUrl: WebUri("https://setup.icloud.com/setup/update_account_ui")),
                  initialSettings: InAppWebViewSettings(
                    useShouldInterceptAjaxRequest: true,
                    interceptOnlyAsyncAjaxRequests: false,
                    useShouldInterceptFetchRequest: true,
                  ),
                  shouldInterceptAjaxRequest: (controller, request) async {
                    var anisette = await api.getAnisetteHeaders(state: this.anisette!, config: config!);
                    for (var header in anisette.entries) {
                      request.headers!.setRequestHeader(header.key, header.value);
                    }
                    return request;
                  },
                  shouldInterceptFetchRequest: (controller, request) async {
                    var anisette = await api.getAnisetteHeaders(state: this.anisette!, config: config!);
                    request.headers ??= {};
                    request.headers!.addAll(anisette);
                    return request;
                  },
                  onWebViewCreated: (controller) {
                    controller.addJavaScriptHandler(handlerName: 'log', callback: (args) {
                      Logger.info("AppleAccountSetup ${args[0]}");
                    });
                    controller.addJavaScriptHandler(handlerName: 'cancel', callback: (args) {
                      Get.back();
                    });
                    controller.addJavaScriptHandler(handlerName: 'updateSucceeded', callback: (args) {
                      updateSucceeded(finish, finalI);
                      Get.back();
                    });
                    // for ios, also hijacks macos because ios doesn't load prefpange-setupservice.js, loads ios-setupservice.js but that doesn't work
                    controller.addJavaScriptHandler(handlerName: 'confirmWithCallback', callback: (args) {
                      updateSucceeded(finish, finalI);
                      Get.back();
                    });
                    controller.addJavaScriptHandler(handlerName: 'resizeToWindow', callback: (args) {
                      setState(() {
                        height = args[1];
                      });
                    });
                    controller.injectJavascriptFileFromAsset(assetFilePath: "assets/scripts/AppleAccountSetup.js");
                  },
                )
              ),
              TextButton(
                onPressed: () {
                  updateSucceeded(finish, finalI);
                  Get.back();
                },
                child: const Text('Accept Terms', style: TextStyle(color: Colors.white)),
              ),
            ],
          ));
        }
      )
    );
  }

  Future<api.LoginState> updateLoginState(api.LoginState ret) async {
    if (ret is api.LoginState_NeedsLogin) {
      ArcMutexAppleAccountDefaultAnisetteProvider account;
      (account, ret) = await api.tryAuth(
        path: pushService.statePath,
        conf: config!,
        conn: connection!,
        anisette: anisette!, 

        creds: twoFaCreds
      );
      currentAppleAccount?.dispose();
      currentAppleAccount = account;
      currentAppleUser = await api.tryIcloudLogin(path: pushService.statePath, conf: config!, account: account);
    }
    if (ret is api.LoginState_NeedsDevice2FA) {
      // subscribe now to not miss the 2fa message
      await ensureWatcher();
      var (provider, rett, sid) = await api.send2FaToDevices(state: currentAppleAccount!, conn: connection!);
      if (sid != null) {
        mcs.invokeMethod("circle-proximity-session", {
          'sid': sid
        });
      }
      ret = rett;
      isSms.value = false;
      circleSession = provider;
    }
    if (ret is api.LoginState_NeedsSMS2FA) {
      mcs.invokeMethod("circle-proximity-session", {
        'sid': null
      });
      var options = await api.get2FaSmsOpts(state: currentAppleAccount!);
      if (options.$2 != null) {
        ret = options.$2!;
      } else if (options.$1.length == 1) {
        ret = await api.send2FaSms(locked: circleSession, account: currentAppleAccount!, phoneId: options.$1[0].id);
        circleSession = null;
      } else {
        int selectedRadio = -1;
        await showDialog(
          context: Get.context!,
          builder: (context) => AlertDialog(
            title: const Text('Choose number'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.$1.map((e) => RadioListTile(
                      value: e.id,
                      groupValue: selectedRadio,
                      title: Text(e.numberWithDialCode),
                      onChanged: (val) {
                        setState(() {
                          selectedRadio = val!;
                        });
                      },
                    )).toList(),
                );
              },
            ),
            actions: <Widget>[
              TextButton(
                      onPressed: () {
                        selectedRadio = -1;
                        Get.back();
                      },
                      child: Text("Cancel", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary))),
              TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: Text("OK", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary))),
            ],
          ),
        );
        if (selectedRadio == -1) {
          return ret;
        }
        ret = await api.send2FaSms(locked: circleSession, account: currentAppleAccount!, phoneId: options.$1[0].id);
        circleSession = null;
      }
      isSms.value = true;
    }
    state = ret;
    if (ret is api.LoginState_LoggedIn) {
      mcs.invokeMethod("circle-proximity-session", {
        'sid': null
      });
      ss.settings.userName.value = await api.getUserName(state: currentAppleAccount!);
      await doRegister();
    }
    return ret;
  }

  Future<T> wrapPromise<T>(Future<T> inner, String text) async {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.theme.colorScheme.properSurface,
          title: Text(
            text,
            style: context.theme.textTheme.titleLarge,
          ),
          content: Container(
            height: 70,
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: context.theme.colorScheme.properSurface,
                valueColor: AlwaysStoppedAnimation<Color>(context.theme.colorScheme.primary),
              ),
            ),
          ),
        );
      }
    );
    T result;
    try {
      result = await inner;
    } catch (e, s) {
      Get.back();
      showSnackbar("Failure! Please try again", e.toString());
      rethrow;
    }
    Get.back();
    return result;
  }

  Future<void> doRegister() async {
    List<api.IdsUser> users = [];

    if (currentAppleUser != null) {
      users.add(currentAppleUser!);
    }

    if (currentPhoneUsers.isNotEmpty && supportsPhoneReg.value) {
      users.addAll(currentPhoneUsers.values);
    }

    if (users.isEmpty) {
      throw Exception("No users to register!");
    }
      var (newUsers, response) = await api.registerIds(
        path: pushService.statePath,
        aps: connection!,
        identity: identity!, 
        config: config!, 
        // stupid FRB will take ownership for us, so we have to do this
        users: users.map((i) => api.duplicateUser(user: i)).toList(),
      );
      if (response != null) {
        var devInfo = await api.getDeviceInfo(config: config!);
        await showDialog(
          context: Get.context!,
          builder: (context) => AlertDialog(
                backgroundColor: Get.theme.colorScheme.properSurface,
                title: Text(
                  response.title,
                  style: Get.textTheme.titleLarge,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      response.body,
                      style: Get.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "The above message is from Apple.\nWarning: Do not contact Apple support for help with OpenBubbles. Do not mention OpenBubbles. For assistance, join our Discord from our website. If you can't login on this Apple Device, call Apple support. When clicking the contact button below, choose 'Get Started,' not 'Chat,' and then choose 'Apple Device.' Do not mention you are using OpenBubbles.\n${RustPushBBUtils.modelToUser(devInfo.name)}\nS/N: ${devInfo.serial}\nmacOS ${devInfo.osVersion}",
                        textAlign: TextAlign.center,
                        style: Get.textTheme.bodySmall,
                      )
                    ),
                  ],
                ),
                actions: [
                  if (response.action != null)
                    TextButton(
                        onPressed: () => launchUrl(Uri.parse("https://apple.co/IMFT-mac"), mode: LaunchMode.externalApplication),
                        child: Text(response.action!.button, style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary))),
                  TextButton(
                      onPressed: () => Get.back(),
                      child: Text("OK", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary))),
                ],
              ));
        return;
      }

      var imclient = await api.makeImclient(path: pushService.statePath, conn: connection!, users: newUsers!, identity: identity!);
      await ensureWatcher();
      var watcher = api.importWatcher(queue: connReceiver!, client: imclient);

      var clientSession = api.makeClientSession(circle: circleSession);

      var stagingPushState = api.SharedPushState(
        osConfig: config!, 
        cancelPoll: watcher.$1, 
        confDir: pushService.statePath, 
        localBroadcast: watcher.$2, 

        anisette: anisette!, 
        conn: connection!, 
        client: imclient, 

        icloudServices: currentAppleAccount == null ? null : await (() async {
          var tokenProvider = api.makeTokenProvider(account: currentAppleAccount!, config: config!);
          var cloudkit = await api.makeCloudkit(path: pushService.statePath, anisette: anisette!, config: config!, tokenProvider: tokenProvider);
          var keychain = cloudkit == null ? null : api.makeKeychain(path: pushService.statePath, cloudkit: cloudkit, anisette: anisette!, config: config!, tokenProvider: tokenProvider);
          return api.SharedICloudServices(
            account: currentAppleAccount!, 
            tokenProvider: tokenProvider, 
            
            cloudkitClient: cloudkit,
            keychain: keychain,
            passwords: keychain == null ? null : await api.makePasswords(path: pushService.statePath, keychain: keychain, cloudkit: cloudkit!, client: imclient, conn: connection!),
            profilesClient: await api.makeProfiles(cloudkit: cloudkit!),
            fmfd: keychain == null ? null : await api.makeFindmy(path: pushService.statePath, tokenProvider: tokenProvider, conn: connection!, cloudkit: cloudkit, keychain: keychain, anisette: anisette!, config: config!, client: imclient), 
            sharedstreams: await api.makeSharedStreams(path: pushService.statePath, conn: connection!, anisette: anisette!, config: config!, token: tokenProvider),
            cloudMessagesClient: api.makeCloudMessagesClient(cloudkit: cloudkit, keychain: keychain!),
            statuskitClient: await api.makeStatuskit(path: pushService.statePath, provider: tokenProvider, conn: connection!, config: config!, client: imclient),
          );
        })(),

        ftClient: await api.makeFacetime(path: pushService.statePath, conn: connection!, client: imclient), 
        idmsClient: connListener!, 
        activeCircleSessions: api.makeCircleSessions(), 
        clientSession: clientSession,
      );

      if (Platform.isAndroid) {
        var (daemon, pushState) = api.sendDaemon(state: stagingPushState, watcher: watcher.$3);
        pushService.state = pushState;
        mcs.invokeMethod("provision-native", {"native": daemon});
      } else {
        var (pollState, deskState) = api.dupDaemonDesk(state: stagingPushState);
        pushService.state = deskState;
        pushService.doPoll(watcher.$3, pollState);
      }

      success = true;
      // persisting SMS auth certs is actually really useful
      // ss.settings.cachedCodes.clear();
      Logger.debug("Success registered!");
      if (ss.settings.deviceIsHosted.value) {
        pushService.mixpanel?.track("hosted-setup-success");
      }
      await pushService.configured();

      var handles = await api.getHandles(state: pushService.state!.client);
      var phone = handles.firstWhereOrNull((h) => h.startsWith("tel:"));
      if (phone != null) {
        ss.settings.defaultHandle.value = phone;
        ss.saveSettings();
      }

      var keychain = pushService.state?.icloudServices?.keychain;
      if (keychain != null && circleSession != null) {
        var defaultPassword = Random.secure().nextInt(1000000).toString().padLeft(6, '0');
        ss.settings.keychainDefaultPassword.value = defaultPassword;
        ss.saveSettings();

        await api.circleSetupClique(client: pushService.state!.clientSession, keychain: keychain, devicePassword: defaultPassword);
      }

      Logger.debug("Finishing!");
      setup.finishSetup();
  }

  Future<void> cacheCode(String code) async {
    if (ss.settings.cachedCodes.containsKey(code)) {
      return;
    }

    String hash = hex.encode(sha256.convert(code.codeUnits).bytes);

    final response = await http.dio.get(
      "$rpApiRoot/$hash",
      options: Options(
        headers: {
          "X-OpenBubbles-Get": ""
        },
      )
    );

    if (response.statusCode == 404) {
      return;
    }

    var data = response.data["data"];
    
     var myData = Uint8List.fromList(decryptAESCryptoJS(data, code));
    Logger.debug("cached code");
    ss.settings.cachedCodes[code] = base64Encode(myData);
    ss.saveSettings();
  }

  Future<void> ensureWatcher() async {
    if (connReceiver != null) return;
    connReceiver = api.subscribeConn(conn: connection!);
    connListener = await api.makeIdms(conn: connection!);
  }

  void destroyConnection() {
    connReceiver?.dispose();
    connReceiver = null;

    connListener?.dispose();
    connListener = null;

    connection?.dispose();
    connection = null;
  }
  

  Future<api.LoginState> submitCode(String code) async {
    if (state is api.LoginState_Needs2FAVerification) {
      var (dart, isAnnoying) = await api.verify2Fa(
        path: pushService.statePath,
        client: circleSession!,
        anisette: anisette!, 
        osConfig: config!,
        watcher: connReceiver!,
        idms: connListener!,


        account: currentAppleAccount!,
        code: code
      );
      state = dart;
      currentAppleUser = isAnnoying;
    } else if (state is api.LoginState_NeedsSMS2FAVerification) {
      var myState = state as api.LoginState_NeedsSMS2FAVerification;
      var (dart, isAnnoying) = await api.verify2FaSms(
        path: pushService.statePath,
        accountMut: currentAppleAccount!,
        anisette: anisette!, 
        config: config!, 

        body: myState.field0, 
        code: code
      );
      state = dart;
      currentAppleUser = isAnnoying;
    }
    return await updateLoginState(state);
  }

  (String, String)? twoFaCreds;

  int get pageOfNoReturn => kIsWeb || kIsDesktop ? 3 : 5;

  Future<void> restoreTicket(String ticket, Duration length) async {
    token = ticket;
    tokenExpiry = DateTime.now().add(length);
    if (availableIAP.value == null) {
      await updateIAPState();
    }
  }

  Future<void> configureHostedDevice(api.JoinedOsConfig newConfig) async {

      identity = api.newNgmIdentity();
      config = newConfig;
      cachedState = null;
      destroyConnection();

      api.resetAnisette(path: pushService.statePath);
      anisette?.dispose();
      anisette = null;


      currentPhoneUsers = {}; // reset validated phone numbers as we have a new token now
      var list = ss.settings.cachedCodes.entries.toList();
      for (var items in list) {
        if (!items.key.startsWith("sms-auth-")) continue;
        ss.settings.cachedCodes.remove(items.key);
      }
      ss.saveSettings();

      await setupConnection();
  }

  Future<void> setupConnection() async {
    var data = await api.setupPush(config: config!, identity: identity!, statePath: pushService.statePath, state: cachedState);
    connection = data.$1;
    anisette = await api.makeAnisette(path: pushService.statePath, config: config!, conn: connection!);
  }

  void updatePage(int newPage) {
    currentPage = newPage;
    updateWidgets<PageNumber>(newPage);
  }

  void updateNumberToDownload(int num) {
    numberToDownload = num;
    updateWidgets<NumberOfMessagesText>(num);
  }

  void handleOfflineError(String newError, String? currentTicket) {
    if (newError.contains("Device not reserved!")) {
      destroyConnection();
      config = null;
      tokenExpiry = DateTime.fromMillisecondsSinceEpoch(0);
      token = null;
      pageController.jumpToPage(4);
    }

    if (newError.contains("Sorry, your hosted device is currently offline!")) {
      showDialog(
        context: Get.context!,
        builder: (context) => AlertDialog(
          title: Text(
            "Sorry, your hosted device is currently offline!",
            style: context.theme.textTheme.titleLarge,
          ),
          backgroundColor: context.theme.colorScheme.properSurface,
          content: Text("You can wait for it to come back, or change your device.", style: context.theme.textTheme.bodyLarge),
          actions: [
            TextButton(
              child: Text(
                  "Cancel",
                  style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                  "Change",
                  style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)
              ),
              onPressed: () {
                Navigator.of(context).pop();
                wrapPromise((() async {
                  var relay = currentTicket ?? await api.validateRelay(configRef: this.config!);
                  if (relay == null) {
                    throw Exception("Failed to validate!");
                  }
                  final status = await http.dio.post("https://hw.openbubbles.app/swap-token", options: Options(
                    headers: {
                      "Authorization": "Bearer $relay"
                    }
                  ));

                  if (status.statusCode != 200) {
                    if (status.data.toString().contains("No device available!")) {
                      Timer(const Duration(milliseconds: 100), () => pushService.offerHostedRefund(false));
                    }
                    throw Exception("Failed to swap ${status.statusCode} ${status.data.toString()}");
                  }

                  var newTicket = status.data["new_ticket"];

                  var config = await api.configFromRelay(code: newTicket, host: "https://hw.openbubbles.app");
                  await configureHostedDevice(config);

                  pageController.jumpToPage(4);
                  updateConnectError('');
                })(), "Changing device...");
              },
            ),
          ],
        ),
      );
    }
  }

  void updateConnectError(String newError) {
    handleOfflineError(newError, null);
    if (newError.contains("6005") && currentPhoneUsers.isNotEmpty) {
      for (var user in currentPhoneUsers.keys) {
        ss.settings.cachedCodes.remove("sms-auth-$user");
        ss.saveSettings();
      }

      currentPhoneUsers.clear();

      newError = "Phone Number validation failed, please re-authenticate!";
      updateWidgets<ErrorText>(newError);
      pageController.jumpToPage(5);
      return;
    }
    error = newError;
    if (ss.settings.deviceIsHosted.value && errorIsProblem()) {
      pushService.mixpanel?.track("hosted-setup-error");
    }
    updateWidgets<ErrorText>(newError);
  }
}

class SetupView extends StatefulWidget {
  (ApsConnection, ApsState, api.JoinedOsConfig, api.IdsngmIdentity, ArcAnisetteClientDefaultAnisetteProvider)? prefix;

  SetupView({super.key, this.prefix});

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends OptimizedState<SetupView> {
  final controller = Get.put(SetupViewController(), permanent: true);

  @override
  void initState() {
    super.initState();

    (() async {
      if (ss.settings.cachedCodes.containsKey("sms-auth")) {
        ss.settings.cachedCodes["sms-auth-1"] = ss.settings.cachedCodes["sms-auth"]!;
        ss.settings.cachedCodes.remove("sms-auth");
        ss.saveSettings();
        Logger.debug("Migrated sms auth");
      }
      await pushService.initFuture; // wait for ready

      var restored = api.readHardware(path: pushService.statePath);

      if (widget.prefix != null) {
        controller.connection = widget.prefix!.$1;
        controller.cachedState = widget.prefix!.$2;
        controller.config = widget.prefix!.$3;
        controller.identity = widget.prefix!.$4;
        controller.anisette = widget.prefix!.$5;
      }

      if (restored != null && pushService.state == null && controller.connection == null) {
        controller.identity = api.decodeIdentity(identity: restored.identity);
        controller.config = restored.osConfig;
        controller.cachedState = restored.push;
        await controller.setupConnection();
      }

      var dumb = File("${pushService.statePath}/dumb");
      if (restored == null && dumb.existsSync()) {
        ss.settings.isDumb.value = true;
        ss.settings.macIsMine.value = false;
        await ss.saveSettings();
        try {
          var list = base64Decode(dumb.readAsStringSync()).toList();
          list.removeRange(0, 5);
          var imported = await api.configFromEncoded(encoded: list);
          controller.config = imported;
          controller.identity = api.newNgmIdentity();
          await controller.setupConnection();
        } catch (e, s) {
          Logger.error("Failed to setup dumb", error: e, trace: s);
        }
      }

      var list = ss.settings.cachedCodes.entries.toList();
      for (var items in list) {
        if (!items.key.startsWith("sms-auth-")) continue;

        controller.phoneValidating.value = true;
        try {
          var user = await api.restoreUser(user: items.value);
          Logger.info("restore validating!");
          await api.validateCert(conn: controller.connection!, user: user);
          Logger.info("restore validated");
          controller.currentPhoneUsers[int.parse(items.key.replaceFirst("sms-auth-", ""))] = user;
        } catch (e) {
          Logger.info("restore resetting! $e");
          ss.settings.cachedCodes.remove(items.key);
          ss.saveSettings();
          continue;
        } finally {
          Logger.info("restore done!");
          controller.phoneValidating.value = false;
        }

      }
    })();

    (() async {

      try {
        await controller.updateIAPState();
      } catch (e, s) {
        Logger.error("failed to fetch IAP state", error: e, trace: s);
      }
      final _appLinks = AppLinks();
      var link = await _appLinks.getLatestLink();

      _appLinks.uriLinkStream.listen((uri) async {
        var text = uri.toString();
        Logger.info("Got uri stream $text");
        var ticketheader = "https://hw.openbubbles.app/ticket/";
        if (text.startsWith(ticketheader)) {
          controller.restoreTicket(text.replaceFirst(ticketheader, ""), const Duration(minutes: 15));
          return;
        }
        var waitlistheader = "https://hw.openbubbles.app/waitlist/";
        if (text.startsWith(waitlistheader)) {
          controller.currentWaitlist = text.replaceFirst(waitlistheader, "");
          controller.updateIAPState();
          return;
        }
        var header = "$rpApiRoot/";
        if (text.startsWith(header)) {
          Logger.debug("caching code");
          await controller.cacheCode(text.replaceFirst(header, ""));
          controller._childKey.currentState?.updateInitial();
        }
      });

      if (link != null) {
        var text = link.toString();
        var ticketheader = "https://hw.openbubbles.app/ticket/";
        if (text.startsWith(ticketheader)) {
          controller.restoreTicket(text.replaceFirst(ticketheader, ""), const Duration(minutes: 15));
          return;
        }
        var waitlistheader = "https://hw.openbubbles.app/waitlist/";
        if (text.startsWith(waitlistheader)) {
          controller.currentWaitlist = text.replaceFirst(waitlistheader, "");
          controller.updateIAPState();
          return;
        }
        var header = "$rpApiRoot/";
        if (text.startsWith(header)) {
          Logger.debug("caching code");
          await controller.cacheCode(text.replaceFirst(header, ""));
        }
      }
    })();

    ever(socket.state, (event) {
      if (event == SocketState.error
          && !ss.settings.finishedSetup.value
          && controller.pageController.hasClients
          && controller.currentPage > controller.pageOfNoReturn) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => FailedToConnectDialog(
            onDismiss: () {
              controller.pageController.animateToPage(
                controller.pageOfNoReturn - 1,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
              Navigator.of(context).pop();
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ss.settings.windowEffect.value != WindowEffect.disabled ? Colors.transparent : context.theme.colorScheme.background,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              SetupHeader(),
              const SizedBox(height: 20),
              SetupPages(),
            ],
          ),
        ),
      ),
    );
  }
}

class SetupHeader extends StatelessWidget {
  final SetupViewController controller = Get.find<SetupViewController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: kIsDesktop ? 40 : 20, left: 20, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Hero(
                tag: "setup-icon",
                child: Image.asset("assets/icon/icon.png", width: 30, fit: BoxFit.contain)
              ),
              const SizedBox(width: 10),
              Text(
                "OpenBubbles",
                style: context.theme.textTheme.bodyLarge!.apply(fontWeightDelta: 2, fontSizeFactor: 1.35),
              ),
            ],
          ),
          PageNumber(parentController: controller),
        ],
      ),
    );
  }
}

class PageNumber extends CustomStateful<SetupViewController> {
  PageNumber({required super.parentController});

  @override
  State<StatefulWidget> createState() => _PageNumberState();
}

class _PageNumberState extends CustomState<PageNumber, int, SetupViewController> {

  @override
  void updateWidget(int newVal) {
    controller.currentPage = newVal;
    super.updateWidget(newVal);
  }

  @override
  Widget build(BuildContext context) {
    return controller.currentPage == 1 ? const SizedBox.square(dimension: 40.0,) : Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          colors: [HexColor('2772C3'), HexColor('5CA7F8').darkenPercent(5)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 13),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "${controller.currentPage}",
                style: context.theme.textTheme.bodyLarge!.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
              ),
              TextSpan(
                text: " of ${kIsWeb ? "4" : kIsDesktop ? "5" : "9"}",
                style: context.theme.textTheme.bodyLarge!.copyWith(color: Colors.white38, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SetupPages extends StatelessWidget {
  final SetupViewController controller = Get.find<SetupViewController>();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() => PageView(
        onPageChanged: (page) {
          // skip pages if the things required are already complete
          if (!kIsWeb && !kIsDesktop && page == 1 && controller.currentPage == 1 && !ss.settings.isDumb.value) {
            Permission.contacts.status.then((status) {
              if (status.isGranted) {
                controller.pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
          if (!kIsWeb && !kIsDesktop && page == 2 && controller.currentPage == 2 && !ss.settings.isDumb.value) {
            DisableBatteryOptimization.isAllBatteryOptimizationDisabled.then((isDisabled) {
              if (isDisabled ?? false) {
                controller.pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
          if (!kIsWeb && !kIsDesktop && page == 3 && controller.currentPage == 3 && !ss.settings.isDumb.value) {
            mcs.invokeMethod("enable-bt").then((isEnabled) {
              if (isEnabled ?? false) {
                controller.pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
          controller.updatePage(page + 1);
        },
        physics: const NeverScrollableScrollPhysics(),
        controller: controller.pageController,
        children: <Widget>[
          if (!ss.settings.isDumb.value)
          WelcomePage(),
          if (!kIsWeb && !kIsDesktop && !ss.settings.isDumb.value) RequestContacts(),
          if (!kIsWeb && !kIsDesktop && !ss.settings.isDumb.value) BatteryOptimizationCheck(),
          if (!kIsWeb && !kIsDesktop && !ss.settings.isDumb.value) RequestBluetooth(),
          if (!usingRustPush)
            MacSetupCheck(),
          if (!usingRustPush)
            ServerCredentials(),
          if (!kIsWeb && !usingRustPush)
            SyncSettings(),
          if (!usingRustPush)
            SyncProgress(),
          if (usingRustPush && !ss.settings.isDumb.value)
            HwInp(key: controller._childKey),
          if (usingRustPush && controller.supportsPhoneReg.value && !kIsDesktop)
            const PhoneNumber(),
          if (usingRustPush)
            AppleIdLogin(),
          if (usingRustPush)
            AppleId2FA(),
          if (usingRustPush)
            FinalizePage(),
          //ThemeSelector(),
        ],
      ),)
    );
  }
}


class ErrorText extends CustomStateful<SetupViewController> {
  ErrorText({required super.parentController});

  @override
  State<StatefulWidget> createState() => _ErrorTextState();
}

class _ErrorTextState extends CustomState<ErrorText, String, SetupViewController> {
  @override
  void updateWidget(String newVal) {
    controller.error = newVal;
    super.updateWidget(newVal);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.error.isNotEmpty)
          Container(
            width: context.width * 2 / 3,
            child: Align(
              alignment: Alignment.center,
              child: SelectableText(controller.error,
                  style: context.theme.textTheme.bodyLarge!
                      .apply(
                        fontSizeDelta: 1.5,
                        color: context.theme.colorScheme.error,
                      )
                      .copyWith(height: 2)),
            ),
          ),
        if (controller.errorIsProblem())
        TextButton(
          onPressed: () async {
            final TextEditingController participantController = TextEditingController();
            final TextEditingController details = TextEditingController();
            Uint8List? attachment;
            showDialog(
              context: context,
              builder: (_) {
                return AlertDialog(
                  actions: [
                    TextButton(
                      child: Text("Cancel", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                      onPressed: () => Get.back(),
                    ),
                    TextButton(
                      child: Text("Screenshot", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                      onPressed: () async {
                        final res = await picker.FilePicker.platform.pickFiles(withData: true, type: picker.FileType.custom, allowedExtensions: ['png', 'jpg', 'jpeg']);
                        if (res == null || res.count == 0) return;
                        attachment = await File(res.files[0].path!).readAsBytes();
                        showSnackbar("Notice", "Screenshot added");
                      },
                    ),
                    TextButton(
                      child: Text("OK", style: context.theme.textTheme.bodyLarge!.copyWith(color: context.theme.colorScheme.primary)),
                      onPressed: () async {
                        if (participantController.text.isEmpty) return;
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: context.theme.colorScheme.properSurface,
                              title: Text(
                                "Uploading log...",
                                style: context.theme.textTheme.titleLarge,
                              ),
                              content: Container(
                                height: 70,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    backgroundColor: context.theme.colorScheme.properSurface,
                                    valueColor: AlwaysStoppedAnimation<Color>(context.theme.colorScheme.primary),
                                  ),
                                ),
                              ),
                            );
                          }
                        );
                        
                        // 
                        var file = Directory(Platform.isAndroid ? "${fs.appDocDir.path}/../files/logs" : "${fs.appDocDir.path}/logs");
                        final List<FileSystemEntity> entities = await file.list().toList();
                        var current = entities.indexWhere((element) => element.path.endsWith("CURRENT.log"));
                        var item = entities.removeAt(current);
                        var end = await File(item.path).readAsBytes();
                        var b = BytesBuilder();
                        if (entities.isNotEmpty) {
                          var next = await File(entities.first.path).readAsBytes();
                          b.add(next);
                        }
                        b.add(end);
                        var total = b.toBytes();

                        Map<String, dynamic> deviceInfo = {};

                        var config = controller.config;
                        if (config != null) {
                          var info = await api.getDeviceInfo(config: config);
                          deviceInfo = {
                            "name": info.name,
                            "serial": info.serial,
                            "os_version": info.osVersion,
                            "encoded_data": info.encodedData != null ? base64Encode(info.encodedData!) : ""
                          };
                        }

                        // stop stupid automatic cralwers from spamming the webhook
                        var url = dotenv.get('REPORT_ISSUE_WEBHOOK');

                        try {
                          final response = await http.dio.post(
                              url,
                              data: FormData.fromMap({
                                "content": "Desc: ${details.text}\nEmail: ${participantController.text}\nError: ${controller.error}\nHosted: ${ss.settings.deviceIsHosted.value}",
                                "username": "Onboarding",
                                "files[0]": MultipartFile.fromBytes(total, filename: "rustpush-logs.log"),
                                "files[1]": MultipartFile.fromString(jsonEncode(deviceInfo), filename: "hardware.json"),
                                if (attachment != null)
                                "files[2]": MultipartFile.fromBytes(attachment!, filename: "screenshot.png")
                              }),
                          );

                          if (response.statusCode == 200) {
                            Get.back();
                            Get.back();
                            showSnackbar("Notice", "Logs sent! Thank you!");
                          } else {
                            Get.back();
                            Logger.error(response.toString());
                            showSnackbar("Error", "There was an issue sending logs");
                          }
                        } catch(e, s) {
                          Get.back();
                          Logger.error("failed", error: e, trace: s);
                          showSnackbar("Error", "There was an issue sending logs $e");
                        }
                      },
                    ),
                  ],
                  content: Column(children: [
                    const Text("Logs and Apple device identifiers will be sent to developer for review. Logs may contain personal identifiers and 48 hours of message and chat history. Do not submit logs containing sensitive chats or messages. Your logs will be shared with Discord for storage subject to their Privacy Policy."),
                    const SizedBox(height: 16,),
                    TextField(
                      controller: participantController,
                      decoration: const InputDecoration(
                        labelText: "Your email",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                    ),
                    const SizedBox(height: 16,),
                    TextField(
                      controller: details,
                      decoration: const InputDecoration(
                        labelText: "Optional details",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                    )
                  ],
                  mainAxisSize: MainAxisSize.min,),
                  title: Text("Report issue", style: context.theme.textTheme.titleLarge),
                  backgroundColor: context.theme.colorScheme.properSurface,
                );
              }
            );
          },
          child: Text(
            "Report Error",
            style: context.theme.textTheme.bodyMedium!.apply(color:context.theme.colorScheme.error, decoration: TextDecoration.underline)
          )
        ),
        if (controller.error.isNotEmpty) const SizedBox(height: 20),
      ],
    );
  }
}
