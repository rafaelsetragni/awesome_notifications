Pod::Spec.new do |s|
  s.name             = 'awesome_notifications'
  s.version          = '0.12.0'
  s.summary          = 'A complete solution to create Local and Push Notifications, through Firebase or another services, using Flutter.'
  s.description      = <<-DESC
A complete solution to create Local Notifications and Push Notifications, through Firebase or another services, using Flutter.
                       DESC
  s.homepage         = 'https://github.com/rafaelsetragni/awesome_notifications'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Carda.me' => 'contact@carda.me' }
  s.source           = { :path => '.' }
  # Shared with Package.swift so CocoaPods and Swift Package Manager build the same sources.
  s.source_files     = 'awesome_notifications/Sources/awesome_notifications/**/*'
  s.static_framework = true
  s.dependency 'Flutter'
  s.dependency 'IosAwnCore', '~> 0.12.0'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = {
    # Pure-Swift pod (the Objective-C registrant shim was removed for SPM): the module
    # must be defined so the generated plugin registrant can `@import awesome_notifications`.
    'DEFINES_MODULE' => 'YES',
    'ENABLE_BITCODE' => 'NO',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'NO',
    'APPLICATION_EXTENSION_API_ONLY' => 'NO',
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64'
  }
  s.swift_version = '5.3'
  
end
