enum NotificationPrivacy : String, CaseIterable, AbstractEnum {
    
    case Public = "Public"
    case Secret = "Secret"
    case Private = "Private"
    
    static func fromString(_ value: String?) -> AbstractEnum? {
        if(value == nil) { return self.allCases[0] }
        return self.allCases.first{ "\($0)" == value }
    }
}
