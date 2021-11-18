//
//  PermissionManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 17/11/21.
//

import Foundation

typealias ActivityCompletionHandler = () -> ()

public class PermissionManager {
    
    private static let TAG:String = "PermissionManager"

    public let activityQueue:SynchronizedArray = SynchronizedArray<ActivityCompletionHandler>()

    private static func getIosPermissionsCode(_ permissions:[String]) -> UNAuthorizationOptions {
        
        var iOSpermissions:UNAuthorizationOptions = []

        for permission in permissions {
            switch NotificationPermission.fromString(permission) {
                
                case .Alert:
                    iOSpermissions.insert(.alert)
                    break
                    
                case .Sound:
                    iOSpermissions.insert(.sound)
                    break
                    
                case .Badge:
                    iOSpermissions.insert(.badge)
                    break
                    
                case .Car:
                    iOSpermissions.insert(.carPlay)
                    break
                
                case .CriticalAlert:
                    if #available(iOS 12.0, *) {
                        iOSpermissions.insert(.criticalAlert)
                    }
                    break
                        
                case .Provisional:
                    if #available(iOS 12.0, *) {
                        iOSpermissions.insert(.provisional)
                    }
                    break

                default:
                    break
            }
        }

        return iOSpermissions;
    }

    public static func areNotificationsGloballyAllowed(permissionCompletion: @escaping (Bool) -> ()) {
             
        // Extension targets are always authorized
        if SwiftUtils.isRunningOnExtension() {
            permissionCompletion(true)
            return
        }
        
        let current = UNUserNotificationCenter.current()
        current.getNotificationSettings(completionHandler: { (settings) in
            
            if settings.authorizationStatus == .notDetermined {
                // The user hasnt decided yet if he authorizes or not
                permissionCompletion(false)
                return
                
            } else if settings.authorizationStatus == .denied {
                // Notification permission was previously denied, go to settings & privacy to re-enable
                permissionCompletion(false)
                return
                
            } else if settings.authorizationStatus == .authorized {
                // Notification permission was already granted
                permissionCompletion(true)
                return
            }
        })
        
        //return UIApplication.shared.isRegisteredForRemoteNotifications
    }

    public static func arePermissionsAllowed(_ permissions:[String], channelKey:String?, completion: @escaping ([String]) -> ()) {

        var allowed:[String] = []
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { iOSpermissions in
            
            // (Settings != .Disabled == .Enabled & .NotSupported /*Emulator limitations*/)
            for permission in permissions {
                let permissionEnum:NotificationPermission = NotificationPermission.fromString(permission)
                switch permissionEnum {
                    
                    case .Alert:
                        if(iOSpermissions.alertSetting != .disabled){
                            if(channelKey == nil || isSpecifiedChannelPermissionAllowed(channelKey: channelKey, permissionEnum: permissionEnum)){
                                allowed.append(NotificationPermission.Alert.rawValue)
                            }
                        }
                        break
                    case .Sound:
                        if(iOSpermissions.soundSetting != .disabled){
                            if(channelKey == nil || isSpecifiedChannelPermissionAllowed(channelKey: channelKey, permissionEnum: permissionEnum)){
                                allowed.append(NotificationPermission.Sound.rawValue)
                            }
                        }
                        break
                        
                    case .Badge:
                        if(iOSpermissions.badgeSetting != .disabled){
                            if(channelKey == nil || isSpecifiedChannelPermissionAllowed(channelKey: channelKey, permissionEnum: permissionEnum)){
                                allowed.append(NotificationPermission.Badge.rawValue)
                            }
                        }
                        break
                        
                    case .Car:
                        if(iOSpermissions.carPlaySetting != .disabled){
                            if(channelKey == nil || isSpecifiedChannelPermissionAllowed(channelKey: channelKey, permissionEnum: permissionEnum)){
                                allowed.append(NotificationPermission.Car.rawValue)
                            }
                        }
                        break
                    
                    case .OverrideDnD:
                    case .CriticalAlert:
                        if #available(iOS 12.0, *) {
                            if(iOSpermissions.criticalAlertSetting != .disabled){
                                if(channelKey == nil || isSpecifiedChannelPermissionAllowed(channelKey: channelKey, permissionEnum: permissionEnum)){
                                    allowed.append(NotificationPermission.CriticalAlert.rawValue)
                                }
                            }
                        }
                        else {
                            if(channelKey == nil || isSpecifiedChannelPermissionAllowed(channelKey: channelKey, permissionEnum: permissionEnum)){
                                allowed.append(NotificationPermission.CriticalAlert.rawValue)
                            }
                        }
                        break
                            
                    case .Provisional:
                        if #available(iOS 12.0, *) {
                            if(iOSpermissions.authorizationStatus == .provisional){
                                if(channelKey == nil || isSpecifiedChannelPermissionAllowed(channelKey: channelKey, permissionEnum: permissionEnum)){
                                    allowed.append(NotificationPermission.Provisional.rawValue)
                                }
                            }
                        }
                        else {
                            if(channelKey == nil || isSpecifiedChannelPermissionAllowed(channelKey: channelKey, permissionEnum: permissionEnum)){
                                allowed.append(NotificationPermission.Provisional.rawValue)
                            }
                        }
                        break

                    default:
                        // Android only permissions are considered globally allowed on iOS
                        if(channelKey == nil || isSpecifiedChannelPermissionAllowed(channelKey: channelKey, permissionEnum: permissionEnum)){
                            allowed.append(permission)
                        }
                        break
                }
            }

            completion(allowed)
        })
    }

    public static func isSpecifiedPermissionGloballyAllowed(_ permission:[String], channel:String?, completion: @escaping ([String]) -> ()){

        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { iOSpermissions in
            
            // (Settings != .Disabled == .Enabled & .NotSupported /*Emulator limitations*/)
            switch NotificationPermission.fromString(permission) {
                
                case .Alert:
                    completion(iOSpermissions.alertSetting != .disabled)
                    break

                case .Sound:
                    completion(iOSpermissions.soundSetting != .disabled)
                    break
                    
                case .Badge:
                    completion(iOSpermissions.badgeSetting != .disabled)
                    break
                    
                case .Car:
                    completion(iOSpermissions.carPlaySetting != .disabled)
                    break
                
                case .OverrideDnD:
                case .CriticalAlert:
                    if #available(iOS 12.0, *) {
                        completion(iOSpermissions.criticalAlertSetting != .disabled)
                    }
                    else {
                        completion(true)
                    }
                    break
                        
                case .Provisional:
                    if #available(iOS 12.0, *) {
                        completion(iOSpermissions.authorizationStatus == .provisional)
                    }
                    else {
                        completion(true)
                    }
                    break

                default:
                    // Android only permissions are considered allowed on iOS
                    completion(true)
                    break
            }
        })
    }

    public static isSpecifiedChannelPermissionAllowed(
        channelKey:String, permissionEnum:NotificationPermission) throws -> Bool {

        guard let channelModel = ChannelManager.getChannelByKey(channelKey: notificationModel.content!.channelKey!) else {
            throw AwesomeNotificationsException.invalidRequiredFields(msg: 
                "Channel '\(notificationModel.content!.channelKey!)' does not exist or is disabled")
        }

        if(channelModel.importance != NotificationImportance.None){

            switch (permissionEnum){

                case Alert:
                    return channelModel.importance.ordinal() >= NotificationImportance.High.ordinal();

                case Sound:
                    return channelModel.playSound;

                case Light:
                    return channelModel.enableLights;

                case Vibration:
                    return channelModel.enableVibration;

                case Badge:
                    return channelModel.channelShowBadge;

                case CriticalAlert:
                    return channelModel.criticalAlerts;

                case PreciseAlarms:
                default:
                    return true;
            }

        }
        return false;
    }

    public static func requestUserPermissions(
        permissions:[String],
        channelKey:String?,
        permissionCompletion: @escaping ([String]) -> ()
    ) throws AwesomeNotificationException {

        if SwiftUtils.isRunningOnExtension() {
            // On Extensions, permissions are never requested
            // because there is no user interaction
            permissionCompletion(permissions)
            return
        }
            
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            
            var isAllowed:Bool = false
            if #available(iOS 12.0, *) {
                isAllowed =
                    (settings.authorizationStatus == .authorized) ||
                    (settings.authorizationStatus == .provisional)
            } else {
                isAllowed =
                    (settings.authorizationStatus == .authorized)
            }

            if !isAllowed && settings.authorizationStatus == .notDetermined {
                shouldShowRequestDialog(
                    channelKey: channelKey,
                    permissions: permissions,
                    permissionCompletion: permissionCompletion)
            }
            else {
                shouldShowRationalePage(
                    channelKey: channelKey,
                    permissions: permissions,
                    permissionCompletion: permissionCompletion)
            }
        }
    }

    private static func shouldShowRequestDialog(
        permissions:[String],
        channelKey:String?,
        permissionCompletion: @escaping ([String]) -> ()
    ) throws AwesomeNotificationException {

        let permissionList:UNAuthorizationOptions = getIosPermissionsCode(permissions)                    
        notificationCenter.requestAuthorization(options: iOSpermissions) { (granted, error) in

            if granted {
                print("Permissions enabled successfully")

                refreshReturnedPermissions(
                    channelKey: channelKey,
                    permissions: permissions,
                    permissionCompletion: permissionCompletion)
            }
            else {

                // All permissions requested was refused
                permissionCompletion(permissions)
            }
        }
    }

    private static func shouldShowRationalePage(
        permissions:[String],
        channelKey:String?,
        permissionCompletion: @escaping ([String]) -> ()
    ) throws AwesomeNotificationException {

        if(showNotificationConfigPage()) {
            actionQueue.append({
                refreshReturnedPermissions(
                    channelKey: channelKey,
                    permissions: permissions,
                    permissionCompletion: permissionCompletion)
            })
        }
        else {
            refreshReturnedPermissions(
                channelKey: channelKey,
                permissions: permissions,
                permissionCompletion: permissionCompletion)
        }
    }

    private static func refreshReturnedPermissions(
        permissions:[String],
        channelKey:String?,
        permissionCompletion: @escaping ([String]) -> ()
    ){
        arePermissionsAllowed(
            channelKey: channelKey,
            permissions: permissions,
            permissionCompletion: { permissionsAllowed:[String] in     

                if(channelKey != nil){
                    
                    ChannelManager.updateChannelModelThroughPermissions(
                        channelKey: channelKey,
                        permissions: permissionsAllowed)
                }

                completion(permissions.filter { !permissionsAllowed.contains($0) })
            })
    }
    
    public static func updateChannelModelThroughPermissions( channelKey:String, permissions:[String] ){

        if permissions.isEmpty {
            return
        }

        guard var channelModel:NotificationChannelModel = ChannelManager.getChannelByKey(String) else {
            return
        }

        for permissionName:String in permissions {

            switch NotificationPermission.fromString(permissionName) {

                case .Alert:
                    channelModel.importance = NotificationImportance.Max
                    break

                case .Sound:
                    channelModel.playSound = true
                    break
                    
                case .Badge:
                    channelModel.channelShowBadge = true
                    break
                    
                case .Vibration:
                    channelModel.enableVibration = true
                    break
                    
                case .Light:
                    channelModel.enableLights = true
                    break
                    
                case .CriticalAlert:
                    channelModel.criticalAlerts = true
                    break
            }
        }

        ChannelManager.saveChannel(channel: channelModel)
    }

    public static func showNotificationConfigPage() -> Bool {
        return startTestedActivity(UIApplication.openSettingsURLString))
    }

    public static func startTestedActivity(_ url:String)) -> Bool {

        guard let settingsUrl = URL(string: url) else {
            return false
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            DispatchQueue.main.async {
                UIApplication.shared.open(settingsUrl, completionHandler: {})
            }
            return true
        }
        
        return false
    }

    public static func handlePermissionResult() {
        fireActivityCompletionHandle()
    }

    private static func fireActivityCompletionHandle(){
        
        while let actionCompletionHandler:ActivityCompletionHandler = activityQueue.first {
            activityQueue.remove(at: 0)
            actionCompletionHandler()
        }
    }
}
