enum NotificationImportance : String, CaseIterable, AbstractEnum {
      
    case None = "None"
    case Min = "Min"
    case Low = "Low"
    case Default = "Default"
    case High = "High"
    case Max = "Max"
    
    static func fromString(_ value: String?) -> AbstractEnum? {
        if(value == nil) { return self.allCases[0] }
        return self.allCases.first{ "\($0)" == value }
    }
    
}
