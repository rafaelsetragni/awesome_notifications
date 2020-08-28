

protocol class Model {

    func fromMap(arguments: [String : AnyObject?]) -> Model
    func toMap() -> [String : AnyObject?]

    func getValueOrDefault<T>(arguments: [String : AnyObject?], reference: String) {
        value:T? = MapUtils.extractValue<T>(arguments, reference, expectedClass);

        if(value != nil) return value;

        return MapUtils.extractValue(Definitions.initialValues, reference, expectedClass);
    }

    func getEnumValueOrDefault<T>(Map<String, Object> arguments, String reference, Class<T> enumerator, T[] values) {
        String key = MapUtils.extractValue(arguments, reference, String.class).orNull();
        T defaultValue =  MapUtils.extractValue(Definitions.initialValues, reference, enumerator).orNull();
        if(key == nil) return defaultValue;

        for(T enumValue : values){
            if(enumValue.toString().toLowerCase().equals(key.toLowerCase())) return enumValue;
        }

        return defaultValue;
    }

    public abstract void validate(Context context) throws PushNotificationException ;
}