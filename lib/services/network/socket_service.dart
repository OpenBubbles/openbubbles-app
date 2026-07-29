import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bluebubbles/helpers/backend/settings_helpers.dart';
import 'package:bluebubbles/utils/crypto_utils.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart';

SocketService socket = Get.isRegistered<SocketService>() ? Get.find<SocketService>() : Get.put(SocketService());

enum SocketState {
  connected,
  disconnected,
  error,
  connecting,
}

class SocketService extends GetxService {
  final Rx<SocketState> state = SocketState.disconnected.obs;
  SocketState _lastState = SocketState.disconnected;
  RxString lastError = "".obs;
  Timer? _reconnectTimer;
  int _connectionGeneration = 0;
  int _reconnectEpoch = 0;
  int _reconnectAttempt = 0;
  late Socket socket;

  String get serverAddress => http.origin;
  String get password => ss.settings.guidAuthKey.value;

  @override
  void onInit() {
    super.onInit();

    Logger.debug("Initializing socket service...");
    startSocket();
    Connectivity().onConnectivityChanged.listen((event) {
      if (!event.contains(ConnectivityResult.wifi) &&
          !event.contains(ConnectivityResult.ethernet) &&
          http.originOverride != null) {
        Logger.info("Detected switch off wifi, removing localhost address...");
        http.originOverride = null;
      }
    });
    Logger.debug("Initialized socket service");
  }

  @override
  void onClose() {
    closeSocket();
    super.onClose();
  }

  void startSocket() {
    _cancelReconnect();
    final generation = ++_connectionGeneration;
    OptionBuilder options = OptionBuilder()
        .setQuery({"guid": password})
        .setTransports(['websocket', 'polling'])
        .setExtraHeaders(http.headers)
        // Disable so that we can create the listeners first
        .disableAutoConnect()
        // Reconnection is owned here so that URL refresh and socket creation
        // cannot race the Socket.IO manager's own retry loop.
        .disableReconnection();
    socket = io(serverAddress, options.build());
    // placed here so that [socket] is still initialized
    if (isNullOrEmpty(serverAddress)) return;

    socket.onConnect((data) => handleStatusUpdate(SocketState.connected, data, generation: generation));
    socket.onReconnect((data) => handleStatusUpdate(SocketState.connected, data, generation: generation));

    socket.onReconnectAttempt((data) => handleStatusUpdate(SocketState.connecting, data, generation: generation));
    socket.onReconnecting((data) => handleStatusUpdate(SocketState.connecting, data, generation: generation));
    socket.onConnecting((data) => handleStatusUpdate(SocketState.connecting, data, generation: generation));

    socket.onDisconnect((data) => handleStatusUpdate(SocketState.disconnected, data, generation: generation));

    socket.onConnectError((data) => handleStatusUpdate(SocketState.error, data, generation: generation));
    socket.onConnectTimeout((data) => handleStatusUpdate(SocketState.error, data, generation: generation));
    socket.onError((data) => handleStatusUpdate(SocketState.error, data, generation: generation));

    // custom events
    // only listen to these events from socket on web/desktop (FCM handles on Android)
    if (kIsWeb || kIsDesktop) {
      socket.on("group-name-change", (data) => ah.handleEvent("group-name-change", data, 'DartSocket'));
      socket.on("participant-removed", (data) => ah.handleEvent("participant-removed", data, 'DartSocket'));
      socket.on("participant-added", (data) => ah.handleEvent("participant-added", data, 'DartSocket'));
      socket.on("participant-left", (data) => ah.handleEvent("participant-left", data, 'DartSocket'));
      socket.on("incoming-facetime", (data) => ah.handleEvent("incoming-facetime", jsonDecode(data), 'DartSocket'));
    }

    socket.on("ft-call-status-changed", (data) => ah.handleEvent("ft-call-status-changed", data, 'DartSocket'));
    socket.on("new-message", (data) => ah.handleEvent("new-message", data, 'DartSocket'));
    socket.on("updated-message", (data) => ah.handleEvent("updated-message", data, 'DartSocket'));
    socket.on("typing-indicator", (data) => ah.handleEvent("typing-indicator", data, 'DartSocket'));
    socket.on("chat-read-status-changed", (data) => ah.handleEvent("chat-read-status-changed", data, 'DartSocket'));
    socket.on("imessage-aliases-removed", (data) => ah.handleEvent("imessage-aliases-removed", data, 'DartSocket'));

    socket.connect();
  }

