//
//  Copyright (C) 2011-2012 Maxwell Barvian
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Maya {

    namespace Option {

        private static bool ADD_EVENT = false;
        private static bool IMPORT_CALENDAR = false;
        private static bool PRINT_VERSION = false;

    }

    public static int main (string[] args) {

        var context = new OptionContext ("Calendar");
        context.add_main_entries (Application.app_options, "maya");
        context.add_group (Gtk.get_option_group(true));

        try {
            context.parse (ref args);
        } catch (Error e) {
            warning (e.message);
        }

        if (Option.PRINT_VERSION) {
            stdout.printf("Maya %s\n", Build.VERSION);
            stdout.printf("Copyright 2011-2012 Maya Developers.\n");
            return 0;
        }

        Gtk.init (ref args);

        return new Application ().run (args);

    }

    /**
     * Main application class.
     */
    public class Application : Granite.Application {

        /**
         * Initializes environment variables
         */
        construct {

            // App info
            build_data_dir = Build.DATADIR;
            build_pkg_data_dir = Build.PKGDATADIR;
            build_release_name = Build.RELEASE_NAME;
            build_version = Build.VERSION;
            build_version_info = Build.VERSION_INFO;

            program_name = "Maya";
            exec_name = "maya";

            app_years = "2011-2012";
            application_id = "net.launchpad.maya";
            app_icon = "office-calendar";
            app_launcher = "maya.desktop";

            main_url = "https://launchpad.net/maya";
            bug_url = "https://bugs.launchpad.net/maya";
            help_url = "https://answers.launchpad.net/maya";
            translate_url = "https://translations.launchpad.net/maya";

            about_authors = {
                "Maxwell Barvian <maxwell@elementaryos.org>",
                "Jaap Broekhuizen <jaapz.b@gmail.com>",
                "Avi Romanoff <aviromanoff@gmail.com>",
                "Allen Lowe <lallenlowe@gmail.com>",
                "Niels Avonds <niels.avonds@gmail.com>",
                "Corentin Noël <tintou@mailoo.org>"
            };
            about_documenters = {
                "Maxwell Barvian <maxwell@elementaryos.org>"
            };
            about_artists = {
                "Daniel Foré <bunny@go-docky.com>"
            };
            about_translators = "Launchpad Translators";
            about_license_type = Gtk.License.GPL_3_0;
        }

        public static const OptionEntry[] app_options = {
            { "add-event", 'a', 0, OptionArg.NONE, out Option.ADD_EVENT, "Show an add event dialog", null },
            { "import-ical", 'i', 0, OptionArg.STRING, out Option.IMPORT_CALENDAR, "Import quickly an ical", null },
            { "version", 'v', 0, OptionArg.NONE, out Option.PRINT_VERSION, "Print version info and exit", null },
            { null }
        };

        Settings.SavedState saved_state;

        Gtk.Window window;
        View.MayaToolbar toolbar;
        View.CalendarView calview;
        View.Sidebar sidebar;
        Gtk.Paned hpaned;

        Model.SourceManager sourcemgr;
        Model.CalendarModel calmodel;
        View.SourceSelector source_selector;

        E.CalComponent sidebar_selected_event = null;

        /**
         * Called when the application is activated.
         */
        protected override void activate () {
            if (get_windows () != null) {
                get_windows ().data.present (); // present window if app is already running
                return;
            }

            init_prefs ();
            init_models ();
            init_gui ();
            window.show_all ();

            if (Option.ADD_EVENT) {
                on_tb_add_clicked (calview.grid.selected_date);
            }

            Gtk.main ();
        }

        /**
         * Initializes the preferences
         */
        void init_prefs () {

            saved_state = new Settings.SavedState ();
            saved_state.changed["show-weeks"].connect (on_saved_state_show_weeks_changed);

        }

        /**
         * Initializes the calendar model
         */
        void init_models () {

            sourcemgr = new Model.SourceManager ();

            // It's dirty, but there is no other way to get it for the moment.
            string output;
            Maya.Settings.Weekday week_starts_on = Maya.Settings.Weekday.MONDAY;

            try {
                GLib.Process.spawn_command_line_sync ("locale first_weekday", out output, null, null);
            } catch (SpawnError e) {
                output = "";
            }

            switch (output) {
            case "1\n":
                week_starts_on = Maya.Settings.Weekday.SUNDAY;
                break;
            case "2\n":
                week_starts_on = Maya.Settings.Weekday.MONDAY;
                break;
            case "3\n":
                week_starts_on = Maya.Settings.Weekday.TUESDAY;
                break;
            case "4\n":
                week_starts_on = Maya.Settings.Weekday.WEDNESDAY;
                break;
            case "5\n":
                week_starts_on = Maya.Settings.Weekday.THURSDAY;
                break;
            case "6\n":
                week_starts_on = Maya.Settings.Weekday.FRIDAY;
                break;
            case "7\n":
                week_starts_on = Maya.Settings.Weekday.SATURDAY;
                break;
            default:
                week_starts_on = Maya.Settings.Weekday.BAD_WEEKDAY;
                stdout.printf ("Locale has a bad first_weekday value\n");
                break;
            }

            calmodel = new Model.CalendarModel (sourcemgr, week_starts_on);

            calmodel.parameters_changed.connect (on_model_parameters_changed);
        }

        /**
         * Initializes the graphical window and its components
         */
        void init_gui () {

            create_window ();

            create_toolbar ();

            calview = new View.CalendarView (calmodel, saved_state.show_weeks);
            calview.on_event_add.connect ((date) => on_tb_add_clicked (date));

            sidebar = new View.Sidebar (sourcemgr, calmodel);
            // Don't automatically display all the widgets on the sidebar
            sidebar.no_show_all = true;
            sidebar.show ();
            sidebar.event_selected.connect ((event) => (on_sidebar_selected (event)));
            sidebar.event_deselected.connect ((event) => (on_sidebar_deselected (event)));
            sidebar.event_removed.connect (on_remove);
            sidebar.event_modified.connect (on_modified);
            sidebar.agenda_view.shown_changed.connect (on_agenda_view_shown_changed);
            sidebar.set_size_request(200,0);

            calview.grid.selection_changed.connect ((date) => sidebar.set_selected_date (date));

            calmodel.load_all_sources ();

            var gridcontainer = new Gtk.Grid ();
            hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            calview.set_vexpand(true);
            hpaned.pack1 (calview, true, false);
            hpaned.pack2 (sidebar, true, false);
            hpaned.position = saved_state.hpaned_position;
            gridcontainer.attach (toolbar, 0, 0, 1, 1);
            gridcontainer.attach (hpaned, 0, 1, 1, 1);
            window.add (gridcontainer);

            add_window(window);

            if (saved_state.window_state == Settings.WindowState.MAXIMIZED)
                window.maximize ();
            else if (saved_state.window_state == Settings.WindowState.FULLSCREEN)
                window.fullscreen ();

            calview.today();

        }

        void on_agenda_view_shown_changed (bool old, bool shown) {
            toolbar.search_bar.sensitive = shown;
        }

        /**
         * Called when an event is selected in the sidebar.
         */
        void on_sidebar_selected (E.CalComponent event) {
            sidebar_selected_event = event;

            toolbar.edit_button.sensitive = true;
            toolbar.delete_button.sensitive = true;
        }

        /**
         * Called when an event is deselected in the sidebar.
         */
        void on_sidebar_deselected (E.CalComponent event) {
            sidebar_selected_event = null;

            toolbar.edit_button.sensitive = false;
            toolbar.delete_button.sensitive = false;
        }

        /**
         * Called when the remove button is selected.
         */
        void on_remove (E.CalComponent comp) {
            calmodel.remove_event (comp.get_data<E.Source>("source"), comp, E.CalObjModType.THIS);
        }

        /**
         * Called when the edit button is selected.
         */
        void on_modified (E.CalComponent comp) {
            var dialog = new Maya.View.EventDialog (window, sourcemgr, comp, comp.get_data<E.Source>("source"), false);
            dialog.response.connect ((response_id) => on_event_dialog_response(dialog, response_id, false));
            dialog.present ();
        }

        /**
         * Creates the main window.
         */
        void create_window () {
            window = new Gtk.Window ();
            window.title = "Maya";
            window.icon_name = "office-calendar";
            window.set_size_request (700, 400);
            window.default_width = saved_state.window_width;
            window.default_height = saved_state.window_height;

            window.delete_event.connect (on_window_delete_event);
            window.destroy.connect (() => Gtk.main_quit ());
            window.key_press_event.connect ((e) => {
                    switch (e.keyval) {
                        case Gdk.Key.@q:
                        case Gdk.Key.@w:
                            if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                                window.destroy ();
                            }

                            break;
                        case Gdk.Key.@F11:
                            toolbar.menu.fullscreen.active = !toolbar.menu.fullscreen.active;
                            break;
                        }

                        return false;
            });
        }

        /**
         * Creates the toolbar and its elements.
         */
        void create_toolbar () {
            toolbar = new View.MayaToolbar (calmodel.month_start);
            toolbar.button_add.clicked.connect (() => on_tb_add_clicked (calview.grid.selected_date));
            toolbar.edit_button.clicked.connect (() => on_modified (sidebar_selected_event));
            toolbar.delete_button.clicked.connect (() => on_remove (sidebar_selected_event));
            toolbar.button_calendar_sources.clicked.connect (on_tb_sources_clicked);
            toolbar.menu.today.activate.connect (on_menu_today_toggled);
            toolbar.menu.fullscreen.toggled.connect (on_toggle_fullscreen);
            toolbar.menu.weeknumbers.toggled.connect (on_menu_show_weeks_toggled);
            toolbar.menu.fullscreen.active = (saved_state.window_state == Settings.WindowState.FULLSCREEN);
            toolbar.menu.about.activate.connect (() => show_about(window));
            toolbar.menu.weeknumbers.active = saved_state.show_weeks;
            toolbar.search_bar.text_changed_pause.connect ((text) => on_search (text));

            toolbar.month_switcher.left_clicked.connect (on_tb_month_switcher_left_clicked);
            toolbar.month_switcher.right_clicked.connect (on_tb_month_switcher_right_clicked);
            toolbar.year_switcher.left_clicked.connect (on_tb_year_switcher_left_clicked);
            toolbar.year_switcher.right_clicked.connect (on_tb_year_switcher_right_clicked);
        }

        void update_saved_state () {

            debug("Updating saved state");

            // Save window state
            if ((window.get_window ().get_state () & Settings.WindowState.MAXIMIZED) != 0)
                saved_state.window_state = Settings.WindowState.MAXIMIZED;
            else if ((window.get_window ().get_state () & Settings.WindowState.FULLSCREEN) != 0)
                saved_state.window_state = Settings.WindowState.FULLSCREEN;
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

        void on_toggle_fullscreen () {

            if (toolbar.menu.fullscreen.active)
                window.fullscreen ();
            else
                window.unfullscreen ();
        }

        void on_event_dialog_response (View.EventDialog dialog, bool response_id, bool add_event)  {

            E.CalComponent event = dialog.ecal;
            E.Source source = dialog.source;
            E.Source? original_source = dialog.original_source;
            E.CalObjModType mod_type = dialog.mod_type;

            dialog.dispose ();

            if (response_id != true)
                return;

            if (add_event)
                calmodel.add_event (source, event);
            else {

                assert(original_source != null);

                if (original_source.peek_uid () == source.peek_uid ()) {
                    // Same uids, just modify
                    calmodel.update_event (source, event, mod_type);
                } else {
                    // Different calendar, remove and readd
                    calmodel.remove_event (original_source, event, mod_type);
                    calmodel.add_event (source, event);
                }
            }
        }

        void on_model_parameters_changed () {
            toolbar.set_switcher_date (calmodel.month_start);
        }

        void on_saved_state_show_weeks_changed () {
            if (calview != null)
                calview.show_weeks = saved_state.show_weeks;
        }

        bool on_window_delete_event (Gdk.EventAny event) {
            update_saved_state ();
            return false;
        }

        void on_tb_add_clicked (DateTime dt) {
            var event = new E.CalComponent ();
            event.set_new_vtype (E.CalComponentVType.EVENT);

            iCal.icaltimetype date = iCal.icaltime_from_day_of_year (dt.get_day_of_year()+1, dt.get_year());
            unowned iCal.icalcomponent comp = event.get_icalcomponent ();

            comp.set_dtstart (date);
            comp.set_dtend (date);
            comp.set_summary ("");

            var dialog = new Maya.View.EventDialog (window, sourcemgr, event, null, true);
            dialog.response.connect ((response_id) => on_event_dialog_response(dialog, response_id, true));
            dialog.present ();

        }

        void on_tb_sources_clicked (Gtk.Widget widget) {
            source_selector = new View.SourceSelector (window, sourcemgr);
            foreach (var group in sourcemgr.groups) {
                var tview = source_selector.get_group_box(group).tview;
                tview.r_enabled.toggled.connect ((path) => on_source_selector_toggled (group,path));
            }
            source_selector.move_to_widget (widget);
            source_selector.show_all ();
            source_selector.run ();
            source_selector.destroy ();
        }

        void on_tb_month_switcher_left_clicked () {
            calmodel.month_start = calmodel.month_start.add_months (-1);
        }

        void on_tb_month_switcher_right_clicked () {
            calmodel.month_start = calmodel.month_start.add_months (1);
        }

        void on_tb_year_switcher_left_clicked () {
            calmodel.month_start = calmodel.month_start.add_years (-1);
        }

        void on_tb_year_switcher_right_clicked () {
            calmodel.month_start = calmodel.month_start.add_years (1);
        }

        /**
         * Called when the search_bar is used.
         */
        void on_search (string text) {
            sidebar.set_search_text (text);
        }

        void on_menu_today_toggled () {

            var today = new DateTime.now_local ();

            if (calmodel.month_start.get_month () != today.get_month ())
                calmodel.month_start = Util.get_start_of_month ();

            calview.today ();
        }

        void on_menu_show_weeks_toggled () {
            saved_state.show_weeks = toolbar.menu.weeknumbers.active;
        }

        void on_source_selector_toggled (E.SourceGroup group, string path) {
            sourcemgr.toggle_source_status (group, path);
        }

    }

    internal void desktop_translations () {
        // maya.desktop:6
        var comment = _("View and schedule events");
        // maya.desktop:5
        var generic_name = _("Calendar");
        // maya.desktop:18
        var add_event = _("_Add Event");
    }

}
