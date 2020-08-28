enum MediaSource : String, CaseIterable, AbstractEnum {
    
    case Resource = "Resource"
    case Asset = "Asset"
    case File = "File"
    case Network = "Network"
    case Unknown = "Unknown"
    
    static func fromString(_ value: String?) -> AbstractEnum? {
        if(value == nil) { return self.allCases[0] }
        return self.allCases.first{ "\($0)" == value }
    }
    
}
