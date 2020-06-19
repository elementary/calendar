[DBus (name = "org.freedesktop.login1.Manager")]
interface LoginManager : Object {
    // Called when computer is going to sleep or waking up.
    // start is true when going to sleep, false when waking up.
    public signal void prepare_for_sleep (bool start);
}

public class Maya.TimeManager : Object {
    private static TimeManager instance = null;
    private uint timeout_id = 0;
    private LoginManager? manager = null;

    public signal void on_update_today ();

    public TimeManager () {
        try {
            // Setup manager to listen for sleep signal.
            // When computer wakes up (!sleeping), update time.
            manager = Bus.get_proxy_sync (BusType.SYSTEM, "org.freedesktop.login1", "/org/freedesktop/login1");
            manager.prepare_for_sleep.connect ((sleeping) => {
                if (!sleeping) {
                    callback_update_today ();
                }
            });
        } catch (Error e) {
            warning (e.message);
        }

        setup_today_callback ();
    }

    private bool callback_update_today () {
        debug ("Updating today");
        on_update_today ();
        setup_today_callback ();
        return false;
    }

    private void setup_today_callback () {
        debug ("Setting new callback to update today");
        if (timeout_id > 0) {
            GLib.Source.remove (timeout_id);
            timeout_id = 0;
        }

        // Sets a timeout that will call at the end of the day.
        // Creates a timer for the time until end of day, and adds an extra
        // second to be sure it's called after midnight.
        var now = new DateTime.now_local ();
        var tomorrow = Util.strip_time (now.add_days (1));
        var interval = (tomorrow.difference (now) + 1) / 1000000;
        assert (interval >= 0);
        timeout_id = GLib.Timeout.add_seconds ((uint) interval, callback_update_today);
    }

    public static TimeManager get_default () {
        if (instance == null) {
            instance = new TimeManager ();
        }

        return instance;
    }
}
