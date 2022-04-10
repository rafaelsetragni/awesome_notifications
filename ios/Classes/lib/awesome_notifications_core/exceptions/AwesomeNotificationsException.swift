public class AwesomeNotificationsException: Error {
    let className:String
    let code:String
    let message:String
    let detailedCode:String
    
    init(className:String, code:String, message:String, detailedCode:String){
        self.className = className
        self.code = code
        self.message = message
        self.detailedCode = detailedCode
    }
}
