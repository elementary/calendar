public class Maya.TimeManager : Object{
    private static TimeManager instance = null;
    private uint timeout_id = 0;

    public signal void on_update_today ();

    public TimeManager () {
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

        var now = new DateTime.now_local ();

        // For testing purposes, wait less than 24 hours to see the effect
        // var tomorrow = Util.strip_time (now.add_days (1));
        var tomorrow = now.add_seconds (10);

        var interval = tomorrow.difference (now) / 1000000;

        timeout_id = GLib.Timeout.add_seconds ((uint) interval, callback_update_today);
    }

    public static TimeManager get_default () {
        if (instance == null) {
            instance = new TimeManager ();
        }

        return instance;
    }
}
