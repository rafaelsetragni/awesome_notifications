#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint awesome_notifications_fcm.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'awesome_notifications_fcm'
  s.version          = '1.0.0-dev.0'
  s.summary          = 'Firebase Cloud Messaging (push) decorator for awesome_notifications.'
  s.description      = <<-DESC
Receives Firebase Cloud Messaging pushes and silent data and displays them
through the awesome_notifications core engine.
                       DESC
  s.homepage         = 'https://discord.awesome-notifications.carda.me/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Rafael Setragni' => 'rafaelsetragni@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'awesome_notifications_fcm/Sources/awesome_notifications_fcm/**/*'

  s.dependency 'Flutter'
  s.dependency 'awesome_notifications'
  s.dependency 'FirebaseCore'
  s.dependency 'FirebaseMessaging'

  s.platform = :ios, '15.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
