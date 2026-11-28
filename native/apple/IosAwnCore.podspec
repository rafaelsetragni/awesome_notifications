#
# Flutter-free Apple notification engine, shared by the awesome_notifications
# plugin and (later) the Notification Service Extension. The same sources are
# exposed to Swift Package Manager through the repo-root Package.swift.
#
Pod::Spec.new do |s|
  s.name             = 'IosAwnCore'
  s.version          = '1.0.0-dev.1'
  s.summary          = 'Flutter-free notification engine for Apple platforms.'
  s.description      = <<-DESC
The Apple-side native engine of Awesome Notifications. Contains no Flutter
dependency so it can be linked by both the Flutter plugin and a Notification
Service Extension.
                       DESC
  s.homepage         = 'https://github.com/rafaelsetragni/awesome_notifications'
  s.license          = { :file => '../../LICENSE' }
  s.author           = { 'Rafael Setragni' => 'rafaelsetra@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Sources/IosAwnCore/**/*.swift'
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.swift_version    = '5.9'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
