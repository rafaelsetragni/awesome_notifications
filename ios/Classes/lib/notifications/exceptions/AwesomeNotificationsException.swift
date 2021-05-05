enum AwesomeNotificationsException: Error {
    case exception
    case notificationNotAuthorized
    case exceptionMsg(msg:String)
    case invalidRequiredFields(msg:String)
    case cronException(msg:String, _ lenght:Int)
}
