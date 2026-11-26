#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint awesome_notifications.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'awesome_notifications'
  s.version          = '1.0.0'
  s.summary          = 'Local and push notifications plugin (iOS bridge).'
  s.description      = <<-DESC
Flutter bridge for Awesome Notifications on iOS. Translates method-channel calls
into the Flutter-free IosAwnCore engine.
                       DESC
  s.homepage         = 'https://github.com/rafaelsetragni/awesome_notifications'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Rafael Setragni' => 'rafaelsetra@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'awesome_notifications/Sources/awesome_notifications/**/*'
  s.dependency 'Flutter'
  s.dependency 'IosAwnCore'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'awesome_notifications_privacy' => ['awesome_notifications/Sources/awesome_notifications/PrivacyInfo.xcprivacy']}
end
