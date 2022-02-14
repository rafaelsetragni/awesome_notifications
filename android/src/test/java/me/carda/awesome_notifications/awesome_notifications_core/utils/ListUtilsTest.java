package me.carda.awesome_notifications.awesome_notifications_core.utils;

import org.junit.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.junit.Assert.*;

public class ListUtilsTest {

    @Test
    public void isNullOrEmpty() {
        assertTrue("null values must are considered empty and must return true", ListUtils.isNullOrEmpty(null));
        assertTrue("null values must are considered empty and must return true", ListUtils.isNullOrEmpty(new ArrayList<>()));

        List test1 = new ArrayList<>();
        test1.add(1);
        assertFalse("List with values are considered not empty and must return false", ListUtils.isNullOrEmpty(test1));
    }

    @Test
    public void listHasDuplicates(){
        assertFalse("List with unique values do not have duplicates", ListUtils.listHasDuplicates(Arrays.asList(1,2,3,4,5,6)));
        assertTrue("List with not unique values have duplicates", ListUtils.listHasDuplicates(Arrays.asList(1,2,3,4,5,6,1)));
        assertTrue("List with unique values do not have duplicates", ListUtils.listHasDuplicates(Arrays.asList(1,1,2,3,4,5,6)));
        assertTrue("List with unique values do not have duplicates", ListUtils.listHasDuplicates(Arrays.asList(1,2,3,1,4,5,6)));
        assertTrue("List with unique values do not have duplicates", ListUtils.listHasDuplicates(Arrays.asList(1,1,1,1,1,1)));
    }
}