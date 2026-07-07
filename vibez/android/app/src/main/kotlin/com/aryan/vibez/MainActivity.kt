package com.aryan.vibez

import android.Manifest
import android.content.pm.PackageManager
import android.media.audiofx.Visualizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.math.sqrt

/// Exposes a real-time "bass level" stream to Flutter using Android's native
/// output Visualizer, bound to just_audio's audio session. Drives the
/// album-art glow so it pulses with the actual music.
class MainActivity : AudioServiceActivity() {
    private val methodChannelName = "vibez/audio_reactive"
    private val eventChannelName = "vibez/audio_reactive/events"
    private val permRequestCode = 4711

    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var pendingSessionId: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        EventChannel(messenger, eventChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                }

                override fun onCancel(args: Any?) {
                    eventSink = null
                }
            },
        )

        MethodChannel(messenger, methodChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0
                    startVisualizer(sessionId)
                    result.success(null)
                }
                "stop" -> {
                    stopVisualizer()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startVisualizer(sessionId: Int) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            // Defer until the user grants the permission, then start.
            pendingSessionId = sessionId
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                permRequestCode,
            )
            return
        }

        stopVisualizer()
        try {
            val v = Visualizer(sessionId)
            v.captureSize = Visualizer.getCaptureSizeRange()[1]
            val rate = Visualizer.getMaxCaptureRate() / 2
            v.setDataCaptureListener(
                object : Visualizer.OnDataCaptureListener {
                    override fun onWaveFormDataCapture(vis: Visualizer?, wf: ByteArray?, sr: Int) {}

                    override fun onFftDataCapture(vis: Visualizer?, fft: ByteArray?, sr: Int) {
                        if (fft == null) return
                        // Sum magnitudes of the lowest frequency bins (the bass).
                        // fft layout: [DC, Nyquist, re1, im1, re2, im2, ...].
                        val bins = 12
                        var sum = 0.0
                        var i = 2
                        var k = 0
                        while (k < bins && i + 1 < fft.size) {
                            val re = fft[i].toDouble()
                            val im = fft[i + 1].toDouble()
                            sum += sqrt(re * re + im * im)
                            i += 2
                            k++
                        }
                        val level = (sum / bins / 60.0).coerceIn(0.0, 1.0)
                        eventSink?.success(level)
                    }
                },
                rate,
                false,
                true,
            )
            v.enabled = true
            visualizer = v
        } catch (e: Exception) {
            eventSink?.error("VIS_ERR", e.message, null)
        }
    }

    private fun stopVisualizer() {
        try {
            visualizer?.enabled = false
            visualizer?.release()
        } catch (_: Exception) {
        }
        visualizer = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == permRequestCode) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            val sid = pendingSessionId
            pendingSessionId = null
            if (granted && sid != null) startVisualizer(sid)
        }
    }

    override fun onDestroy() {
        stopVisualizer()
        super.onDestroy()
    }
}
