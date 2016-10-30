// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (https://launchpad.net/maya)
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
            stdout.printf("Copyright 2011-2015 Maya Developers.\n");
            return 0;
        }

        GtkClutter.init (ref args);
        var app = new Application ();

        return app.run (args);

    }

    /**
     * Main application class.
     */
    public class Application : Granite.Application {

        /**
         * Initializes environment variables
         */
        construct {
            flags |= ApplicationFlags.HANDLES_OPEN;

            // App info
            build_data_dir = Build.DATADIR;
            build_pkg_data_dir = Build.PKGDATADIR;
            build_release_name = Build.RELEASE_NAME;
            build_version = Build.VERSION;
            build_version_info = Build.VERSION_INFO;

            program_name = _(Build.APP_NAME);
            exec_name = "maya-calendar";

            app_years = "2011-2016";
            application_id = "org.pantheon.maya";
            app_icon = "office-calendar";
            app_launcher = "org.pantheon.maya.desktop";

            main_url = "https://launchpad.net/maya";
            bug_url = "https://bugs.launchpad.net/maya";
            help_url = "https://elementary.io/help/maya";
            translate_url = "https://translations.launchpad.net/maya";

            about_authors = {
                "Maxwell Barvian <maxwell@elementary.io>",
                "Jaap Broekhuizen <jaapz.b@gmail.com>",
                "Avi Romanoff <aviromanoff@gmail.com>",
                "Allen Lowe <lallenlowe@gmail.com>",
                "Niels Avonds <niels.avonds@gmail.com>",
                "Corentin Noël <corentin@elementary.io>"
            };
            about_documenters = {
                "Maxwell Barvian <maxwell@elementary.io>"
            };
            about_artists = {
                "Daniel Foré <daniel@elementary.io>"
            };
            about_translators = _("translator-credits");
            about_license_type = Gtk.License.GPL_3_0;
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.textdomain (Build.GETTEXT_PACKAGE);
        }

        public const OptionEntry[] app_options = {
            { "add-event", 'a', 0, OptionArg.NONE, out Option.ADD_EVENT, "Show an add event dialog", null },
            { "show-day", 's', 0, OptionArg.STRING, out Option.SHOW_DAY, "Start focused to the given day", null },
            { "version", 'v', 0, OptionArg.NONE, out Option.PRINT_VERSION, "Print version info and exit", null },
            { null }
        };

        public Gtk.Window window;
        View.MayaToolbar toolbar;
        View.CalendarView calview;
        View.AgendaView sidebar;
        Gtk.Paned hpaned;
        Gtk.Grid gridcontainer;
        Gtk.InfoBar infobar;
        Gtk.Label infobar_label;

        /**
         * Called when the application is activated.
         */
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
                on_tb_add_clicked (calview.selected_date);
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
            if (first_start)
                Gtk.main ();
        }

        /**
         * Initializes the graphical window and its components
         */
        void init_gui () {
            create_window ();
            var saved_state = Settings.SavedState.get_default ();

            sidebar = new View.AgendaView ();
            // Don't automatically display all the widgets on the sidebar
            sidebar.no_show_all = true;
            sidebar.show ();
            sidebar.event_removed.connect (on_remove);
            sidebar.event_modified.connect (on_modified);
            sidebar.set_size_request(160,0);

            calview = new View.CalendarView ();
            calview.vexpand = true;
            calview.on_event_add.connect ((date) => on_tb_add_clicked (date));
            calview.edition_request.connect (on_modified);
            calview.selection_changed.connect ((date) => sidebar.set_selected_date (date));

            gridcontainer = new Gtk.Grid ();
            gridcontainer.orientation = Gtk.Orientation.VERTICAL;

            hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            hpaned.pack1 (calview, true, false);
            hpaned.pack2 (sidebar, true, false);
            hpaned.position = saved_state.hpaned_position;

            infobar_label = new Gtk.Label (null);
            infobar_label.show ();
            infobar = new Gtk.InfoBar ();
            infobar.message_type = Gtk.MessageType.ERROR;
            infobar.show_close_button = true;
            infobar.get_content_area ().add (infobar_label);
            infobar.no_show_all = true;
            infobar.response.connect ((id) => infobar.hide ());
            Model.CalendarModel.get_default ().error_received.connect ((message) => {
                Idle.add (() => {
                    infobar_label.label = message;
                    infobar.show ();
                    return false;
                });
            });

            gridcontainer.add (infobar);
            gridcontainer.add (hpaned);
            window.add (gridcontainer);

            add_window (window);

            if (saved_state.window_state == Settings.WindowState.MAXIMIZED)
                window.maximize ();
        }

        /**
         * Called when the remove button is selected.
         */
        void on_remove (E.CalComponent comp) {
            Model.CalendarModel.get_default ().remove_event (comp.get_data<E.Source> ("source"), comp, E.CalObjModType.THIS);
        }

        /**
         * Called when the edit button is selected.
         */
        void on_modified (E.CalComponent comp) {
            var dialog = new Maya.View.EventDialog (comp, null);
            dialog.transient_for = window;
            dialog.present ();
        }

        /** Returns true if the code parameter matches the keycode of the keyval parameter for
        * any keyboard group or level (in order to allow for non-QWERTY keyboards) **/
        protected bool match_keycode (int keyval, uint code) {
            Gdk.KeymapKey [] keys;
            Gdk.Keymap keymap = Gdk.Keymap.get_default ();
            if (keymap.get_entries_for_keyval (keyval, out keys)) {
                foreach (var key in keys) {
                    if (code == key.keycode)
                        return true;
                    }
                }

            return false;
        }

        /**
         * Creates the main window.
         */
        void create_window () {
            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/org/pantheon/maya");
            var saved_state = Settings.SavedState.get_default ();
            window = new Gtk.Window ();
            window.title = program_name;
            window.icon_name = "office-calendar";
            window.set_size_request (625, 400);
            window.default_width = saved_state.window_width;
            window.default_height = saved_state.window_height;
            window.window_position = Gtk.WindowPosition.CENTER;

            window.delete_event.connect (on_window_delete_event);
            window.destroy.connect (on_quit);
            window.key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.q, keycode) || match_keycode (Gdk.Key.w, keycode)) {
                        window.destroy ();
                    }
                }
                
                return false;
            });

            toolbar = new View.MayaToolbar ();
            toolbar.add_calendar_clicked.connect (() => on_tb_add_clicked (calview.selected_date));
            toolbar.on_menu_today_toggled.connect (on_menu_today_toggled);
            toolbar.on_search.connect ((text) => on_search (text));
            window.set_titlebar (toolbar);
        }
        
        void on_quit () {
            Model.CalendarModel.get_default ().delete_trashed_calendars ();
            Gtk.main_quit ();
        }

        void update_saved_state () {

            debug("Updating saved state");

            // Save window state
            var saved_state = Settings.SavedState.get_default ();
            if ((window.get_window ().get_state () & Settings.WindowState.MAXIMIZED) != 0)
                saved_state.window_state = Settings.WindowState.MAXIMIZED;
            else
                saved_state.window_state = Settings.WindowState.NORMAL;

            // Save window size
            if (saved_state.window_state == Settings.WindowState.NORMAL) {
                int width, height;
                window.get_size (out width, out height);
                saved_state.window_width = width;
                saved_state.window_height = height;
            }

            saved_state.hpaned_position = hpaned.position;
        }

        //--- SIGNAL HANDLERS ---//

        bool on_window_delete_event (Gdk.EventAny event) {
            update_saved_state ();
            return false;
        }

        void on_tb_add_clicked (DateTime dt) {
            var dialog = new Maya.View.EventDialog (null, dt);
            dialog.transient_for = window;
            dialog.show_all ();
        }

        /**
         * Called when the search_bar is used.
         */
        void on_search (string text) {
            sidebar.set_search_text (text);
        }

        void on_menu_today_toggled () {
            calview.today ();
        }

    }

}
