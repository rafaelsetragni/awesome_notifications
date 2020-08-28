
class MapUtils {
    
    public static func isNullOrEmptyKey(map: [String : AnyObject?], key: String) -> Bool {

        if(map.isEmpty) { return true }

        let value:AnyObject? = map[key] ?? nil

        if(value == nil) { return true }

        if (value is String){
            if((value as! String).isEmpty) { return true }
        }
        else if (value is [String : AnyObject?]){
            if((value as! [String : AnyObject?]).isEmpty) { return true }
        }

        return false
    }

    public static func getValueOrDefault<T>(type: T.Type, reference: String, arguments: [String : AnyObject?]) -> T? {
        let value:AnyObject? = arguments[reference] ?? nil
        let defaultValue:T? = (Definitions.initialValues[reference] ?? nil) as T

        if(value == nil) { return defaultValue }

        if(T.self == Int.self){
            return (Int(value as? String ?? "") ?? 0) as T
        }

        if(T.self == Float.self){
            return (Float(value as? String ?? "") ?? 0) as T
        }

        if(T.self == Double.self){
            return (Double(value as? String ?? "") ?? 0) as T
        }

        return defaultValue
    }
    
    public static func getEnumOrDefault<T: AbstractEnum>(type: T.Type, reference: String, arguments: [String : AnyObject?]) -> T {
        let value:AnyObject? = arguments[reference] ?? nil
        let defaultValue:T = T.fromString(arguments[reference] as! String) as! T

        if(value == nil) { return defaultValue }
        return value as! T
    }
}
