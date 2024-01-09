#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint awesome_notifications.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'awesome_notifications'
  s.version          = '0.9.0'
  s.summary          = 'A complete solution to create Local and Push Notifications, through Firebase or another services, using Flutter.'
  s.description      = <<-DESC
A complete solution to create Local and Push Notifications, customizing buttons, images, sounds, emoticons and applying many different layouts for Flutter apps.
                       DESC
  s.homepage         = 'https://github.com/rafaelsetragni/awesome_notifications'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Rafael Setragni' => 'rafaelsetra@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.static_framework = true
  s.dependency 'Flutter'
  s.dependency 'IosAwnCore', '~> 0.9.1'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'NO',
    'ENABLE_BITCODE' => 'NO',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'NO',
    'APPLICATION_EXTENSION_API_ONLY' => 'NO',
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64'
  }
  s.swift_version = '5.0'
end
