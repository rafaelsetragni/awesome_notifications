package me.carda.awesome_notifications.core.utils;

import java.util.List;

import javax.annotation.Nullable;

public class ListUtils {
    public static boolean isNullOrEmpty(@Nullable List<?> list){
        return list == null || list.isEmpty();
    }

    public static boolean listHasDuplicates(List<Object> list){
        for(int position = 0; position < list.size(); position++)
            for(int searchPointer = position + 1; searchPointer < list.size(); searchPointer++)
                if(CompareUtils.assertEqualObjects(list.get(position), list.get(searchPointer)))
                    return true;
        return false;
    }
}
