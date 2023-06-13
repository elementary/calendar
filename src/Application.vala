// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2023 elementary, Inc. (https://elementary.io)
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
 *
 * Authored by: Maxwell Barvian <maxwell@elementary.io>
 *              Corentin Noël <corentin@elementary.io>
 */

namespace Maya {
    public class Application : Gtk.Application {
        public MainWindow window;
        public static GLib.Settings? saved_state = null;
        public static GLib.Settings? wingpanel_settings = null;
        private static bool run_in_background = false;
        private static bool add_event = false;
        private static string show_day = null;

        private Xdp.Portal? portal = null;

        private const OptionEntry[] APP_OPTIONS = {
            { "add-event", 'a', 0, OptionArg.NONE, out add_event, N_("Create an event"), null },
            { "show-day", 's', 0, OptionArg.STRING, out show_day, N_("Focus the given day"), N_("date") },
            { "background", 'b', 0, OptionArg.NONE, out run_in_background, "Run the Application in background", null},
            { null }
        };

        static construct {
            if (SettingsSchemaSource.get_default ().lookup ("io.elementary.calendar.savedstate", true) != null) {
                saved_state = new GLib.Settings ("io.elementary.calendar.savedstate");
            }

            if (GLib.SettingsSchemaSource.get_default ().lookup ("io.elementary.desktop.wingpanel.datetime", true) != null) {
                wingpanel_settings = new GLib.Settings ("io.elementary.desktop.wingpanel.datetime");
            }
        }

        construct {
            flags |= ApplicationFlags.HANDLES_OPEN;

            application_id = Build.EXEC_NAME;

            Environment.set_variable ("GTK_USE_PORTAL", "1", true);
            GLib.Intl.setlocale (LocaleCategory.ALL, "");
            GLib.Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
            GLib.Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
            GLib.Intl.textdomain (GETTEXT_PACKAGE);

            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/io/elementary/calendar/Application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        protected override void activate () {
            new Calendar.TodayEventMonitor ();
            if (run_in_background) {
                run_in_background = false;
                hold ();

                ask_for_background.begin ((obj, res) => {
                    if (!ask_for_background.end (res)) {
                        release ();
                    }
                });

                return;
            }

            if (get_windows () != null) {
                get_windows ().data.present (); // present window if app is already running
                return;
            }

            if (show_day != null) {
                var date = Date ();
                date.set_parse (show_day);
                if (date.valid () == true) {
                    var datetime = get_selected_datetime ();
                    datetime = datetime.add_years ((int)date.get_year () - datetime.get_year ());
                    datetime = datetime.add_days ((int)date.get_day_of_year () - datetime.get_day_of_year ());

                    saved_state.set_string ("selected-day", datetime.format ("%Y-%j"));
                    saved_state.set_string ("month-page", datetime.format ("%Y-%m"));
                } else {
                    warning ("Invalid date '%s' - Ignoring", show_day);
                }
            }

            var calmodel = Calendar.EventStore.get_default ();
            calmodel.load_all_sources ();

            init_gui ();
            window.show_all ();

            if (add_event) {
                Idle.add (() => {
                    window.on_tb_add_clicked (window.calview.selected_date);
                    return false;
                });
            }

            var granite_settings = Granite.Settings.get_default ();
            var gtk_settings = Gtk.Settings.get_default ();

            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

            granite_settings.notify["prefers-color-scheme"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
            });
        }

        public override void open (File[] files, string hint) {
            if (get_windows () == null) {
                var calmodel = Calendar.EventStore.get_default ();
                calmodel.load_all_sources ();

                init_gui ();
                window.show_all ();
            } else {
                get_windows ().data.present (); // present window if app is already running
            }

            var dialog = new Maya.View.ImportDialog (files);
            dialog.transient_for = window;
            dialog.show_all ();
        }

        /**
         * Initializes the graphical window and its components
         */
        void init_gui () {
            int window_x, window_y;
            var rect = Gtk.Allocation ();

            saved_state.get ("window-position", "(ii)", out window_x, out window_y);
            saved_state.get ("window-size", "(ii)", out rect.width, out rect.height);

            window = new MainWindow (this);
            window.title = _(Build.APP_NAME);
            window.set_allocation (rect);

            if (window_x != -1 || window_y != -1) {
                window.move (window_x, window_y);
            }

            if (saved_state.get_boolean ("window-maximized")) {
                window.maximize ();
            }

            window.destroy.connect (on_quit);

            var quit_action = new SimpleAction ("quit", null);
            quit_action.activate.connect (() => {
                if (window != null) {
                    window.destroy ();
                }
            });

            add_action (quit_action);
            set_accels_for_action ("app.quit", { "<Control>q" });
        }

        private void on_quit () {
            Calendar.EventStore.get_default ().delete_trashed_calendars ();
        }

        public async bool ask_for_background () {
            const string[] DAEMON_COMMAND = { "io.elementary.calendar", "--background" };
            if (portal == null) {
                portal = new Xdp.Portal ();
            }

            string reason = _(
                "Calendar will automatically start when this device turns on " +
                "and run when its window is closed so that it can send event notifications."
            );
            var command = new GenericArray<unowned string> (2);
            foreach (unowned var arg in DAEMON_COMMAND) {
                command.add (arg);
            }

            var window = Xdp.parent_new_gtk (active_window);

            try {
                return yield portal.request_background (window, reason, command, AUTOSTART, null);
            } catch (Error e) {
                warning ("Error during portal request: %s", e.message);
                return e is IOError.FAILED;
            }
        }

        public static DateTime get_selected_datetime () {
            var selected_day = saved_state.get_string ("selected-day");
            if (selected_day == null || selected_day == "") {
                return new DateTime.now_local ();
            }

            var numbers = selected_day.split ("-", 2);
            var dt = new DateTime.local (int.parse (numbers[0]), 1, 1, 0, 0, 0);
            dt = dt.add_days (int.parse (numbers[1]) - 1);
            return dt;
        }

        public static int main (string[] args) {
            var context = new OptionContext (_("Calendar"));
            context.add_main_entries (Application.APP_OPTIONS, "maya");
            context.add_group (Gtk.get_option_group (true));

            try {
                context.parse (ref args);
            } catch (Error e) {
                warning (e.message);
            }

            GtkClutter.init (ref args);
            var app = new Application ();

            int res = app.run (args);
            ICal.Object.free_global_objects ();
            return res;
        }
    }
}
