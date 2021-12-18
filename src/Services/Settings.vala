/*
 * Copyright 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[DBus (name = "org.freedesktop.portal.Settings")]
private interface Portal.Settings : DBusProxy {
    public abstract void read (string name_space, string key, out Variant @value) throws Error;
    public abstract HashTable<string, HashTable<string, Variant>> read_all (string[] name_spaces) throws Error;
    public signal void settings_changed (string name_space, string key, Variant @value);
}

[SingleInstance]
public class Calendar.Settings : Object {
    public enum ClockFormat {
        24H,
        12H
    }

    // application settings
    public DateTime date { get; set; }
    public WindowState window { get; set; }
    public bool background { get; set; }

    // external settings
    public bool show_weeks { get; set; default = true; }
    public DateWeekday first_weekday { get; set; default = DateWeekday.MONDAY; }
    public ClockFormat clock_format { get; set; default = ClockFormat.12H; }

    private const string PORTAL_DESKTOP_NAME = "org.freedesktop.portal.Desktop";
    private const string PORTAL_DESKTOP_PATH = "/org/freedesktop/portal/desktop";

    private const string DAEMON_DATE_TIME_SCHEMA = "io.elementary.settings-daemon.datetime";
    private const string GNOME_DESKTOP_SCHEMA = "org.gnome.desktop.interface";

    construct {
        var schema_source = SettingsSchemaSource.get_default ();
        window = new WindowState ();

        if (schema_source.lookup ("io.elementary.calendar.savedstate", true) != null) {
            var saved_state = new GLib.Settings ("io.elementary.calendar.savedstate");
            saved_state.bind ("background", this, "background", SettingsBindFlags.DEFAULT);
            saved_state.bind ("show-weeks", this, "show-weeks", SettingsBindFlags.DEFAULT);
            window.bind (saved_state);

            string day = saved_state.get_string ("selected-day");
            string month = saved_state.get_string ("month-page");

            if ( day != "" || month != "") {
                int y = 1, m = 1, d = 1;

                if (month != null) {
                    var split = month.split ("-", 2);
                    y = int.parse (split[0]);
                    m = int.parse (split[1]);
                }

                if (day != null) {
                    var split = day.split ("-", 2);
                    if (y == 1) {
                        y = int.parse (split[0]);
                    }

                    d = int.parse (split[1]);
                }

                date = new DateTime.local (y, m, d, 0, 0, 0);
            }

            notify["date"].connect (() => {
                saved_state.set ("selected-day", "s", date.format ("%Y-%j"));
                saved_state.set ("month-page", "s", date.format ("%Y-%m"));
            });
        }

        try {
            Portal.Settings portal = Bus.get_proxy_sync (BusType.SESSION, PORTAL_DESKTOP_NAME, PORTAL_DESKTOP_PATH);
            var keys = portal.read_all ({ DAEMON_DATE_TIME_SCHEMA, GNOME_DESKTOP_SCHEMA });
            if (keys.length > 0) {
                if (DAEMON_DATE_TIME_SCHEMA in keys) {
                    var daemon = keys[DAEMON_DATE_TIME_SCHEMA];
                    show_weeks = daemon["show-weeks"].get_boolean ();
                    first_weekday = parse_weekday_name (daemon["week-start-day-name"]);
                }

                if (GNOME_DESKTOP_SCHEMA in keys) {
                    var gnome = keys[GNOME_DESKTOP_SCHEMA];
                    clock_format = gnome["clock-format"].get_string () == "24h" ? ClockFormat.24H : ClockFormat.12H;
                }

                portal.settings_changed.connect ((schema, key, val) => {
                    if (schema == DAEMON_DATE_TIME_SCHEMA) {
                        if (key == "show-weeks") {
                            show_weeks = val.get_boolean ();
                        }

                        if (key == "week-start-day-name") {
                            first_weekday = parse_weekday_name (val);
                        }
                    }

                    if (schema == GNOME_DESKTOP_SCHEMA && key == "clock-format") {
                        clock_format = val.get_string () == "24h" ? ClockFormat.24H : ClockFormat.12H;
                    }
                });
            }
        } catch (Error e) {
            warning ("cannot connect to settings portal: %s", e.message);

            /* we use only SettingsBindFlags.GET here, so we keep the same behaviour from the portal
             * if we end using the fallback show-weeks settings, we allow writing that
             */
            if (schema_source.lookup (DAEMON_DATE_TIME_SCHEMA, true) != null) {
                var daemon = new GLib.Settings (DAEMON_DATE_TIME_SCHEMA);
                daemon.bind ("show-weeks", this, "show-weeks", SettingsBindFlags.GET);
                daemon.bind_with_mapping (
                    "week-start-day-name",
                    this,
                    "first-weekday",
                    SettingsBindFlags.GET,
                    (val, @var) => {
                        val = parse_weekday_name (@var);
                        return true;
                    },
                    (v, t, d) => {
                        warning ("this callback shouldn't be called");
                        return ((GLib.Settings) d).get_value ("week-start-day-name");
                    },
                    daemon, null
                );
            }

            if (schema_source.lookup (GNOME_DESKTOP_SCHEMA, true) != null) {
                var gnome = new GLib.Settings (GNOME_DESKTOP_SCHEMA);
                gnome.bind_with_mapping (
                    "clock-format",
                    this,
                    "clock-format",
                    SettingsBindFlags.GET,
                    (val, @var) => {
                        val = @var.get_string () == "24h" ? ClockFormat.24H : ClockFormat.12H;
                        return true;
                    },
                    (v, t, d) => {
                        warning ("this callback shouldn't be called");
                        return ((GLib.Settings) d).get_value ("clock-format");
                    },
                    gnome, null
                );
            }
        }
    }

    public static string time_format () {
        // If AM/PM doesn't exist, use 24h.
        if (Posix.nl_langinfo (Posix.NLItem.AM_STR) == null || Posix.nl_langinfo (Posix.NLItem.AM_STR) == "") {
            return Granite.DateTime.get_default_time_format (false);
        }

        return Granite.DateTime.get_default_time_format (new Settings ().clock_format == ClockFormat.12H);
    }

    private static DateWeekday parse_weekday_name (Variant variant) {
        switch (variant.get_string ()) {
            case "friday":
                return DateWeekday.FRIDAY;
            case "monday":
                return DateWeekday.MONDAY;
            case "saturday":
                return DateWeekday.SATURDAY;
            case "sunday":
                return DateWeekday.SUNDAY;
            case "thursday":
                return DateWeekday.THURSDAY;
            case "tuesday":
                return DateWeekday.TUESDAY;
            case "wednesday":
                return DateWeekday.WEDNESDAY;
            default:
                return DateWeekday.BAD_WEEKDAY;
        }
    }

    public class WindowState : Object {
        [Compact]
        private class ObjData {
            public WindowState self;
            public string property_name;

            public ObjData (WindowState self, string property_name) {
                this.self = self;
                this.property_name = property_name;
            }
        }

        // values get from the settings default values, for when we can't access them
        public int x { get; set; default = -1; }
        public int y { get; set; default = -1; }
        public int width { get; set; default = 1024; }
        public int height { get; set; default = 750; }
        public bool maximized { get; set; default = false; }
        public int hpaned { get; set; default = 650; }

        public void bind (GLib.Settings settings) {
            settings.bind_with_mapping (
                "window-position", this, "x", SettingsBindFlags.DEFAULT,
                get_first_child, set_first_child, new ObjData (this, "y"),
                null
            );

            settings.bind_with_mapping (
                "window-position", this, "y", SettingsBindFlags.DEFAULT,
                get_second_child, set_second_child, new ObjData (this, "x"),
                null
            );

            settings.bind_with_mapping (
                "window-size", this, "width", SettingsBindFlags.DEFAULT,
                get_first_child, set_first_child, new ObjData (this, "height"),
                null
            );

            settings.bind_with_mapping (
                "window-size", this, "height", SettingsBindFlags.DEFAULT,
                get_second_child, set_second_child, new ObjData (this, "width"),
                null
            );

            settings.bind ("window-maximized", this, "maximized", SettingsBindFlags.DEFAULT);
            settings.bind ("hpaned-position", this, "hpaned", SettingsBindFlags.DEFAULT);
        }

        private static bool get_first_child (Value @value, Variant variant) {
            @value = variant.get_child_value (0).get_int32 ();
            return true;
        }

        private static bool get_second_child (Value @value, Variant variant) {
            @value = variant.get_child_value (1).get_int32 ();
            return true;
        }

        private static Variant set_first_child (Value @value, VariantType type, void* data) {
            unowned var o = (ObjData) data;
            int first, second;

            o.self.get (o.property_name, out second);
            first = @value.get_int ();

            return new Variant ("(ii)", first, second);
        }

        private static Variant set_second_child (Value @value, VariantType type, void* data) {
            unowned var o = (ObjData) data;
            int first, second;

            o.self.get (o.property_name, out first);
            second = @value.get_int ();

            return new Variant ("(ii)", first, second);
        }

    }
}
