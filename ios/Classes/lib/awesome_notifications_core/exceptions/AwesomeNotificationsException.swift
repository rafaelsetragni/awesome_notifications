enum AwesomeNotificationsException: Error {
    case msg(code:ExceptionCode, _ msg:String)
    case cascade(code:ExceptionCode, originalException:Error)
}
