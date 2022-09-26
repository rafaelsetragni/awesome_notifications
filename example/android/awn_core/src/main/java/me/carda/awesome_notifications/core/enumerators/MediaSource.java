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

//        if(valueList == null) return null;
//        for (MediaSource candidate : valueList) {
//            if (candidate.getSafeName().equalsIgnoreCase(reference)) {
//                return candidate;
//            }
//        }

        if (SafeEnum.charMatches(reference, stringLength, 0, 'n')){
            return Network;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'a')){
            return Asset;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'r')){
            return Resource;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'f')){
            return File;
        }
        if (SafeEnum.charMatches(reference, stringLength, 0, 'u')){
            return Unknown;
        }
        return null;
    }
}
