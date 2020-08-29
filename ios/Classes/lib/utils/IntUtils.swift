
class IntUtils {

    public static func isNullOrEmpty(_ value:Int?) -> Bool {
        return value == nil
    }
    
    // Note: sometimes Json parser converts Integer into Double values
    public static func extractInteger(_ value: AnyObject?, defaultValue: AnyObject) -> Int {
        if(value == nil){
            return convertToInt(value: defaultValue) ?? 0;
        }
        return convertToInt(value: value) ?? 0;
    }

    public static func convertToInt(value: AnyObject?) -> Int? {
    
        var intValue:Int? = nil
        
        if(value != nil) {

            if (value is Int) {
                intValue = value as? Int
            } else
            if (value is Float) {
                intValue = Int(value as? Float ?? 0.0)
            } else
            if (value is Double) {
                intValue = Int(value as? Double ?? 0.0)
            } else
            if (value is String){
                intValue = Int(value as? String ?? "") ?? 0
            }
        }
        return intValue;
    }
}
