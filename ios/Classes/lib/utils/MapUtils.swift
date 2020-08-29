
class MapUtils {
    
    public static func isNullOrEmptyKey(map: [String : Any?], key: String) -> Bool {

        if(map.isEmpty) { return true }

        let value:Any? = map[key] ?? nil

        if(value == nil) { return true }

        if (value is String){
            if((value as! String).isEmpty) { return true }
        }
        else if (value is [String : Any?]){
            if((value as! [String : Any?]).isEmpty) { return true }
        }

        return false
    }

    public static func getValueOrDefault<T>(type: T.Type, reference: String, arguments: [String : Any?]?) -> T? {
        let value:Any? = arguments?[reference] ?? nil
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
    
    public static func getEnumOrDefault<T: AbstractEnum>(type: T.Type, reference: String, arguments: [String : Any?]?) -> T {
        let value:Any? = arguments?[reference] ?? nil
        let defaultValue:T = T.fromString(Definitions.initialValues[reference] as? String) as! T

        if(value == nil) { return defaultValue }
        return value as! T
    }
}
