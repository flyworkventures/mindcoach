import Flutter
import UIKit
import AVFoundation
import flutter_local_notifications
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Flutter Local Notifications plugin registration callback
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    
    // Request notification permissions for iOS 10+
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    GeneratedPluginRegistrant.register(with: self)

    // ── Voice call audio session channel ──────────────────────────────────
    // Enables hardware echo cancellation on iPhone for real-time voice chat.
    // Called from Flutter when entering/leaving the voice-call screen.
    let controller = window?.rootViewController as? FlutterViewController
    if let messenger = controller?.binaryMessenger {
      let channel = FlutterMethodChannel(
        name: "mindcoach/voice_audio_session",
        binaryMessenger: messenger)
      channel.setMethodCallHandler { (call, result) in
        let session = AVAudioSession.sharedInstance()
        do {
          switch call.method {
          case "configureForVoiceCall":
            // Other plugins (flutter_pcm_sound, record, …) may reset the
            // category / mode on us. Re-apply BOTH explicitly so we end up
            // in voiceChat mode (required for iOS hardware AEC).
            //
            // We ROUTE TO THE LOUDSPEAKER BY DEFAULT (`.defaultToSpeaker` +
            // explicit `overrideOutputAudioPort(.speaker)`). Testers reported
            // that with an earpiece-first route users didn't realise audio
            // was even playing, because most people don't hold the phone up
            // to their ear during an AI coaching session. The `setSpeakerOn`
            // handler below still lets the UI toggle back to earpiece.
            try session.setCategory(
              .playAndRecord,
              mode: .voiceChat, // enables hardware AEC + auto-ducking
              options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
            // setCategory occasionally silently reverts the mode to
            // `default` on iOS 17+; force it again if that happened.
            if session.mode != .voiceChat {
              try? session.setMode(.voiceChat)
            }
            try session.setActive(true, options: [])
            // Force speaker on the way in — `.defaultToSpeaker` only sets
            // the fallback; an override left over from a previous session
            // could still put us on the earpiece.
            try? session.overrideOutputAudioPort(.speaker)
            result(session.mode.rawValue) // return the actual mode for debugging

          case "setSpeakerOn":
            // Toggle between loudspeaker and earpiece (the iPhone Phone app
            // "Speaker" button behaviour). Must be called while the session
            // is already active in .playAndRecord/.voiceChat mode.
            let on = (call.arguments as? [String: Any])?["on"] as? Bool ?? false
            try session.overrideOutputAudioPort(on ? .speaker : .none)
            result(on)

          case "resetAudioSession":
            // Return to a permissive default so OTHER audio features in the
            // app (voice-message recording, audio playback, etc.) keep
            // working. Do NOT call setActive(false) — that silences the whole
            // app until the next setActive(true) and breaks unrelated chat
            // features after the user leaves the voice call screen.
            try session.setCategory(
              .playAndRecord,
              mode: .default,
              options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try session.setActive(true)
            // Always release the proximity sensor when leaving the call.
            DispatchQueue.main.async {
              UIDevice.current.isProximityMonitoringEnabled = false
            }
            result(nil)

          case "setProximityMonitoring":
            // Real-phone behaviour: when the user holds the device to
            // their ear, iOS automatically blanks the screen and locks
            // touch input. Only active while the voice-call screen is
            // visible — must be turned off again on dispose so the rest
            // of the app behaves normally.
            let on = (call.arguments as? [String: Any])?["on"] as? Bool ?? false
            DispatchQueue.main.async {
              UIDevice.current.isProximityMonitoringEnabled = on
            }
            result(on)

          default:
            result(FlutterMethodNotImplemented)
          }
        } catch {
          result(FlutterError(
            code: "AUDIO_SESSION_ERROR",
            message: error.localizedDescription,
            details: nil))
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
