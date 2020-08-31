enum PushNotificationError: Error {
    case exception
    case exceptionMsg(msg:String)
    case invalidRequiredFields(msg:String)
    case cronException(msg:String, _ lenght:Int)
}
