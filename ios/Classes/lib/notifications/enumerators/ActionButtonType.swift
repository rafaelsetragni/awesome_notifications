enum ActionButtonType : String, CaseIterable, AbstractEnum {
    
    case Default = "Default"
    case InputField = "InputField"
    case DisabledAction = "DisabledAction"
    case KeepOnTop = "KeepOnTop"
    
    static func fromString(_ value: String?) -> AbstractEnum? {
        if(value == nil) { return self.allCases[0] }
        return self.allCases.first{ "\($0)" == value }
    }
}