  void disconnect() {
    _cancelReconnect();
    _connectionGeneration++;
    if (isNullOrEmpty(serverAddress)) return;
    socket.disconnect();
    state.value = SocketState.disconnected;
  }

  void reconnect() {
    if (state.value == SocketState.connected || isNullOrEmpty(serverAddress)) return;
    _cancelReconnect();
    state.value = SocketState.connecting;
    socket.connect();
  }

  void closeSocket() {
    _cancelReconnect();
    _connectionGeneration++;
    if (isNullOrEmpty(serverAddress)) return;
    socket.dispose();
    state.value = SocketState.disconnected;
  }

  void restartSocket() {
    closeSocket();
    startSocket();
  }

  void forgetConnection() {
    closeSocket();
    ss.settings.guidAuthKey.value = "";
    clearServerUrl(saveAdditionalSettings: ["guidAuthKey"]);
  }

  Future<Map<String, dynamic>> sendMessage(String event, Map<String, dynamic> message) {
    Completer<Map<String, dynamic>> completer = Completer();

    socket.emitWithAck(event, message, ack: (response) {
      if (response['encrypted'] == true) {
        response['data'] = jsonDecode(utf8.decode(decryptAESCryptoJS(response['data'], password)));
      }

      if (!completer.isCompleted) {
        completer.complete(response);
      }
    });

    return completer.future;
  }

  void handleStatusUpdate(SocketState status, dynamic data, {int? generation}) {
    if (generation != null && generation != _connectionGeneration) return;
    if (_lastState == status) return;
    _lastState = status;

    switch (status) {
      case SocketState.connected:
        state.value = SocketState.connected;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        _reconnectEpoch++;
        _reconnectAttempt = 0;
        NetworkTasks.onConnect();
        notif.clearSocketError();
        return;
      case SocketState.disconnected:
        Logger.info("Disconnected from socket...");
        state.value = SocketState.disconnected;
        _scheduleReconnect();
        return;
      case SocketState.connecting:
        Logger.info("Connecting to socket...");
        state.value = SocketState.connecting;
        return;
      case SocketState.error:
        Logger.info("Socket connect error, fetching new URL...");

        if (data is SocketException) {
          handleSocketException(data);
        }

        state.value = SocketState.error;
        _scheduleReconnect();
        return;
      default:
        return;
    }
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectEpoch++;
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null || state.value == SocketState.connected || isNullOrEmpty(serverAddress)) return;

    final epoch = _reconnectEpoch;
    final generation = _connectionGeneration;
    final attempt = _reconnectAttempt > 3 ? 3 : _reconnectAttempt;
    final seconds = 5 * (1 << attempt);
    if (_reconnectAttempt < 3) _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), () async {
      _reconnectTimer = null;
      if (epoch != _reconnectEpoch || generation != _connectionGeneration || state.value == SocketState.connected) return;

      try {
        await fdb.fetchNewUrl(restartSocket: false, tryRestartForegroundService: false);
      } catch (e, s) {
        Logger.warn("Failed to refresh socket URL before reconnect", error: e, trace: s);
        _scheduleReconnect();
        return;
      }

      if (epoch != _reconnectEpoch || generation != _connectionGeneration) return;
      restartSocket();

      if (state.value != SocketState.connected && !ss.settings.keepAppAlive.value) {
        notif.createSocketError();
      }
    });
  }

  void handleSocketException(SocketException e) {
    String msg = e.message;
    if (msg.contains("Failed host lookup")) {
      lastError.value = "Failed to resolve hostname";
    } else {
      lastError.value = msg;
    }
  }
}
