enum GroupAlertBehaviour : String, CaseIterable, AbstractEnum {
    
    case All = "All"
    case Summary = "Summary"
    case Children = "Children"
    
    static func fromString(_ value: String?) -> AbstractEnum? {
        if(value == nil) { return self.allCases[0] }
        return self.allCases.first{ "\($0)" == value }
    }
}
