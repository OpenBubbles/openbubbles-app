package com.bluebubbles.messaging.services.system

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import com.bluebubbles.messaging.models.MethodCallHandlerImpl
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Foreground-only, user-triggered nearby sound support for compatible Find My trackers.
 *
 * The protocol compatibility was informed by the Apache-2.0 AirGuard project, especially
 * its AppleFindMy model and BluetoothLeService. This is an original, deliberately narrow
 * implementation: it never exposes addresses or advertisement bytes, and it does not run
 * in the background or claim ownership of a discovered tracker.
 */
class NearbyFindMyAccessoryHandler private constructor() : MethodCallHandlerImpl() {
    companion object {
        const val scanTag = "scanNearbyFindMyAccessories"
        const val playTag = "playNearbyFindMyAccessorySound"

        val instance: NearbyFindMyAccessoryHandler by lazy { NearbyFindMyAccessoryHandler() }

        private const val defaultScanDurationMs = 8_000L
        private const val minScanDurationMs = 3_000L
        private const val maxScanDurationMs = 15_000L
        private const val tokenLifetimeMs = 60_000L
        private const val soundDurationMs = 5_000L
        private const val operationTimeoutMs = 20_000L
        private const val cccdUuidString = "00002902-0000-1000-8000-00805f9b34fb"
        private const val appleManufacturerId = 0x004C
        private const val findMyAdvertisementType = 0x12
        private const val separatedFindMyAdvertisementType = 0x19

        private val dultServiceUuid = UUID.fromString("15190001-12F4-C226-88ED-2AC5579F2A85")
        private val dultCharacteristicUuid = UUID.fromString("8E0C0001-1D68-FB92-BF61-48377421680E")
        private val findMyCharacteristicUuid = UUID.fromString("4F860003-943B-49EF-BED4-2F730304427A")
        private val airtagServiceUuid = UUID.fromString("7DFC9000-7D1C-4951-86AA-8D9728F8D66C")
        private val airtagCharacteristicUuid = UUID.fromString("7DFC9001-7D1C-4951-86AA-8D9728F8D66C")
    }

    private enum class Protocol(val wireName: String) {
        DULT("dult"),
        FIND_MY("find_my"),
        AIRTAG("airtag")
    }

    private enum class CommandPhase { START, STOP }

    private data class TokenEntry(
        val device: BluetoothDevice,
        val protocol: Protocol,
        val expiresAtMs: Long,
    )

    private val mainHandler = Handler(Looper.getMainLooper())
    private val tokenLock = Any()
    private val tokens = HashMap<String, TokenEntry>()
    private var activeScan: ScanOperation? = null

