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

    const OptionEntry[] options =  {
        { "debug", 'd', 0, OptionArg.NONE, out has_debug,
        N_("Print debug information"), null},
        { null }
    };

    public class Daemon : GLib.Application {
        private Gee.HashMap<E.CalComponent, string> event_uid;

        construct {
            load_today_events ();
            Timeout.add_seconds (86400, () => {
                event_uid.clear ();
                load_today_events ();
                return true;
            });
        }

        protected override void activate () {
            Gtk.main ();
        }

        private void load_today_events () {
            event_uid = new Gee.HashMap<E.CalComponent, string> ();
            var model = Maya.Model.CalendarModel.get_default ();
            model.events_added.connect (on_events_added);
            model.events_updated.connect (on_events_updated);
            model.events_removed.connect (on_events_removed);
            model.month_start = Maya.Util.get_start_of_month (new DateTime.now_local ());
        }

        private void on_events_added (E.Source source, Gee.Collection<E.CalComponent> events) {
            var extension = (E.SourceAlarms)source.get_extension (E.SOURCE_EXTENSION_ALARMS);
            if (extension.get_include_me () == false) {
                return;
            }

            Idle.add ( () => {
                foreach (var event in events)
                    add_event (source, event);

                return false;
            });
        }

        private void on_events_updated (E.Source source, Gee.Collection<E.CalComponent> events) {
            Idle.add ( () => {
                foreach (var event in events)
                    update_event (source, event);

                return false;
            });
        }

        private void on_events_removed (E.Source source, Gee.Collection<E.CalComponent> events) {
            Idle.add ( () => {
                foreach (var event in events)
                    remove_event (source, event);

                return false;
            });
        }

        private void add_event (E.Source source, E.CalComponent event) {
            unowned iCal.Component comp = event.get_icalcomponent ();
            debug ("Event [%s, %s, %s]".printf (comp.get_summary(), source.dup_display_name(), comp.get_uid()));
            foreach (var alarm_uid in event.get_alarm_uids ()) {
                E.CalComponentAlarm e_alarm = event.get_alarm (alarm_uid);
                E.CalComponentAlarmAction action;
                e_alarm.get_action (out action);
                switch (action) {
                    case (E.CalComponentAlarmAction.DISPLAY):
                        E.CalComponentAlarmTrigger trigger;
                        e_alarm.get_trigger (out trigger);
                        if (trigger.type == E.CalComponentAlarmTriggerType.RELATIVE_START) {
                            iCal.DurationType duration = trigger.rel_duration;
                            var start_time = Maya.Util.ical_to_date_time (comp.get_dtstart ());
                            var now = new DateTime.now_local ();
                            if (now.compare (start_time) > 0) {
                                continue;
                            }
                            start_time = start_time.add_weeks (-(int)duration.weeks);
                            start_time = start_time.add_days (-(int)duration.days);
                            start_time = start_time.add_hours (-(int)duration.hours);
                            start_time = start_time.add_minutes (-(int)duration.minutes);
                            start_time = start_time.add_seconds (-(int)duration.seconds);
                            if (start_time.get_year () == now.get_year () && start_time.get_day_of_year () == now.get_day_of_year ()) {
                                var time = time_until_now (start_time);
                                if (time >= 0) {
                                    add_timeout.begin (source, event, (uint)time);
                                }
                            }
                        }
                        continue;
                    default:
                        continue;
                }
            }
        }

        public async void add_timeout (E.Source source, E.CalComponent event, uint interval) {
            var uid = "%u-%u".printf (interval, GLib.Random.next_int ());
            event_uid.set (event, uid);
            debug ("adding timeout uid:%s", uid);
            Timeout.add_seconds (interval, () => {
                var extension = (E.SourceAlarms)source.get_extension (E.SOURCE_EXTENSION_ALARMS);
                if (extension != null) {
                    extension.set_last_notified (new DateTime.now_local ().to_string ());
                }

                queue_event_notification (event, uid);
                return false;
            });
        }

        public void queue_event_notification (E.CalComponent event, string uid) {
            if (event_uid.values.contains (uid) == false) {
                return;
            }

            unowned iCal.Component comp = event.get_icalcomponent ();
            var primary_text = "%s".printf (comp.get_summary ());
            var start_time = Maya.Util.ical_to_date_time (comp.get_dtstart ());
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

        private void update_event (E.Source source, E.CalComponent event) {
            remove_event (source, event);
            event.rescan ();
            event.commit_sequence ();
            add_event (source, event);
        }

        private void remove_event (E.Source source, E.CalComponent event) {
            if (event_uid.has_key (event)) {
                event_uid.unset (event);
            }
        }

        private TimeSpan time_until_now (GLib.DateTime dt) {
            var now = new DateTime.now_local ();
            return dt.difference (now)/TimeSpan.SECOND;
        }
    }

    public static int main (string[] args) {
        OptionContext context = new OptionContext ("");
        context.add_main_entries (options, null);

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

