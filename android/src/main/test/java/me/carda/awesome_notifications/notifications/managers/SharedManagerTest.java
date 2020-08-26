package android.src.main.test.java.me.carda.awesome_notifications.notifications.managers;

import android.content.Context;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import me.carda.push_notifications.notifications.models.NotificationContentModel;

import static org.junit.Assert.*;

public class SharedManagerTest {

    Context mMockContext;
    SharedManager _shared;

    @Before
    public void setUp() throws Exception {
        ///mMockContext = new RenamingDelegatingContext(InstrumentationRegistry.getTargetContext(), "test_");
        //_shared = SharedManager.getInstance(mMockContext);
    }

    @After
    public void tearDown() throws Exception {
    }

    @Test
    public void getAll() {
    }

    @Test
    public void get() {
        NotificationContentModel content = NotificationContentModel.fromMap(null);

    }

    @Test
    public void set() {
    }

    @Test
    public void remove() {
    }
}