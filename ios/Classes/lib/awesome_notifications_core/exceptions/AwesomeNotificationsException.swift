enum AwesomeNotificationsException: Error {
    case exception
    case notificationNotAuthorized
    case notificationExpired
    case msg(_ msg:String)
    case invalidRequiredFields(msg:String)
    case cronException(msg:String, _ lenght:Int)
}
