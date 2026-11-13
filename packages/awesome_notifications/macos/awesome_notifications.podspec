#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'awesome_notifications'
  s.version          = '1.0.0'
  s.summary          = 'Local and push notifications plugin (macOS bridge).'
  s.description      = <<-DESC
Flutter bridge for Awesome Notifications on macOS. Translates method-channel calls
into the Flutter-free IosAwnCore engine (shared with iOS).
                       DESC
  s.homepage         = 'https://github.com/rafaelsetragni/awesome_notifications'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Rafael Setragni' => 'rafaelsetra@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'awesome_notifications/Sources/awesome_notifications/**/*.swift'
  s.dependency 'FlutterMacOS'
  s.dependency 'IosAwnCore'
  s.platform = :osx, '10.15'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
