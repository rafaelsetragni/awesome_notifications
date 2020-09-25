#require 'yaml'

#pubspec = YAML.load_file(File.join('..', 'pubspec.yaml'))
#library_version = pubspec['version'].gsub('+', '-')

#firebase_sdk_version = '6.26.0'
#if defined?($FirebaseSDKVersion)
#  Pod::UI.puts "#{pubspec['name']}: Using user specified Firebase SDK version '#{$FirebaseSDKVersion}'"
#  firebase_sdk_version = $FirebaseSDKVersion
#else
#  firebase_core_script = File.join(File.expand_path('..', File.expand_path('..', File.dirname(__FILE__))), 'firebase_core/ios/firebase_sdk_version.rb')
#  if File.exist?(firebase_core_script)
#    require firebase_core_script
#    firebase_sdk_version = firebase_sdk_version!
#    Pod::UI.puts "#{pubspec['name']}: Using Firebase SDK version '#{firebase_sdk_version}' defined in 'firebase_core'"
#  end
#end

Pod::Spec.new do |s|
  s.name             = 'awesome_notifications'
  s.version          = '0.0.1'
  s.summary          = 'A complete solution to create Local Notifications and Push Notifications, throught Firebase or another services, using Flutter.'
  s.description      = <<-DESC
A complete solution to create Local Notifications and Push Notifications, throught Firebase or another services, using Flutter.
                       DESC
  s.homepage         = 'https://github.com/rafaelsetragni/awesome_notifications'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Rafael Setragni' => 'rafaelsetra@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.static_framework = true
  s.dependency 'Flutter'
  s.dependency 'Firebase'
  s.dependency 'Firebase/Messaging'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end

#pod 'Firebase/Messaging'
