// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2018 elementary, Inc. (https://elementary.io)
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
    namespace Option {
        private static bool ADD_EVENT = false;
        private static string SHOW_DAY = null;
        private static bool PRINT_VERSION = false;
    }

    public class Application : Gtk.Application {
        public MainWindow window;
        public static GLib.Settings saved_state;

        static construct {
            saved_state = new GLib.Settings ("io.elementary.calendar.savedstate");
        }

        construct {
            flags |= ApplicationFlags.HANDLES_OPEN;

            application_id = Build.EXEC_NAME;

            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.textdomain (Build.GETTEXT_PACKAGE);
        }

        public const OptionEntry[] app_options = {
            { "add-event", 'a', 0, OptionArg.NONE, out Option.ADD_EVENT, N_("Create an event"), null },
            { "show-day", 's', 0, OptionArg.STRING, out Option.SHOW_DAY, N_("Focus the given day"), N_("date") },
            { "version", 'v', 0, OptionArg.NONE, out Option.PRINT_VERSION, N_("Print version info and exit"), null },
            { null }
        };

        protected override void activate () {
            if (get_windows () != null) {
                get_windows ().data.present (); // present window if app is already running
                return;
            }

            if (Option.SHOW_DAY != null) {
                var date = Date ();
                date.set_parse (Option.SHOW_DAY);
                if (date.valid () == true) {
                    var datetime = Settings.SavedState.get_default ().get_selected ();
                    datetime = datetime.add_years ((int)date.get_year () - datetime.get_year ());
                    datetime = datetime.add_days ((int)date.get_day_of_year () - datetime.get_day_of_year ());
                    Settings.SavedState.get_default ().selected_day = datetime.format ("%Y-%j");
                    Settings.SavedState.get_default ().month_page = datetime.format ("%Y-%m");
                } else {
                    warning ("Invalid date '%s' - Ignoring", Option.SHOW_DAY);
                }
            }

            var calmodel = Model.CalendarModel.get_default ();
            calmodel.load_all_sources ();

            init_gui ();
            window.show_all ();

            if (Option.ADD_EVENT) {
                window.on_tb_add_clicked (window.calview.selected_date);
            }

            const string DESKTOP_SCHEMA = "io.elementary.desktop";
            const string DARK_KEY = "prefer-dark";

            var lookup = SettingsSchemaSource.get_default ().lookup (DESKTOP_SCHEMA, false);

            if (lookup != null) {
                var desktop_settings = new GLib.Settings (DESKTOP_SCHEMA);
                var gtk_settings = Gtk.Settings.get_default ();
                desktop_settings.bind (DARK_KEY, gtk_settings, "gtk_application_prefer_dark_theme", SettingsBindFlags.DEFAULT);
            }

            Gtk.main ();
        }

        public override void open (File[] files, string hint) {
            bool first_start = false;
            if (get_windows () == null) {
                var calmodel = Model.CalendarModel.get_default ();
                calmodel.load_all_sources ();

                init_gui ();
                window.show_all ();
                first_start = true;
            }

            var dialog = new Maya.View.ImportDialog (files);
            dialog.transient_for = window;
            dialog.show_all ();

            if (first_start) {
                Gtk.main ();
            }
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

            if (window_x != -1 ||  window_y != -1) {
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
            set_accels_for_action("app.quit", new string[] { "<Control>q" });
        }

        void on_quit () {
            Model.CalendarModel.get_default ().delete_trashed_calendars ();
            Gtk.main_quit ();
        }
    }

    public static int main (string[] args) {
        var context = new OptionContext (_("Calendar"));
        context.add_main_entries (Application.app_options, "maya");
        context.add_group (Gtk.get_option_group (true));

        try {
            context.parse (ref args);
        } catch (Error e) {
            warning (e.message);
        }

        if (Option.PRINT_VERSION) {
            stdout.printf("Maya %s\n", Build.VERSION);
            stdout.printf("Copyright 2011-2017 elementary LLC.\n");
            return 0;
        }

        GtkClutter.init (ref args);
        var app = new Application ();

        return app.run (args);
    }
}
