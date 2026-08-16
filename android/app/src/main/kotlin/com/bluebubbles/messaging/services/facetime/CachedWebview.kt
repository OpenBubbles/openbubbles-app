package com.bluebubbles.messaging.services.facetime

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.PermissionRequest
import android.webkit.ConsoleMessage
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import okhttp3.Cache
import okhttp3.Headers
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.ByteArrayInputStream
import java.io.File

@SuppressLint("SetJavaScriptEnabled")
class CachedWebview(context: Context, name: String?, desc: String, url: String) {
    companion object {
        private const val diagnosticTag = "FaceTimeDiag"
    }

    val webView = WebView(context)
    private val applicationContext = context.applicationContext

    var mirrorReady = false
    var mirrorReadyCall: (() -> Unit)? = null
    var endTask: () -> Unit = {
        webView.destroy()
        FaceTimeActivity.cachedWebview = null
    }

    val deferredRequests = arrayListOf<PermissionRequest>()
    var deferredRequestsUpdated: () -> Unit = {}

    private fun diagnosticsEnabled(): Boolean = FaceTimeDiagnostics.isEnabled(applicationContext)

    private fun safeResourceLabel(requestUrl: String?): String = FaceTimeDiagnostics.safeResourceLabel(requestUrl)

    fun getScriptData(request: WebResourceRequest, client: OkHttpClient, name: String?, desc: String): String {
        if (diagnosticsEnabled()) Log.i(diagnosticTag, "getting main.js")
        // OKHTTP should handle caching for us
        val okhttp = Request.Builder()
            .method(request.method, null)
            .headers(request.requestHeaders.entries.fold(Headers.Builder()) { acc, e ->
                acc.set(e.key, e.value)
                acc
            }.build())
            .url(request.url.toString())
            .build()

        val call = client.newCall(okhttp)
        val response = call.execute()
        if (response.code() != 200) {
            throw Exception("Failed to load resource! $response")
        }
        val body = response.body() ?: throw Exception("Failed to load resource! Empty body!")
        var string = body.string()
            .replace(""""GenericToast\.Waiting": *"Waiting to be let in…",""".toRegex(), """"GenericToast.Waiting":"Connecting…",""")
            .replace(""""SessionBanner\.FaceTime": *"FaceTime Call",""".toRegex(), """"SessionBanner.FaceTime":"$desc",""")
            .replace("this.onLeave.notifyListeners()", "Native.leave(), this.onLeave.notifyListeners()")

        if (name != null) {
            string = string.replace("(submitName: *([a-zA-Z]+?)[ a-zA-Z,}=:]*?;)".toRegex(), "$1 $2(\"$name\").then(() => Native.mirrored());")
        }

        return string
    }

    init {
        val client = OkHttpClient.Builder()
            .cache(
                Cache(
                    File(context.cacheDir, "http_cache"),
                    10L * 1024L * 1024L // 10 MiB
                )
            )
            .build()
        webView.settings.javaScriptEnabled = true
        webView.webViewClient = object : WebViewClient() {
            override fun shouldInterceptRequest(
                view: WebView?,
                request: WebResourceRequest?
            ): WebResourceResponse? {
                if (request == null) return null
                if (!request.url.toString().endsWith("main.js")) return null
                // intercept and patch request

                if (diagnosticsEnabled()) Log.i(diagnosticTag, "intercepting ${safeResourceLabel(request.url.toString())}")
                val scriptData = try {
                    getScriptData(request, client, name, desc)
                } catch (error: Exception) {
                    if (diagnosticsEnabled()) Log.e(diagnosticTag, "main.js interception failed: ${error.javaClass.simpleName}")
                    throw error
                }

                return WebResourceResponse(
                    "application/javascript",
                    "utf-8",
                    ByteArrayInputStream(scriptData.encodeToByteArray())
                )
            }

            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                if (diagnosticsEnabled()) Log.i(diagnosticTag, "page started ${safeResourceLabel(url)}")
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                if (diagnosticsEnabled()) Log.i(diagnosticTag, "page finished ${safeResourceLabel(url)} mirrorReady=$mirrorReady")
            }

            override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
                if (diagnosticsEnabled()) Log.w(diagnosticTag, "resource error mainFrame=${request?.isForMainFrame} code=${error?.errorCode} resource=${safeResourceLabel(request?.url?.toString())}")
            }

            override fun onReceivedHttpError(view: WebView?, request: WebResourceRequest?, errorResponse: WebResourceResponse?) {
                if (diagnosticsEnabled()) Log.w(diagnosticTag, "http error mainFrame=${request?.isForMainFrame} status=${errorResponse?.statusCode} resource=${safeResourceLabel(request?.url?.toString())}")
            }
        }
        webView.setBackgroundColor(Color.BLACK)

        webView.addJavascriptInterface(object {
            @JavascriptInterface
            fun leave() {
                endTask()
            }
            @JavascriptInterface
            fun mirrored() {
                // takes a second for the mirror to be ready
                Handler(Looper.getMainLooper()).postDelayed({
                    mirrorReady = true
                    mirrorReadyCall?.let {
                        it()
                    }
                }, 250)
                if (diagnosticsEnabled()) Log.i(diagnosticTag, "Native.mirrored received; mirrorReady scheduled")
            }
        }, "Native")

        webView.webChromeClient = object : WebChromeClient() {
            override fun onPermissionRequest(request: PermissionRequest?) {
                if (request == null) return
                if (diagnosticsEnabled()) Log.i(diagnosticTag, "WebView permission request resources=${request.resources.sorted().joinToString()}")
                deferredRequests.add(request)
                deferredRequestsUpdated()
            }

            override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean {
                if (!diagnosticsEnabled() || consoleMessage == null) return false
                if (consoleMessage.messageLevel() == ConsoleMessage.MessageLevel.ERROR || consoleMessage.messageLevel() == ConsoleMessage.MessageLevel.WARNING) {
                    Log.w(diagnosticTag, "console ${consoleMessage.messageLevel()} line=${consoleMessage.lineNumber()} source=${safeResourceLabel(consoleMessage.sourceId())} message=<omitted>")
                }
                return false
            }

            override fun getDefaultVideoPoster(): Bitmap {
                return Bitmap.createBitmap(1, 1, Bitmap.Config.RGB_565)
            }
        }

        webView.loadUrl(url)
    }

}
