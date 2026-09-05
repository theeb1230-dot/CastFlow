package com.castflow.castflow

import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Surface
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class HardwareEncoderBridge(
    private val projectionBridge: MediaProjectionSessionBridge,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val methodChannelName = "castflow/hardware_encoder"
        private const val eventChannelName = "castflow/hardware_encoder/events"
    }

    private val methodChannel = MethodChannel(messenger, methodChannelName)
    private val eventChannel = EventChannel(messenger, eventChannelName)
    private val mainHandler = Handler(Looper.getMainLooper())

    private var codec: MediaCodec? = null
    private var inputSurface: Surface? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var drainThread: Thread? = null
    private val draining = AtomicBoolean(false)
    private var eventSink: EventChannel.EventSink? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                val width = call.argument<Int>("width")
                val height = call.argument<Int>("height")
                val fps = call.argument<Int>("fps")
                val bitrate = call.argument<Int>("bitrate")
                if (
                    width == null ||
                    height == null ||
                    fps == null ||
                    bitrate == null ||
                    width <= 0 ||
                    height <= 0 ||
                    fps <= 0 ||
                    bitrate <= 0
                ) {
                    result.error("invalid_argument", "Invalid encoder configuration.", null)
                    return
                }

                try {
                    start(width, height, fps, bitrate)
                    result.success(null)
                } catch (error: Throwable) {
                    stop()
                    result.error(
                        "encoder_start_failed",
                        error.message ?: "Unable to start hardware encoder.",
                        null,
                    )
                }
            }
            "setBitrate" -> {
                val bitrate = call.argument<Int>("bitrate")
                if (bitrate == null || bitrate <= 0) {
                    result.error("invalid_argument", "bitrate must be positive.", null)
                    return
                }

                try {
                    setBitrate(bitrate)
                    result.success(null)
                } catch (error: Throwable) {
                    result.error(
                        "encoder_update_failed",
                        error.message ?: "Unable to update encoder bitrate.",
                        null,
                    )
                }
            }
            "stop" -> {
                stop()
                result.success(null)
            }
            "isActive" -> result.success(codec != null && draining.get())
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun dispose() {
        stop()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    private fun start(
        width: Int,
        height: Int,
        fps: Int,
        bitrate: Int,
    ) {
        if (codec != null) {
            throw IllegalStateException("Hardware encoder is already active.")
        }

        val projection = projectionBridge.activeProjection()
            ?: throw IllegalStateException("MediaProjection session is not active.")

        val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
            setInteger(
                MediaFormat.KEY_COLOR_FORMAT,
                MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface,
            )
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }

        val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val surface = encoder.createInputSurface()
        encoder.start()

        val densityDpi = projectionBridge.densityDpi()
        val display = projection.createVirtualDisplay(
            "CastFlowCapture",
            width,
            height,
            densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            surface,
            null,
            null,
        )

        codec = encoder
        inputSurface = surface
        virtualDisplay = display
        startDrainLoop(encoder)
    }

    private fun setBitrate(bitrate: Int) {
        val encoder = codec ?: throw IllegalStateException("Hardware encoder is not active.")
        val params = Bundle().apply {
            putInt(MediaCodec.PARAMETER_KEY_VIDEO_BITRATE, bitrate)
        }
        encoder.setParameters(params)
    }

    private fun startDrainLoop(encoder: MediaCodec) {
        draining.set(true)
        drainThread = Thread({
            val info = MediaCodec.BufferInfo()

            while (draining.get()) {
                val index = try {
                    encoder.dequeueOutputBuffer(info, 10_000)
                } catch (_: IllegalStateException) {
                    break
                }

                when {
                    index >= 0 -> {
                        val buffer = encoder.getOutputBuffer(index)
                        if (buffer != null && info.size > 0) {
                            buffer.position(info.offset)
                            buffer.limit(info.offset + info.size)

                            val bytes = ByteArray(info.size)
                            buffer.get(bytes)

                            val event = mapOf(
                                "data" to bytes,
                                "presentationTimeUs" to info.presentationTimeUs,
                                "flags" to info.flags,
                            )
                            mainHandler.post {
                                eventSink?.success(event)
                            }
                        }
                        encoder.releaseOutputBuffer(index, false)
                    }
                    index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        val format = encoder.outputFormat
                        mainHandler.post {
                            eventSink?.success(
                                mapOf(
                                    "formatChanged" to true,
                                    "mime" to format.getString(MediaFormat.KEY_MIME),
                                    "width" to format.getInteger(MediaFormat.KEY_WIDTH),
                                    "height" to format.getInteger(MediaFormat.KEY_HEIGHT),
                                ),
                            )
                        }
                    }
                }
            }
        }, "CastFlowEncoderDrain").apply {
            start()
        }
    }

    private fun stop() {
        draining.set(false)
        val thread = drainThread
        drainThread = null
        if (thread != null && thread !== Thread.currentThread()) {
            try {
                thread.join(500)
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
            }
        }

        virtualDisplay?.release()
        virtualDisplay = null

        inputSurface?.release()
        inputSurface = null

        codec?.let { encoder ->
            try {
                encoder.stop()
            } catch (_: IllegalStateException) {
            }
            encoder.release()
        }
        codec = null
    }
}
