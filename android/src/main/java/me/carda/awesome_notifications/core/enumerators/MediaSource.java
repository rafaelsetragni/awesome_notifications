package me.carda.awesome_notifications.core.enumerators;

public enum MediaSource implements SafeEnum {
    Resource("Resource"),
    Asset("Asset"),
    File("File"),
    Network("Network"),
    Unknown("Unknown");

    private final String safeName;
    MediaSource(final String safeName){
        this.safeName = safeName;
    }

    @Override
    public String getSafeName() {
        return safeName;
    }

    static MediaSource[] valueList = MediaSource.class.getEnumConstants();
    public static MediaSource getSafeEnum(String reference) {
        if (reference == null) return null;
        int stringLength = reference.length();
        if (stringLength == 0) return null;

        if(valueList == null) return null;
        for (MediaSource candidate : valueList) {
            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
                return candidate;
            }
        }

//    public static MediaSource getSafeEnum(String name) {
//        if (name == null) return null;
//        int stringLength = name.length();
//        if (stringLength == 0) return null;
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'n')){
//            return Network;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'a')){
//            return Asset;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'r')){
//            return Resource;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'f')){
//            return File;
//        }
//        else if (SafeEnum.charMatches(name, stringLength, 0, 'u')){
//            return Unknown;
//        }
        return null;
    }
}
