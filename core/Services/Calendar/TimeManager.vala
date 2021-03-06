[DBus (name = "org.freedesktop.login1.Manager")]
private interface FDO.LoginManager : Object {
    // Called when computer is going to sleep or waking up.
    // start is true when going to sleep, false when waking up.
    public signal void prepare_for_sleep (bool start);
}

[DBus (name = "org.freedesktop.timedate1")]
private interface FDO.TimeDate1 : Object {
    public abstract string timezone {owned get;}
}

/** Manages signals to keep temporal state up to date */
public class Calendar.TimeManager : Object {
    public signal void on_update_today ();

    /* The system time zone as an ICal.Timezone */
    public ICal.Timezone system_timezone {get; private set;}

    private static TimeManager? instance = null;

    private uint timeout_id = 0;
    private FDO.LoginManager? login_manager = null;
    private FDO.TimeDate1? timedate1 = null;

    private TimeManager () {
        try {
            // Setup login_manager to listen for sleep signal.
            // When computer wakes up (!sleeping), update time.
            login_manager = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
            login_manager.prepare_for_sleep.connect ((sleeping) => {
                if (!sleeping) {
                    on_update_today ();
                    setup_today_timeout ();
                }
            });

            // Watch the DBus time settings server: if it's present, time
            // settings are probably being changed and we should callback faster
            // to keep up to date
            Bus.watch_name (BusType.SYSTEM, "org.freedesktop.timedate1", BusNameWatcherFlags.NONE, on_settings_watch, on_settings_unwatch);
        } catch (Error e) {
            warning (e.message);
        }

#if E_CAL_2_0
        this.system_timezone = ECal.util_get_system_timezone ().copy ();
#else
        this.system_timezone = ECal.Util.get_system_timezone ().copy ();
#endif
        setup_today_timeout ();
    }

    /** Set a new timeout for the end of the day */
    private void setup_today_timeout () {
        if (timeout_id > 0) {
            GLib.Source.remove (timeout_id);
            timeout_id = 0;
        }

        // Creates a timer for the time until end of day, and adds an extra
        // second to be sure it's called after midnight.
        var now = new DateTime.now_local ();
        var tomorrow = Calendar.Util.datetime_strip_time (now.add_days (1));
        var seconds = (tomorrow.difference (now) / 1000000) + 1;
        uint interval = (uint)seconds; // Seconds until next callback
        debug (@"Setting new callback to update today in $(interval) seconds");
        timeout_id = GLib.Timeout.add_seconds (interval, () => {
            on_update_today ();
            setup_today_timeout ();
            return GLib.Source.REMOVE;
        });
    }

    private void on_timedate_properties_changed (Variant changed_properties, string[] invalidated_properties) {
        var timezone = changed_properties.lookup_value ("Timezone", GLib.VariantType.STRING);
        if (timezone != null) {
#if E_CAL_2_0
            this.system_timezone = ECal.util_get_system_timezone ().copy ();
#else
            this.system_timezone = ECal.Util.get_system_timezone ().copy ();
#endif
        }

        var timeusec = changed_properties.lookup_value ("TimeUSec", GLib.VariantType.UINT64);
        if (timezone != null || timeusec != null) {
            on_update_today ();
            setup_today_timeout ();
        }
    }

    /** When time settings server is present, start refreshing quickly */
    private void on_settings_watch () {
        try {
            timedate1 = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.timedate1", "/org/freedesktop/timedate1");
            ((DBusProxy)timedate1).g_properties_changed.connect (on_timedate_properties_changed);
        } catch (Error e) {
            critical (e.message);
        }
    }

    private void on_settings_unwatch () {
        if (timedate1 != null) {
            ((DBusProxy)timedate1).g_properties_changed.disconnect (on_timedate_properties_changed);
        }

        timedate1 = null;
    }

    public static unowned TimeManager get_default () {
        if (instance == null) {
            instance = new TimeManager ();
        }

        return instance;
    }

    // Sets up a new TimeManager for testing, which uses settable values.
    // This overwrites the default instance, so once this is called it can be
    // get_default can be used as usual to return the test object.
    public static unowned TimeManager setup_test (ICal.Timezone system_timezone) {
        if (instance != null) {
            warning ("Resetting default TimeManager to new testing instance");
        }

        instance = new TimeManager.for_testing (system_timezone);
        return instance;
    }

    private TimeManager.for_testing (ICal.Timezone system_timezone) {
        this.system_timezone = system_timezone;
    }
}
