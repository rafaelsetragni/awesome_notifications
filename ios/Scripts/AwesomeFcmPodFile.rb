require 'xcodeproj'

def install_awesome_fcm_ios_pod_target(application_path = nil)
    # defined_in_file is set by CocoaPods and is a Pathname to the Podfile.
    application_path ||= File.dirname(defined_in_file.realpath) if self.respond_to?(:defined_in_file)
    raise 'Could not find application path in install_awesome_fcm_ios_pod_target' unless application_path

    flutter_install_ios_engine_pod application_path
    pod 'awesome_notifications', :path => File.join('.symlinks', 'plugins', 'awesome_notifications', 'ios')
    pod 'awesome_notifications_fcm', :path => File.join('.symlinks', 'plugins', 'awesome_notifications_fcm', 'ios')
end

def update_awesome_fcm_service_target(target_name, xcodeproj_path, flutter_root)
     pod 'IosAwnCore', :path => '../../../IosAwnCore/'
     pod 'IosAwnFcmCore', :path => '../../../IosAwnFcmCore/'
     project = Xcodeproj::Project.open(File.join(xcodeproj_path, 'Runner.xcodeproj'))
     target = project.targets.select { |t| t.name == target_name }.first
     if target.nil? || project.targets.count == 1
         raise "You need to create a notification service extension to properly use awesome_notifications_fcm\n"
     end
     target.build_configurations.each do |config|
         config.build_settings['ENABLE_BITCODE'] = 'NO'
     end
     project.save
end
