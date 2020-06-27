[DBus (name = "org.freedesktop.login1.Manager")]
interface LoginManager : Object {
    // Called when computer is going to sleep or waking up.
    // start is true when going to sleep, false when waking up.
    public signal void prepare_for_sleep (bool start);
}

/** Manages signals to keep temporal state up to date */
public class Maya.TimeManager : Object {
    private static TimeManager instance = null;
    private uint timeout_id = 0;
    private LoginManager? login_manager = null;

    public signal void on_update_today ();

    public TimeManager () {
        try {
            // Setup login_manager to listen for sleep signal.
            // When computer wakes up (!sleeping), update time.
            login_manager = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
            login_manager.prepare_for_sleep.connect ((sleeping) => {
                if (!sleeping) {
                    update_today ();
                }
            });

            // Watch the DBus time settings server: if it's present, time
            // settings are probably being changed and we should callback faster
            //  to keep up to date
            Bus.watch_name (BusType.SYSTEM, "org.freedesktop.timedate1", BusNameWatcherFlags.NONE, on_settings_watch, on_settings_unwatch);
        } catch (Error e) {
            warning (e.message);
        }

        setup_today_timeout ();
    }

    /** Send the on_update_today signal and setup the next timeout */
    private void update_today (bool update_fast = false) {
        debug ("Updating today");
        on_update_today ();
        setup_today_timeout (update_fast);
    }

    /** Set a new timeout for the end of the day */
    private void setup_today_timeout (bool update_fast = false) {
        if (timeout_id > 0) {
            GLib.Source.remove (timeout_id);
            timeout_id = 0;
        }

        uint interval; // Seconds until next callback
        if (update_fast) {
            // Update roughly every second to look current
            interval = 1;
        } else {
            // Creates a timer for the time until end of day, and adds an extra
            // second to be sure it's called after midnight.
            var now = new DateTime.now_local ();
            var tomorrow = Calendar.Util.datetime_strip_time (now.add_days (1));
            var seconds = (tomorrow.difference (now) / 1000000) + 1;
            interval = (uint)seconds;
        }
        debug (@"Setting new callback to update today in $(interval) seconds");
        timeout_id = GLib.Timeout.add_seconds ((uint) interval, () => {
            update_today (update_fast);
            return GLib.Source.REMOVE;
        });
    }

    /** When time settings server is present, start refreshing quickly */
    private void on_settings_watch () {
        debug ("Time settings present: updating quickly");
        update_today (true);
    }

    /** When time settings server disappears, stop refreshing quickly and return to normal */
    private void on_settings_unwatch () {
        debug ("Time settings closed: updating slowly");
        update_today (false);
    }

    public static TimeManager get_default () {
        if (instance == null) {
            instance = new TimeManager ();
        }

        return instance;
    }
}
