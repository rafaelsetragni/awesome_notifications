//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import audio_session
import awesome_notifications
import awesome_notifications_media
import just_audio

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  AudioSessionPlugin.register(with: registry.registrar(forPlugin: "AudioSessionPlugin"))
  AwesomeNotificationsPlugin.register(with: registry.registrar(forPlugin: "AwesomeNotificationsPlugin"))
  AwesomeNotificationsMediaPlugin.register(with: registry.registrar(forPlugin: "AwesomeNotificationsMediaPlugin"))
  JustAudioPlugin.register(with: registry.registrar(forPlugin: "JustAudioPlugin"))
}
