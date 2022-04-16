public class AwesomeNotificationsException: Error {
    public let className:String
    public let code:String
    public let message:String
    public let detailedCode:String
    
    init(className:String, code:String, message:String, detailedCode:String){
        self.className = className
        self.code = code
        self.message = message
        self.detailedCode = detailedCode
    }
}