    override fun handleMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
        context: Context,
    ) {
        when (call.method) {
            scanTag -> scan(call, result, context)
            playTag -> play(call, result, context)
            else -> result.error("NOT_IMPLEMENTED", "Unsupported nearby Find My method", null)
        }
    }

    private fun scan(call: MethodCall, result: MethodChannel.Result, context: Context) {
        val once = OnceResult(result)
        if (!isUsableForeground(context)) {
            once.error("FOREGROUND_REQUIRED", "Nearby tracker actions require the app to be open", null)
            return
        }

        val permissionError = permissionError(context, requireConnect = true)
        if (permissionError != null) {
            once.error("PERMISSION_DENIED", permissionError, null)
            return
        }

        val adapter = bluetoothAdapter(context)
        if (adapter == null) {
            once.error("BLUETOOTH_UNAVAILABLE", "This device does not provide Bluetooth", null)
            return
        }
        if (!adapter.isEnabled) {
            once.error("BLUETOOTH_DISABLED", "Bluetooth is turned off", null)
            return
        }

        val scanner = try {
            adapter.bluetoothLeScanner
        } catch (_: SecurityException) {
            null
        }
        if (scanner == null) {
            once.error("BLUETOOTH_UNAVAILABLE", "Bluetooth scanning is unavailable", null)
            return
        }

        val requestedDuration = call.argument<Number>("scanDurationMs")?.toLong() ?: defaultScanDurationMs
        val durationMs = requestedDuration.coerceIn(minScanDurationMs, maxScanDurationMs)
        synchronized(tokenLock) {
            expireTokensLocked(System.currentTimeMillis())
            if (activeScan != null) {
                once.error("SCAN_IN_PROGRESS", "A nearby tracker scan is already running", null)
                return
            }
            val operation = ScanOperation(context.applicationContext, scanner, once, durationMs)
            activeScan = operation
            operation.start()
        }
    }

    private fun play(call: MethodCall, result: MethodChannel.Result, context: Context) {
        val once = OnceResult(result)
        if (!isUsableForeground(context)) {
            once.error("FOREGROUND_REQUIRED", "Nearby tracker actions require the app to be open", null)
            return
        }

        val permissionError = permissionError(context, requireConnect = true)
        if (permissionError != null) {
            once.error("PERMISSION_DENIED", permissionError, null)
            return
        }

        val token = call.argument<String>("token")?.trim()
        if (token.isNullOrEmpty()) {
            once.error("INVALID_TOKEN", "A nearby tracker token is required", null)
            return
        }

        val entry = synchronized(tokenLock) {
            expireTokensLocked(System.currentTimeMillis())
            tokens.remove(token)
        }
        if (entry == null) {
            once.error("TOKEN_EXPIRED", "That nearby tracker result has expired", null)
            return
        }

        val adapter = bluetoothAdapter(context)
        if (adapter == null) {
            once.error("BLUETOOTH_UNAVAILABLE", "This device does not provide Bluetooth", null)
            return
        }
        if (!adapter.isEnabled) {
            once.error("BLUETOOTH_DISABLED", "Bluetooth is turned off", null)
            return
        }

        SoundGattSession(context.applicationContext, entry, once).start()
    }

    private fun bluetoothAdapter(context: Context): BluetoothAdapter? {
        val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager ?: return null
        return try {
            manager.adapter
        } catch (_: SecurityException) {
            null
        }
    }

    private fun permissionError(context: Context, requireConnect: Boolean): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
        if (context.checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) {
            return "Nearby device scan permission is not granted"
        }
        if (requireConnect && context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
            return "Nearby device connection permission is not granted"
        }
        return null
    }

    private fun isUsableForeground(context: Context): Boolean {
        val activity = context as? Activity ?: return false
        return !activity.isFinishing && (Build.VERSION.SDK_INT < 17 || !activity.isDestroyed)
    }

    private fun expireTokensLocked(nowMs: Long) {
        tokens.entries.removeIf { it.value.expiresAtMs <= nowMs }
    }

    private inner class ScanOperation(
        private val context: Context,
        private val scanner: BluetoothLeScanner,
        private val result: OnceResult,
        private val durationMs: Long,
    ) {
        private val completed = AtomicBoolean(false)
        private val devicesByAddress = HashMap<String, DiscoveredDevice>()
        private val timeout = Runnable { finishSuccess() }
        private val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, scanResult: ScanResult) {
                record(scanResult)
            }

            override fun onBatchScanResults(results: MutableList<ScanResult>) {
                results.forEach(::record)
            }

            override fun onScanFailed(errorCode: Int) {
                finishError("SCAN_FAILED", "Bluetooth scan failed", errorCode)
            }
        }

        fun start() {
            try {
                scanner.startScan(
                    null,
                    ScanSettings.Builder()
                        .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                        .setReportDelay(0L)
                        .build(),
                    callback,
                )
                mainHandler.postDelayed(timeout, durationMs)
            } catch (_: SecurityException) {
                finishError("PERMISSION_DENIED", "Bluetooth scan permission is not granted", null)
            } catch (_: Exception) {
                finishError("BLUETOOTH_UNAVAILABLE", "Bluetooth scanning is unavailable", null)
            }
        }

        private fun record(scanResult: ScanResult) {
            if (completed.get()) return
            val protocol = protocolFor(scanResult.scanRecord) ?: return
            try {
                val address = scanResult.device.address
                val previous = devicesByAddress[address]
                if (previous == null || scanResult.rssi > previous.rssi) {
                    devicesByAddress[address] = DiscoveredDevice(scanResult.device, protocol, scanResult.rssi)
                }
            } catch (_: SecurityException) {
                finishError("PERMISSION_DENIED", "Bluetooth connection permission is not granted", null)
            }
        }

        private fun finishSuccess() {
            if (!completed.compareAndSet(false, true)) return
            stop()
            val now = System.currentTimeMillis()
            val output = synchronized(tokenLock) {
                expireTokensLocked(now)
                devicesByAddress.values.sortedByDescending { it.rssi }.map { discovered ->
                    val token = UUID.randomUUID().toString()
                    tokens[token] = TokenEntry(
                        device = discovered.device,
                        protocol = discovered.protocol,
                        expiresAtMs = now + tokenLifetimeMs,
                    )
                    mapOf(
                        "token" to token,
                        "protocol" to discovered.protocol.wireName,
                        "signal" to signalFor(discovered.rssi),
                        "rssi" to discovered.rssi,
                    )
                }
            }
            result.success(output)
            synchronized(tokenLock) {
                if (activeScan === this) activeScan = null
            }
        }

        private fun finishError(code: String, message: String, details: Any?) {
            if (!completed.compareAndSet(false, true)) return
            stop()
            result.error(code, message, details)
            synchronized(tokenLock) {
                if (activeScan === this) activeScan = null
            }
        }

        private fun stop() {
            mainHandler.removeCallbacks(timeout)
            try {
                scanner.stopScan(callback)
            } catch (_: SecurityException) {
                // The operation is already completing. Do not call the result twice.
            }
        }
    }

    private data class DiscoveredDevice(
        val device: BluetoothDevice,
        val protocol: Protocol,
        val rssi: Int,
    )

    private inner class SoundGattSession(
        private val context: Context,
        private val entry: TokenEntry,
        private val result: OnceResult,
    ) : BluetoothGattCallback() {
        private val completed = AtomicBoolean(false)
        private val callbackTimeout = Runnable { fail("GATT_TIMEOUT", "The nearby tracker did not respond") }
        private var stopRunnable: Runnable? = null
        private var gatt: BluetoothGatt? = null
        private var characteristic: BluetoothGattCharacteristic? = null
        private var activeProtocol = entry.protocol
        private var commandPhase = CommandPhase.START
        private var started = false

        fun start() {
            try {
                gatt = entry.device.connectGatt(context, false, this, BluetoothDevice.TRANSPORT_LE)
                if (gatt == null) {
                    fail("GATT_UNAVAILABLE", "Could not connect to the nearby tracker")
                    return
                }
                mainHandler.postDelayed(callbackTimeout, operationTimeoutMs)
            } catch (_: SecurityException) {
                fail("PERMISSION_DENIED", "Bluetooth connection permission is not granted")
            } catch (_: Exception) {
                fail("GATT_UNAVAILABLE", "Could not connect to the nearby tracker")
            }
        }

        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            if (completed.get()) return
            if (status == 19 && activeProtocol == Protocol.AIRTAG && started) {
                succeed()
                return
            }
            if (status != BluetoothGatt.GATT_SUCCESS) {
                fail("GATT_CONNECTION_FAILED", "The nearby tracker connection failed")
                return
            }
            if (newState == BluetoothGatt.STATE_CONNECTED) {
                try {
                    if (!gatt.discoverServices()) {
                        fail("GATT_DISCOVERY_FAILED", "Could not inspect the nearby tracker")
                    }
                } catch (_: SecurityException) {
                    fail("PERMISSION_DENIED", "Bluetooth connection permission is not granted")
                }
            } else if (newState == BluetoothGatt.STATE_DISCONNECTED && !started) {
                fail("GATT_DISCONNECTED", "The nearby tracker disconnected before sounding")
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (completed.get()) return
            if (status != BluetoothGatt.GATT_SUCCESS) {
                fail("GATT_DISCOVERY_FAILED", "Could not inspect the nearby tracker")
                return
            }

            val protocols = listOf(entry.protocol) + Protocol.values().filter { it != entry.protocol }
            val match = protocols.firstNotNullOfOrNull { protocol ->
                findService(gatt, protocol)?.getCharacteristic(characteristicUuidFor(protocol))?.let { protocol to it }
            }
            if (match == null) {
                fail("UNSUPPORTED_TRACKER", "The nearby tracker sound protocol is unavailable")
                return
            }
            activeProtocol = match.first
            val target = match.second
            characteristic = target

            if (activeProtocol == Protocol.AIRTAG) {
                writeCommand(byteArrayOf(0xAF.toByte()))
            } else {
                enableNotifications(gatt, target)
            }
        }

        override fun onDescriptorWrite(gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
            if (completed.get()) return
            if (descriptor.uuid.toString().equals(cccdUuidString, ignoreCase = true) && status == BluetoothGatt.GATT_SUCCESS) {
                writeCommand(startCommandFor(activeProtocol))
            } else {
                fail("GATT_NOTIFICATION_FAILED", "Could not prepare the nearby tracker sound command")
            }
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int,
        ) {
            if (completed.get()) return
            if (status != BluetoothGatt.GATT_SUCCESS) {
                fail("GATT_WRITE_FAILED", "The nearby tracker rejected the sound command")
                return
            }

            if (commandPhase == CommandPhase.START) {
                started = true
                if (activeProtocol == Protocol.AIRTAG) {
                    // First-generation AirTags confirm the trigger by closing the GATT link
                    // with status 19. Keep the session open until that confirmation arrives.
                    return
                } else {
                    commandPhase = CommandPhase.STOP
                    stopRunnable = Runnable {
                        if (!completed.get()) writeCommand(stopCommandFor(activeProtocol))
                    }
                    mainHandler.postDelayed(stopRunnable!!, soundDurationMs)
                }
            } else {
                succeed()
            }
        }

        private fun findService(gatt: BluetoothGatt, protocol: Protocol) = gatt.services.firstOrNull { service ->
            when (protocol) {
                Protocol.DULT -> service.uuid == dultServiceUuid
                Protocol.FIND_MY -> service.uuid.toString().lowercase(Locale.US).contains("fd44")
                Protocol.AIRTAG -> service.uuid == airtagServiceUuid
            }
        }

        private fun characteristicUuidFor(protocol: Protocol): UUID = when (protocol) {
            Protocol.DULT -> dultCharacteristicUuid
            Protocol.FIND_MY -> findMyCharacteristicUuid
            Protocol.AIRTAG -> airtagCharacteristicUuid
        }

        private fun startCommandFor(protocol: Protocol): ByteArray = when (protocol) {
            Protocol.DULT -> byteArrayOf(0x00, 0x03)
            Protocol.FIND_MY -> byteArrayOf(0x01, 0x00, 0x03)
            Protocol.AIRTAG -> byteArrayOf(0xAF.toByte())
        }

        private fun stopCommandFor(protocol: Protocol): ByteArray = when (protocol) {
            Protocol.DULT -> byteArrayOf(0x01, 0x03)
            Protocol.FIND_MY -> byteArrayOf(0x01, 0x01, 0x03)
            Protocol.AIRTAG -> byteArrayOf(0xAF.toByte())
        }

        private fun enableNotifications(gatt: BluetoothGatt, target: BluetoothGattCharacteristic) {
            try {
                if (!gatt.setCharacteristicNotification(target, true)) {
                    fail("GATT_NOTIFICATION_FAILED", "Could not enable nearby tracker notifications")
                    return
                }
                val descriptor = target.getDescriptor(UUID.fromString(cccdUuidString))
                if (descriptor == null) {
                    fail("GATT_NOTIFICATION_FAILED", "The nearby tracker has no notification control")
                    return
                }
                val cccdValue = if (
                    (target.properties and BluetoothGattCharacteristic.PROPERTY_INDICATE) != 0
                ) BluetoothGattDescriptor.ENABLE_INDICATION_VALUE else BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                val accepted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    gatt.writeDescriptor(descriptor, cccdValue) == BluetoothGatt.GATT_SUCCESS
                } else {
                    @Suppress("DEPRECATION")
                    descriptor.value = cccdValue
                    @Suppress("DEPRECATION")
                    gatt.writeDescriptor(descriptor)
                }
                if (!accepted) fail("GATT_NOTIFICATION_FAILED", "Could not prepare the nearby tracker sound command")
            } catch (_: SecurityException) {
                fail("PERMISSION_DENIED", "Bluetooth connection permission is not granted")
            }
        }

        private fun writeCommand(value: ByteArray) {
            val gatt = gatt ?: return fail("GATT_UNAVAILABLE", "The nearby tracker connection is gone")
            val target = characteristic ?: return fail("GATT_UNAVAILABLE", "The nearby tracker sound channel is gone")
            try {
                val accepted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    gatt.writeCharacteristic(target, value, BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT) == BluetoothGatt.GATT_SUCCESS
                } else {
                    @Suppress("DEPRECATION")
                    target.value = value
                    @Suppress("DEPRECATION")
                    gatt.writeCharacteristic(target)
                }
                if (!accepted) fail("GATT_WRITE_FAILED", "The nearby tracker rejected the sound command")
            } catch (_: SecurityException) {
                fail("PERMISSION_DENIED", "Bluetooth connection permission is not granted")
            }
        }

        private fun fail(code: String, message: String) {
            if (!completed.compareAndSet(false, true)) return
            cleanup()
            result.error(code, message, null)
        }

        private fun succeed() {
            if (!completed.compareAndSet(false, true)) return
            cleanup()
            result.success(true)
        }

        private fun cleanup() {
            completed.set(true)
            mainHandler.removeCallbacks(callbackTimeout)
            stopRunnable?.let(mainHandler::removeCallbacks)
            stopRunnable = null
            val currentGatt = gatt
            gatt = null
            try {
                currentGatt?.disconnect()
                currentGatt?.close()
            } catch (_: SecurityException) {
                // Cleanup is best effort after the one result has been completed.
            }
        }

    }

    private class OnceResult(private val delegate: MethodChannel.Result) {
        private val completed = AtomicBoolean(false)

        fun success(value: Any?) {
            if (completed.compareAndSet(false, true)) delegate.success(value)
        }

        fun error(code: String, message: String, details: Any?) {
            if (completed.compareAndSet(false, true)) delegate.error(code, message, details)
        }
    }

    private fun protocolFor(scanRecord: android.bluetooth.le.ScanRecord?): Protocol? {
        val normalized = (scanRecord?.serviceUuids ?: emptyList<ParcelUuid>())
            .map { it.uuid.toString().lowercase(Locale.US) }
        // Legacy/separated Find My advertisements often expose no service UUID. AirGuard's
        // AppleFindMy detector identifies this Apple company-data format as type 0x12 with
        // the separated/offline marker 0x19 in the second byte. Treat this only as a scan
        // hint. GATT discovery below independently tries every supported sound protocol.
        val appleFindMyAdvertisement = scanRecord
            ?.getManufacturerSpecificData(appleManufacturerId)
            ?.let { data ->
                data.size >= 2 &&
                    (data[0].toInt() and 0xFF) == findMyAdvertisementType &&
                    (data[1].toInt() and 0xFF) == separatedFindMyAdvertisementType
            } == true
        return when {
            normalized.any { it == dultServiceUuid.toString().lowercase(Locale.US) } -> Protocol.DULT
            normalized.any { it.contains("fd44") } -> Protocol.FIND_MY
            normalized.any { it == airtagServiceUuid.toString().lowercase(Locale.US) } -> Protocol.AIRTAG
            appleFindMyAdvertisement -> Protocol.AIRTAG
            else -> null
        }
    }

    private fun signalFor(rssi: Int): String = when {
        rssi >= -60 -> "strong"
        rssi >= -80 -> "medium"
        else -> "weak"
    }
}
