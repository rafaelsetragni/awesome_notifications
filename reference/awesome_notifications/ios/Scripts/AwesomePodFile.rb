require 'xcodeproj'

def update_awesome_pod_build_settings(installer)
    installer.pods_project.targets.each do |target|
      if target.name.start_with?("awesome_notif")
        target.build_configurations.each do |config|
          config.build_settings['ENABLE_BITCODE'] = 'NO'
          config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
          config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
        end
        puts "[Awesome Notifications] Successfully updated build settings for the pod: #{target.name}"
      end
    end
    installer.pods_project.save
end

def update_awesome_main_target_settings(target_name, xcodeproj_path, flutter_root)
  project = Xcodeproj::Project.open(File.join(xcodeproj_path, 'Runner.xcodeproj'))

    target = project.targets.select { |t| t.name == target_name }.first
    if target.nil?
     raise "[Awesome Notifications] The main target '#{target_name}' does not exists\n"
    end

    target.build_configurations.each do |config|
     config.build_settings['ENABLE_BITCODE'] = 'NO'
     config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
     config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
    end
    puts "[Awesome Notifications] Successfully updated build settings for the target: '#{target.name}'"

  project.save
end