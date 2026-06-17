//
//  ExceptionFactory.swift
//  awesome_notifications
//
//  Created by CardaDev on 07/04/22.
//

import Foundation


public class ExceptionFactory {
    
    static let TAG:String = "ExceptionFactory"
    
    // ************** SINGLETON PATTERN ***********************
    
    static var instance:ExceptionFactory?
    public static var shared:ExceptionFactory {
        get {
            ExceptionFactory.instance = ExceptionFactory.instance ?? ExceptionFactory()
            return ExceptionFactory.instance!
        }
    }
    private init(){}
    
    // ************** FACTORY METHODS ***********************
    
    public func createNewAwesomeException(
                className:String,
                code:String,
                message:String,
                detailedCode:String
    ) -> AwesomeNotificationsException {
        return createNewAwesomeException(
                fromClassName: className,
                withAwesomeException:
                    AwesomeNotificationsException(
                        className: className,
                        code: code,
                        message: message,
                        detailedCode: detailedCode))
    }

    public func createNewAwesomeException(
            className:String,
            code:String,
            message:String,
            detailedCode:String,
            exception:Error
    ) -> AwesomeNotificationsException {
        return createNewAwesomeException(
                fromClassName: className,
                withAwesomeException:
                    AwesomeNotificationsException(
                        className: className,
                        code: code,
                        message: exception.localizedDescription,
                        detailedCode: detailedCode))
    }

    public func createNewAwesomeException(
            className:String,
            code:String,
            detailedCode:String,
            originalException:Error
    ) -> AwesomeNotificationsException {
        return createNewAwesomeException(
                fromClassName: className,
                withAwesomeException:
                    AwesomeNotificationsException(
                        className: className,
                        code: code,
                        message: originalException.localizedDescription,
                        detailedCode: detailedCode))
    }

    public func registerNewAwesomeException(
            className:String,
            code:String,
            message:String,
            detailedCode:String
    ) {
        _ = createNewAwesomeException(
                fromClassName: className,
                withAwesomeException:
                    AwesomeNotificationsException(
                        className: className,
                        code: code,
                        message: message,
                        detailedCode: detailedCode))
    }

    public func registerNewAwesomeException(
            className:String,
            code:String,
            message:String,
            detailedCode:String,
            originalException:Error
    ) {
        registerAwesomeException(
                fromClassName: className,
                withAwesomeException:
                    AwesomeNotificationsException(
                        className: className,
                        code: code,
                        message: message,
                        detailedCode: detailedCode))
    }

    public func registerNewAwesomeException(
            className:String,
            code:String,
            detailedCode:String,
            originalException:Error
    ) {
        registerAwesomeException(
            fromClassName: className,
            withAwesomeException:
                AwesomeNotificationsException(
                    className: className,
                    code: code,
                    message: originalException.localizedDescription,
                    detailedCode: detailedCode))
    }

    /// **************  FACTORY METHODS  *********************

    private func createNewAwesomeException(
        fromClassName className:String,
        withAwesomeException awesomeException:AwesomeNotificationsException
    ) -> AwesomeNotificationsException {
        AwesomeExceptionReceiver
                .shared
                .notifyExceptionEvent(
                    fromClassName: className,
                    withAwesomeException: awesomeException)
        return awesomeException
    }

    private func registerAwesomeException(
        fromClassName className:String,
        withAwesomeException awesomeException:AwesomeNotificationsException
    ) {
        AwesomeExceptionReceiver
                .shared
                .notifyExceptionEvent(
                    fromClassName: className,
                    withAwesomeException: awesomeException)
    }
}
