
public class PushNotification : AbstractModel {
    
    var content:NotificationContentModel?
    var actionButtons:[NotificationButtonModel]?
    var schedule:NotificationScheduleModel?
    
    func fromMap(arguments: [String : Any?]?) -> AbstractModel {
        
        
        return self
    }
    
    func toMap() -> [String : Any?] {
        let mapData:[String: Any?] = [:]
        
        return mapData
    }
    
    func validate() throws {
        
    }
    
}
