package com.bluebubbles.messaging.services.system

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import com.bluebubbles.messaging.Constants
import com.bluebubbles.messaging.models.MethodCallHandlerImpl
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions
import com.radzivon.bartoshyk.avif.coder.HeifCoder
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/// Extract the foreground subject from an image and save it as a transparent-background PNG sticker.
/// Uses Google ML Kit's Subject Segmentation API (on-device, no network required after model download).
class CreateSubjectSticker : MethodCallHandlerImpl() {
    companion object {
        const val tag = "create-subject-sticker"
    }

    override fun handleMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
        context: Context
    ) {
        val inputPath: String = call.argument("file")!!
        val outputPath: String = call.argument("output")!!

        try {
            // Decode the input image. Prefer HeifCoder for HEIC/HEIF files since
            // BitmapFactory can't handle them reliably on older Android versions.
            val bitmap: Bitmap = try {
                val bytes = File(inputPath).readBytes()
                // HeifCoder handles HEIC/HEIF/AVIF; falls through for other formats
                if (isHeifLike(inputPath)) {
                    HeifCoder().decode(bytes)
                } else {
                    BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                        ?: throw IllegalStateException("BitmapFactory returned null")
                }
            } catch (e: Exception) {
                Log.e(Constants.logTag, "Failed to decode image for subject segmentation: ${e.message}")
                result.error("decode_failed", "Could not decode the image.", null)
                return
            }

            val options = SubjectSegmenterOptions.Builder()
                .enableForegroundBitmap()
                .build()
            val segmenter = SubjectSegmentation.getClient(options)
            val inputImage = InputImage.fromBitmap(bitmap, 0)

            segmenter.process(inputImage)
                .addOnSuccessListener { segResult ->
                    val foreground = segResult.foregroundBitmap
                    if (foreground == null) {
                        Log.w(Constants.logTag, "Subject segmentation returned no foreground bitmap")
                        segmenter.close()
                        result.error("no_subject", "No subject could be detected in this image.", null)
                        return@addOnSuccessListener
                    }
                    try {
                        FileOutputStream(outputPath).use { out ->
                            foreground.compress(Bitmap.CompressFormat.PNG, 100, out)
                        }
                        Log.i(Constants.logTag, "Created subject sticker at $outputPath")
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(Constants.logTag, "Failed to write sticker PNG: ${e.message}")
                        result.error("write_failed", "Could not save the sticker.", e.message)
                    } finally {
                        segmenter.close()
                    }
                }
                .addOnFailureListener { e ->
                    Log.e(Constants.logTag, "Subject segmentation failed: ${e.message}")
                    segmenter.close()
                    // Surface model-download issues distinctly so the UI can show a helpful message.
                    val code = if (e.message?.contains("model", ignoreCase = true) == true
                        || e.message?.contains("download", ignoreCase = true) == true) {
                        "model_unavailable"
                    } else {
                        "segmentation_failed"
                    }
                    result.error(code, e.message ?: "Subject segmentation failed.", null)
                }
        } catch (e: Exception) {
            Log.e(Constants.logTag, "Unexpected error in CreateSubjectSticker: ${e.message}")
            result.error("unknown", e.message ?: "Unknown error", null)
        }
    }

    private fun isHeifLike(path: String): Boolean {
        val lower = path.lowercase()
        return lower.endsWith(".heic") || lower.endsWith(".heif") || lower.endsWith(".avif")
    }
}
