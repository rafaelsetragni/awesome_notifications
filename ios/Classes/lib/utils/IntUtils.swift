package me.carda.awesome_notifications.utils;

public class IntUtils {

    // Note: sometimes Json parser converts Integer into Double values
    public static extractInteger(value: AnyObject?) -> Int { 
        return extractInteger(value: value, 0);
    }

    // Note: sometimes Json parser converts Integer into Double values
    public static func extractInteger(value: AnyObject?, defaultValue: AnyObject) -> Int {
        if(value == nil){
            return convertToInt(value: defaultValue);
        }
        return convertToInt(value: value);
    }

    public static func convertToInt(value: AnyObject?) -> Int {
    
        var intValue?
        
        if(value != nil) {

            if (value is Int) {
                intValue = value as! Int
            } else
            if (value is Float) {
                intValue = Int(value as! Float)
            } else
            if (value is Double) {
                intValue = Int(value as! Double)
            } else
            if (value is String){
                do {
                    intValue = Int(value as! String) ?? 0
                } catch {
                    print("Unexpected error: \(error).")
                }
            }
        }
        return intValue;
    }
}
