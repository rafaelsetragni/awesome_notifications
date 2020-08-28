
class MapUtils {
    
    public static func isNullOrEmptyKey(map: [String : AnyObject?], key: String) -> Bool {

        if(map == nil || map.isEmpty) { return true }

        value:AnyObject? = map[key]

        if(value == nil) { return true }

        if (value is String){
            if((value as String).isEmpty) { return true }
        }
        else if (value is [String : AnyObject?]){
            if((value as [String : AnyObject?]).isEmpty) { return true }
        }

        return false
    }

    public static func getValueOrDefault<T>(arguments: [String : AnyObject?], reference: String) -> T? {
        var value:AnyObject? = arguments[reference]
        var defaultValue:T? = Definitions.initialValues[reference]

        if(value == nil) { return defaultValue }

        if T == Int {
            return Int(value as? String ?? "") ?? 0
        }

        if T == Float {
            return Float(value as? String ?? "") ?? 0
        }

        if T == Double {
            return Double(value as? String ?? "") ?? 0
        }

        if value is T {
            return value as T
        }

        return defaultValue
    }    
}