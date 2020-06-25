/*
 * Copyright 2018 elementary, Inc. (https://elementary.io)
 *           2014 Corentin Noël <corentin@elementary.io>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Maya {
    private static bool has_debug;

    const OptionEntry[] OPTIONS = {
        { "debug", 'd', 0, OptionArg.NONE, out has_debug,
        N_("Print debug information"), null},
        { null }
    };

    public class Daemon : GLib.Application {
        private Gee.HashMap<ECal.Component, string> component_uid;

        construct {
            load_today_components ();
            Timeout.add_seconds (86400, () => {
                component_uid.clear ();
                load_today_components ();
                return true;
            });
        }

        protected override void activate () {
            Gtk.main ();
        }

        private void load_today_components () {
            component_uid = new Gee.HashMap<ECal.Component, string> ();
            var store = Calendar.Store.get_event_store ();
            store.components_added.connect (on_components_added);
            store.components_modified.connect (on_components_modified);
            store.components_removed.connect (on_components_removed);
            store.month_start = Calendar.Util.datetime_get_start_of_month (new DateTime.now_local ());
        }

        private void on_components_added (Gee.Collection<ECal.Component> components, E.Source source, Gee.Collection<ECal.ClientView> views) {
            var extension = (E.SourceAlarms)source.get_extension (E.SOURCE_EXTENSION_ALARMS);
            if (extension.get_include_me () == false) {
                return;
            }

            foreach (var component in components)
                add_component (source, component);
        }

        private void on_components_modified (Gee.Collection<ECal.Component> components, E.Source source, Gee.Collection<ECal.ClientView> views) {
            foreach (var component in components)
                update_component (source, component);
        }

        private void on_components_removed (Gee.Collection<ECal.Component> components, E.Source source, Gee.Collection<ECal.ClientView> views) {
            foreach (var component in components)
                remove_component (source, component);
        }

        private void add_component (E.Source source, ECal.Component component) {
            unowned ICal.Component comp = component.get_icalcomponent ();
            debug ("component [%s, %s, %s]".printf (comp.get_summary (), source.dup_display_name (), comp.get_uid ()));
            foreach (var alarm_uid in component.get_alarm_uids ()) {
                ECal.ComponentAlarm e_alarm = component.get_alarm (alarm_uid);
                ECal.ComponentAlarmAction action;

#if E_CAL_2_0
                action = e_alarm.get_action ();
#else
                e_alarm.get_action (out action);
#endif
                switch (action) {
                    case (ECal.ComponentAlarmAction.DISPLAY):
                        ECal.ComponentAlarmTrigger trigger;
#if E_CAL_2_0
                        trigger = e_alarm.get_trigger ();
#else
                        e_alarm.get_trigger (out trigger);
#endif
                        if (trigger.get_kind () == ECal.ComponentAlarmTriggerKind.RELATIVE_START) {
                            ICal.Duration duration = trigger.get_duration ();
                            var start_time = Calendar.Util.icaltime_to_datetime (comp.get_dtstart ());
                            var now = new DateTime.now_local ();
                            if (now.compare (start_time) > 0) {
                                continue;
                            }
                            start_time = start_time.add_weeks (-(int)duration.get_weeks ()); //vala-lint=space-before-paren
                            start_time = start_time.add_days (-(int)duration.get_days ()); //vala-lint=space-before-paren
                            start_time = start_time.add_hours (-(int)duration.get_hours ()); //vala-lint=space-before-paren
                            start_time = start_time.add_minutes (-(int)duration.get_minutes ()); //vala-lint=space-before-paren
                            start_time = start_time.add_seconds (-(int)duration.get_seconds ()); //vala-lint=space-before-paren
                            if (start_time.get_year () == now.get_year () && start_time.get_day_of_year () == now.get_day_of_year ()) {
                                var time = time_until_now (start_time);
                                if (time >= 0) {
                                    add_timeout.begin (source, component, (uint)time);
                                }
                            }
                        }
                        continue;
                    default:
                        continue;
                }
            }
        }

        public async void add_timeout (E.Source source, ECal.Component component, uint interval) {
            var uid = "%u-%u".printf (interval, GLib.Random.next_int ());
            component_uid.set (component, uid);
            debug ("adding timeout uid:%s", uid);
            Timeout.add_seconds (interval, () => {
                var extension = (E.SourceAlarms)source.get_extension (E.SOURCE_EXTENSION_ALARMS);
                if (extension != null) {
                    extension.set_last_notified (new DateTime.now_local ().to_string ());
                }

                queue_component_notification (component, uid);
                return false;
            });
        }

        public void queue_component_notification (ECal.Component component, string uid) {
            if (component_uid.values.contains (uid) == false) {
                return;
            }

            unowned ICal.Component comp = component.get_icalcomponent ();
            var primary_text = "%s".printf (comp.get_summary ());
            var start_time = Calendar.Util.icaltime_to_datetime (comp.get_dtstart ());
            var now = new DateTime.now_local ();
            string secondary_text = "";
            var h24_settings = new GLib.Settings ("org.gnome.desktop.interface");
            var format = h24_settings.get_string ("clock-format");
            var text = Granite.DateTime.get_default_time_format (format.contains ("12h"));
            if (start_time.get_year () == now.get_year ()) {
                if (start_time.get_day_of_year () == now.get_day_of_year ()) {
                    secondary_text = Granite.DateTime.get_relative_datetime (start_time);
                } else {
                    secondary_text = start_time.format ("%s, %s".printf (Granite.DateTime.get_default_date_format (), text));
                }
            } else {
                secondary_text = start_time.format ("%s, %s".printf (Granite.DateTime.get_default_date_format (false, true, true), text));
            }

            var notification = new GLib.Notification (primary_text);
            notification.set_body (secondary_text);
            notification.set_icon (new ThemedIcon ("office-calendar"));

            GLib.Application.get_default ().send_notification (uid, notification);
        }

        private void update_component (E.Source source, ECal.Component component) {
            remove_component (source, component);
#if !E_CAL_2_0
            component.rescan ();
#endif
            component.commit_sequence ();
            add_component (source, component);
        }

        private void remove_component (E.Source source, ECal.Component component) {
            if (component_uid.has_key (component)) {
                component_uid.unset (component);
            }
        }

        private TimeSpan time_until_now (GLib.DateTime dt) {
            var now = new DateTime.now_local ();
            return dt.difference (now) / TimeSpan.SECOND;
        }
    }

    public static int main (string[] args) {
        OptionContext context = new OptionContext ("");
        context.add_main_entries (OPTIONS, null);

        try {
            context.parse (ref args);
        } catch (OptionError e) {
            error (e.message);
        }

        Granite.Services.Logger.initialize (Build.APP_NAME);
        Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.WARN;

        if (has_debug) {
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
        }

        var app = new Daemon ();

        return app.run (args);
    }
}
