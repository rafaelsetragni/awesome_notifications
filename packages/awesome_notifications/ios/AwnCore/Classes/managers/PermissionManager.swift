//
//  PermissionManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 17/11/21.
//

import Foundation

typealias ActivityCompletionHandler = () -> ()

public class PermissionManager {
    
    private let TAG:String = "PermissionManager"

    private var activityQueue:SynchronizedArray = SynchronizedArray<ActivityCompletionHandler>()
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:PermissionManager?
    public static var shared:PermissionManager {
        get {
            PermissionManager.instance =
                PermissionManager.instance ?? PermissionManager()
            return PermissionManager.instance!
        }
    }
    private init(){}
    
    // ********************************************************

    private func getIosPermissionsCode(_ permissions:[String]) -> UNAuthorizationOptions {
        
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

    public func areNotificationsGloballyAllowed(whenGotResults permissionCompletion: @escaping (Bool) -> ()) {
             
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
    
    public func shouldShowRationale(
        _ permissions:[String],
        filteringByChannelKey channelKey:String?,
        whenGotResults completion: @escaping ([String]) -> ()
    ){
        var shouldShowRationaleList:[String] = []
        
        self.areNotificationsGloballyAllowed(whenGotResults: { (areAllowed) in
            
            if !areAllowed {
                completion(permissions)
                return
            }
            
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { iOSpermissions in
                
                for permission in permissions {
                    if let permissionEnum:NotificationPermission = NotificationPermission.fromString(permission) {
                        switch permissionEnum {
                            
                            case .Alert:
                                if(iOSpermissions.alertSetting != .enabled){
                                    shouldShowRationaleList.append(NotificationPermission.Alert.rawValue)
                                }
                                break
                            case .Sound:
                                if(iOSpermissions.soundSetting != .enabled){
                                    shouldShowRationaleList.append(NotificationPermission.Sound.rawValue)
                                }
                                break
                                
                            case .Badge:
                                if(iOSpermissions.badgeSetting != .enabled){
                                    shouldShowRationaleList.append(NotificationPermission.Badge.rawValue)
                                }
                                break
                                
                            case .Car:
                                if(iOSpermissions.carPlaySetting != .enabled){
                                    shouldShowRationaleList.append(NotificationPermission.Car.rawValue)
                                }
                                break
                            
                            case .OverrideDnD: fallthrough
                            case .CriticalAlert:
                                if #available(iOS 12.0, *) {
                                    if(iOSpermissions.criticalAlertSetting == .disabled){
                                        shouldShowRationaleList.append(NotificationPermission.CriticalAlert.rawValue)
                                    }
                                }
                                break
                                    
                            case .Provisional:
                                if #available(iOS 12.0, *) {
                                    if(iOSpermissions.authorizationStatus != .provisional){
                                        shouldShowRationaleList.append(NotificationPermission.Provisional.rawValue)
                                    }
                                }
                                break

                            default:
                                // Android only permissions do not require user intervention on iOS
                                break
                        }
                    }
                }

                completion(shouldShowRationaleList)
            })
        })
    }

    public func arePermissionsAllowed(
        _ permissions:[String],
        filteringByChannelKey channelKey:String?,
        whenGotResults completion: @escaping ([String]) -> ()) {

        var allowed:[String] = []
        
            self.areNotificationsGloballyAllowed(whenGotResults: { (areAllowed) in
                
            if !areAllowed {
                completion(allowed)
                return
            }
            
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { iOSpermissions in
                
                // (Settings != .Disabled == .Enabled & .NotSupported /*Emulator limitations*/)
                for permission in permissions {
                    if let permissionEnum:NotificationPermission = NotificationPermission.fromString(permission) {
                        switch permissionEnum {
                            
                            case .Alert:
                                if(iOSpermissions.alertSetting == .enabled){
                                    if(channelKey == nil || self.isSpecifiedChannelPermissionAllowed(channelKey: channelKey!, permissionEnum: permissionEnum)){
                                        allowed.append(NotificationPermission.Alert.rawValue)
                                    }
                                }
                                break
                            case .Sound:
                                if(iOSpermissions.soundSetting == .enabled){
                                    if(channelKey == nil || self.isSpecifiedChannelPermissionAllowed(channelKey: channelKey!, permissionEnum: permissionEnum)){
                                        allowed.append(NotificationPermission.Sound.rawValue)
                                    }
                                }
                                break
                                
                            case .Badge:
                                if(iOSpermissions.badgeSetting == .enabled){
                                    if(channelKey == nil || self.isSpecifiedChannelPermissionAllowed(channelKey: channelKey!, permissionEnum: permissionEnum)){
                                        allowed.append(NotificationPermission.Badge.rawValue)
                                    }
                                }
                                break
                                
                            case .Car:
                                if(iOSpermissions.carPlaySetting == .enabled){
                                    if(channelKey == nil || self.isSpecifiedChannelPermissionAllowed(channelKey: channelKey!, permissionEnum: permissionEnum)){
                                        allowed.append(NotificationPermission.Car.rawValue)
                                    }
                                }
                                break
                            
                            case .OverrideDnD: fallthrough
                            case .CriticalAlert:
                                if #available(iOS 12.0, *) {
                                    if(iOSpermissions.criticalAlertSetting == .enabled){
                                        if(channelKey == nil || self.isSpecifiedChannelPermissionAllowed(channelKey: channelKey!, permissionEnum: permissionEnum)){
                                            allowed.append(NotificationPermission.CriticalAlert.rawValue)
                                        }
                                    }
                                }
                                else {
                                    if(channelKey == nil || self.isSpecifiedChannelPermissionAllowed(channelKey: channelKey!, permissionEnum: permissionEnum)){
                                        allowed.append(NotificationPermission.CriticalAlert.rawValue)
                                    }
                                }
                                break
                                    
                            case .Provisional:
                                if #available(iOS 12.0, *) {
                                    if(iOSpermissions.authorizationStatus == .provisional){
                                        if(channelKey == nil || self.isSpecifiedChannelPermissionAllowed(channelKey: channelKey!, permissionEnum: permissionEnum)){
                                            allowed.append(NotificationPermission.Provisional.rawValue)
                                        }
                                    }
                                }
                                else {
                                    if(channelKey == nil || self.isSpecifiedChannelPermissionAllowed(channelKey: channelKey!, permissionEnum: permissionEnum)){
                                        allowed.append(NotificationPermission.Provisional.rawValue)
                                    }
                                }
                                break

                            default:
                                // Android only permissions are considered globally allowed on iOS
                                if(channelKey == nil || self.isSpecifiedChannelPermissionAllowed(channelKey: channelKey!, permissionEnum: permissionEnum)){
                                    allowed.append(permission)
                                }
                                break
                        }
                    }
                }

                completion(allowed)
            })
        })
    }

    public func isSpecifiedPermissionGloballyAllowed(_ permission:String, channel:String?, completion: @escaping (Bool) -> ()){

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
                
                case .OverrideDnD: fallthrough
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

    public func isSpecifiedChannelPermissionAllowed(
        channelKey:String, permissionEnum:NotificationPermission) -> Bool {

        guard let channelModel =
                        ChannelManager
                            .shared
                            .getChannelByKey(channelKey: channelKey)
        else {
            return false
        }

        if(channelModel.importance != NotificationImportance.None){

            switch (permissionEnum){

                case .Alert:
                    return channelModel.importance == NotificationImportance.Max ||
                           channelModel.importance == NotificationImportance.High;

                case .Sound:
                    return channelModel.playSound ?? false;

                case .Vibration:
                    return channelModel.enableVibration ?? false;

                case .Light:
                    return channelModel.enableLights ?? false;

                case .Badge:
                    return channelModel.channelShowBadge ?? false;

                case .CriticalAlert:
                    return channelModel.criticalAlerts ?? false;

                default:
                    return true;
            }

        }
        return false
    }

    public func requestUserPermissions(
        _ permissions:[String],
        filteringByChannelKey channelKey:String?,
        whenUserReturns permissionCompletion: @escaping ([String]) -> ()
    ) throws {

        if SwiftUtils.isRunningOnExtension() {
            // On Extensions, permissions are never requested
            // because there is no user interaction
            permissionCompletion(permissions)
            return
        }
        
        arePermissionsAllowed(
            permissions,
            filteringByChannelKey: channelKey,
            whenGotResults: { (permissionsAllowed) in
                
                let permissionsNeeded:[String] = permissions.filter({ !permissionsAllowed.contains($0) })
                var permissionsRequested = permissionsNeeded
                
                if permissionsNeeded.isEmpty {
                    permissionCompletion([])
                }
                
                else {
                    UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                        
                        var isAllowed:Bool = false
                        if #available(iOS 12.0, *) {
                            isAllowed =
                                (settings.authorizationStatus == .authorized) ||
                                (settings.authorizationStatus == .provisional)
                        } else {
                            isAllowed =
                                (settings.authorizationStatus == .authorized)
                        }
                        
                        if #available(iOS 12.0, *) {
                            if permissionsRequested.contains(NotificationPermission.CriticalAlert.rawValue) ||
                                permissionsRequested.contains(NotificationPermission.OverrideDnD.rawValue){
                                if(settings.criticalAlertSetting == .notSupported){
                                    Logger.e(self.TAG,
                                        "Critical Alerts are not available for this project. " +
                                        "You must require Apple special permissions to use it. " +
                                        "For more informations, please read our official documentation.")
                                    if permissionsRequested.count == 1 {
                                        permissionCompletion(permissionsNeeded)
                                        return
                                    }
                                    permissionsRequested = permissionsRequested.filter {
                                        ![NotificationPermission.CriticalAlert.rawValue, NotificationPermission.CriticalAlert.rawValue].contains($0)
                                    }
                                }
                            }
                        }
                        
                        if permissionsRequested.isEmpty {
                            permissionCompletion(permissions)
                            return
                        }

                        self.shouldShowRationale(permissionsRequested, filteringByChannelKey: channelKey, whenGotResults: { listToShowRationale in
                            
                            if listToShowRationale.count < 1 {
                                // There is no need for user intervention
                                self.refreshReturnedPermissions(
                                    permissionsNeeded,
                                    filteringByChannelKey: channelKey,
                                    whenUserReturns: permissionCompletion)
                                return
                            }
                            
                            if listToShowRationale.count == 1 {
                                
                                guard let permissionEnum = NotificationPermission.fromString(permissionsNeeded.first!) else {
                                    self.refreshReturnedPermissions(
                                        permissionsNeeded,
                                        filteringByChannelKey: channelKey,
                                        whenUserReturns: permissionCompletion)
                                    return
                                }
                                
                                switch permissionEnum {
                                    
                                    case .OverrideDnD: fallthrough
                                    case .CriticalAlert:
                                        if #available(iOS 12.0, *) {
                                            if(settings.criticalAlertSetting == .disabled){
                                                self.showRequestDialog(
                                                    channelKey: channelKey,
                                                    permissionsNeeded: permissionsNeeded,
                                                    permissionsToRequest: listToShowRationale,
                                                    permissionCompletion: permissionCompletion)
                                                return
                                            }
                                        }
                                        break
                                        
                                    default:
                                        break
                                }
                                
                            }
                            
                            if !isAllowed && settings.authorizationStatus == .notDetermined {
                                self.showRequestDialog(
                                    channelKey: channelKey,
                                    permissionsNeeded: permissionsNeeded,
                                    permissionsToRequest: listToShowRationale,
                                    permissionCompletion: permissionCompletion)
                            }
                            else {
                                self.showRationalePage(
                                    channelKey: channelKey,
                                    permissionsNeeded: permissionsNeeded,
                                    permissionCompletion: permissionCompletion)
                            }
                        })
                    }
                }
        })
    }

    private func showRequestDialog(
        channelKey:String?,
        permissionsNeeded:[String],
        permissionsToRequest:[String],
        permissionCompletion: @escaping ([String]) -> ()
    ) {
        
        let iOSpermissions:UNAuthorizationOptions = getIosPermissionsCode(permissionsToRequest)
        UNUserNotificationCenter.current().requestAuthorization(options: iOSpermissions) { (granted, error) in

            if granted {
                Logger.d("PermissionManager", "Permissions enabled successfully")

                self.refreshReturnedPermissions(
                    permissionsNeeded,
                    filteringByChannelKey: channelKey,
                    whenUserReturns: permissionCompletion)
            }
            else {

                // All permissions requested was refused
                permissionCompletion(permissionsNeeded)
            }
        }
    }

    private func showRationalePage(
        channelKey:String?,
        permissionsNeeded:[String],
        permissionCompletion: @escaping ([String]) -> ()
    ) {

        if(gotoNotificationConfigPage()) {
            activityQueue.append({ () in
                self.refreshReturnedPermissions(
                    permissionsNeeded,
                    filteringByChannelKey: channelKey,
                    whenUserReturns: permissionCompletion)
            })
        }
        else {
            self.refreshReturnedPermissions(
                permissionsNeeded,
                filteringByChannelKey: channelKey,
                whenUserReturns: permissionCompletion)
        }
    }

    private func refreshReturnedPermissions(
        _ permissions:[String],
        filteringByChannelKey channelKey:String?,
        whenUserReturns completionHanlder: @escaping ([String]) -> ()
    ){
        arePermissionsAllowed(
            permissions,
            filteringByChannelKey: nil,
            whenGotResults: { (permissionsAllowed:[String]) in

                if(channelKey != nil){
                    
                    self.updateChannelModelThroughPermissions(
                        channelKey: channelKey!,
                        permissions: permissionsAllowed)
                }

                completionHanlder(permissions.filter { !permissionsAllowed.contains($0) })
            })
    }
    
    public func updateChannelModelThroughPermissions( channelKey:String, permissions:[String] ){

        if permissions.isEmpty {
            return
        }

        guard let channelModel:NotificationChannelModel =
                ChannelManager
                    .shared
                    .getChannelByKey(channelKey: channelKey) else {
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
                
                default:
                    break
            }
        }

        ChannelManager
            .shared
            .saveChannel(channel: channelModel, setOnlyNew: false)
    }
    
    public func showNotificationConfigPage(whenUserReturns completionHandler: @escaping () -> ()) {
        if startTestedActivity(UIApplication.openSettingsURLString) {
            activityQueue.append(completionHandler)
        }
    }

    public func gotoNotificationConfigPage() -> Bool {
        return startTestedActivity(UIApplication.openSettingsURLString)
    }

    public func startTestedActivity(_ url:String) -> Bool {

        guard let settingsUrl = URL(string: url) else {
            return false
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            DispatchQueue.main.async {
                UIApplication.shared.open(settingsUrl)
            }
            return true
        }
        
        return false
    }
    public func handlePermissionResult() {
        fireActivityCompletionHandle()
    }

    private func fireActivityCompletionHandle(){
        
        while (!activityQueue.isEmpty) {
            if let actionCompletionHandler:ActivityCompletionHandler = activityQueue.first {
                activityQueue.remove(at: 0)
                actionCompletionHandler()
            }
        }
    }
}
