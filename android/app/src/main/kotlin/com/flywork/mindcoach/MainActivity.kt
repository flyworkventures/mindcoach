package com.flywork.mindcoach

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private var proximityWakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mindcoach/voice_audio_session",
        ).setMethodCallHandler { call, result ->
            val am = applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            try {
                when (call.method) {
                    "configureForVoiceCall" -> {
                        // Voice-chat routing: MODE_IN_COMMUNICATION enables
                        // hardware AEC / auto-ducking. We ALSO force the
                        // loudspeaker on by default here — testers reported
                        // audio going to the earpiece silently made the
                        // session feel broken, since most users hold the
                        // phone away from their ear during an AI coaching
                        // session. The Flutter UI's speaker toggle still
                        // works and can flip us back to the earpiece.
                        am.mode = AudioManager.MODE_IN_COMMUNICATION
                        routeToSpeaker(am, true)
                        result.success("in_communication")
                    }
                    "setSpeakerOn" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        routeToSpeaker(am, on)
                        result.success(on)
                    }
                    "resetAudioSession" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            am.clearCommunicationDevice()
                        } else {
                            @Suppress("DEPRECATION")
                            am.isSpeakerphoneOn = false
                        }
                        am.mode = AudioManager.MODE_NORMAL
                        // Always release proximity wake lock when leaving the call
                        // so the screen never gets stuck off.
                        releaseProximityWakeLock()
                        result.success(null)
                    }
                    "setProximityMonitoring" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        if (on) acquireProximityWakeLock() else releaseProximityWakeLock()
                        result.success(on)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("AUDIO_SESSION_ERROR", e.message, null)
            }
        }
    }

    /**
     * Real-phone behaviour: blank the screen and disable touch input when
     * the proximity sensor reports the device is near the user's ear.
     * Implemented via PROXIMITY_SCREEN_OFF_WAKE_LOCK — same wake lock the
     * stock Phone app uses.
     */
    private fun acquireProximityWakeLock() {
        if (proximityWakeLock == null) {
            val pm = applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!pm.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) return
            proximityWakeLock = pm.newWakeLock(
                PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                "mindcoach:voiceCallProximity",
            )
        }
        val lock = proximityWakeLock ?: return
        if (!lock.isHeld) lock.acquire()
    }

    private fun releaseProximityWakeLock() {
        val lock = proximityWakeLock ?: return
        if (lock.isHeld) {
            // RELEASE_FLAG_WAIT_FOR_NO_PROXIMITY → screen stays off until
            // the user moves the device away from their ear, avoiding the
            // brief flash you'd otherwise get while still in the pocket.
            lock.release(PowerManager.RELEASE_FLAG_WAIT_FOR_NO_PROXIMITY)
        }
        proximityWakeLock = null
    }

    override fun onDestroy() {
        releaseProximityWakeLock()
        super.onDestroy()
    }

    private fun routeToSpeaker(am: AudioManager, speakerOn: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val devices = am.availableCommunicationDevices
            val target = if (speakerOn) {
                devices.find { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
            } else {
                devices.find { it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE }
            }
            if (target != null) {
                am.setCommunicationDevice(target)
            } else {
                @Suppress("DEPRECATION")
                am.isSpeakerphoneOn = speakerOn
            }
        } else {
            @Suppress("DEPRECATION")
            am.isSpeakerphoneOn = speakerOn
        }
    }
}
