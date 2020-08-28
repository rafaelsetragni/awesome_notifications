
public class StringUtils {

    public static func isNullOrEmpty(value:String?) -> Bool {
        return value?.isEmpty ?? true
    }
}