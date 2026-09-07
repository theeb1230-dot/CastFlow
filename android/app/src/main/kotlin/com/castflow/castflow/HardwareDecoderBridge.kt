package com.castflow.castflow

import android.media.MediaCodec
import android.media.MediaFormat
import android.view.Surface
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.nio.ByteBuffer

class HardwareDecoderBridge(
    messenger: BinaryMessenger,
    private val textureRegistry: TextureRegistry,
) : MethodChannel.MethodCallHandler {
    companion object {
        private const val channelName = "castflow/hardware_decoder"
        private const val inputTimeoutUs = 10_000L
    }

    private val channel = MethodChannel(messenger, channelName)

    private var codec: MediaCodec? = null
    private var surface: Surface? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val width = call.argument<Int>("width")
                val height = call.argument<Int>("height")
                if (width == null || height == null || width <= 0 || height <= 0) {
                    result.error("invalid_argument", "width and height must be positive.", null)
                    return
                }

                try {
                    result.success(initialize(width, height))
                } catch (error: Throwable) {
                    disposeDecoder()
                    result.error(
                        "decoder_init_failed",
                        error.message ?: "Unable to initialize H.264 decoder.",
                        null,
                    )
                }
            }
            "push" -> {
                val data = call.argument<ByteArray>("data")
                val presentationTimeUs = call.argument<Long>("presentationTimeUs")
                    ?: call.argument<Int>("presentationTimeUs")?.toLong()
                val flags = call.argument<Int>("flags") ?: 0

                if (data == null || data.isEmpty() || presentationTimeUs == null) {
                    result.error("invalid_argument", "Invalid encoded packet.", null)
                    return
                }

                try {
                    val rendered = push(data, presentationTimeUs, flags)
                    result.success(rendered)
                } catch (error: Throwable) {
                    result.error(
                        "decoder_push_failed",
                        error.message ?: "Unable to queue H.264 packet.",
                        null,
                    )
                }
            }
            "dispose" -> {
                disposeDecoder()
                result.success(null)
            }
            "isActive" -> result.success(codec != null)
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        disposeDecoder()
        channel.setMethodCallHandler(null)
    }

    private fun initialize(width: Int, height: Int): Long {
        if (codec != null) {
            return textureEntry?.id()
                ?: throw IllegalStateException("Decoder is active without a texture.")
        }

        val entry = textureRegistry.createSurfaceTexture()
        entry.surfaceTexture().setDefaultBufferSize(width, height)
        val outputSurface = Surface(entry.surfaceTexture())

        val format = MediaFormat.createVideoFormat(
            MediaFormat.MIMETYPE_VIDEO_AVC,
            width,
            height,
        )

        val decoder = MediaCodec.createDecoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        decoder.configure(format, outputSurface, null, 0)
        decoder.start()

        textureEntry = entry
        surface = outputSurface
        codec = decoder

        return entry.id()
    }

    private fun push(data: ByteArray, presentationTimeUs: Long, flags: Int): Boolean {
        val decoder = codec ?: throw IllegalStateException("Decoder is not initialized.")

        val inputIndex = decoder.dequeueInputBuffer(inputTimeoutUs)
        if (inputIndex < 0) {
            throw IllegalStateException("Decoder input buffer is temporarily unavailable.")
        }

        val inputBuffer: ByteBuffer = decoder.getInputBuffer(inputIndex)
            ?: throw IllegalStateException("Decoder input buffer is unavailable.")
        inputBuffer.clear()
        inputBuffer.put(data)

        decoder.queueInputBuffer(
            inputIndex,
            0,
            data.size,
            presentationTimeUs,
            flags,
        )

        return drainOutput(decoder)
    }

    private fun drainOutput(decoder: MediaCodec): Boolean {
        val info = MediaCodec.BufferInfo()
        var renderedFrame = false

        while (true) {
            val outputIndex = decoder.dequeueOutputBuffer(info, 0)
            when {
                outputIndex >= 0 -> {
                    val codecConfig = (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0
                    val endOfStream = (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0
                    val render = info.size > 0 && !codecConfig && !endOfStream
                    decoder.releaseOutputBuffer(outputIndex, render)
                    renderedFrame = renderedFrame || render
                }
                outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> return renderedFrame
                outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> continue
                else -> return renderedFrame
            }
        }
    }

    private fun disposeDecoder() {
        codec?.let { decoder ->
            try {
                decoder.stop()
            } catch (_: IllegalStateException) {
            }
            decoder.release()
        }
        codec = null

        surface?.release()
        surface = null

        textureEntry?.release()
        textureEntry = null
    }
}
