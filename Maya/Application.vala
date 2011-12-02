//
//  Copyright (C) 2011 Maxwell Barvian
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

    public static int main (string[] args) {

        var context = new OptionContext("Calendar");
        context.add_main_entries(Application.app_options, "maya");
        context.add_group(Gtk.get_option_group(true));

        try {
            context.parse(ref args);
        } catch(Error e) {
            print(e.message + "\n");
        }

        Gtk.init(ref args);

        return new Application ().run (args);
    }

	public class Application : Granite.Application {

		construct {

			// App info
			build_data_dir = Build.DATADIR;
			build_pkg_data_dir = Build.PKGDATADIR;
			build_release_name = Build.RELEASE_NAME;
			build_version = Build.VERSION;
			build_version_info = Build.VERSION_INFO;

			program_name = "Maya";
			exec_name = "maya";

			app_years = "2011";
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
				"Allen Lowe <lallenlowe@gmail.com>"
			};
			about_documenters = {
				"Maxwell Barvian <maxwell@elementaryos.org>"
			};
			about_artists = {
				"Daniel Foré <bunny@go-docky.com>"
			};
			about_translators = "";
            about_license_type = Gtk.License.GPL_3_0;
		}

		private static bool APP_OPTION_ADD = false;

		public static const OptionEntry[] app_options = {
			{ "add-event", 'a', 0, OptionArg.NONE, out APP_OPTION_ADD, "Just show an add event dialog", null },
			{ null }
		};

		Settings.SavedState saved_state;
		Settings.MayaSettings prefs;

        Gtk.Window window;
		View.MayaToolbar toolbar;
		View.CalendarView calview;
		View.Sidebar sidebar;
        Gtk.HPaned hpaned;

        Model.SourceSelectionModel source_selection_model;
        Model.CalendarModel calmodel;
        View.SourceSelector source_selector_view;

		protected override void activate () {

			if (get_windows () != null) {
				get_windows ().data.present (); // present window if app is already running
			    return;
			}

			if (APP_OPTION_ADD) {
			    (new View.AddEventDialog.without_parent (this)).show_all ();
			} else {
                initialise();
			    window.show_all ();
			}
		}

        private void initialise() {

			saved_state = new Settings.SavedState ();
			prefs = new Settings.MayaSettings ();

            window = new Gtk.Window ();
			window.title = "Maya";
			window.icon_name = "office-calendar";
			window.set_size_request (700, 400);
			window.default_width = saved_state.window_width;
			window.default_height = saved_state.window_height;
            window.delete_event.connect (window_delete_event_cb);
            window.destroy.connect( () => Gtk.main_quit() );

            source_selection_model = new Model.SourceSelectionModel();

            var enabled_sources = source_selection_model.enabled_sources;
            calmodel = new Model.CalendarModel(enabled_sources, prefs.week_starts_on);

            source_selector_view = new View.SourceSelector (window, source_selection_model);
            foreach (var group in source_selection_model.groups) {
                var tview = source_selector_view.group_box.get(group).tview;
                tview.r_enabled.toggled.connect ((path) => {source_selector_toggled(group,path);} );
            }

			toolbar = new View.MayaToolbar (calmodel.month_start);
			toolbar.button_add.clicked.connect(toolbar_add_clicked);
			toolbar.button_calendar_sources.clicked.connect(toolbar_sources_clicked);
			toolbar.menu.today.activate.connect (menu_today_toggled);
			toolbar.menu.fullscreen.toggled.connect (toggle_fullscreen);
			toolbar.menu.weeknumbers.toggled.connect (menu_show_weeks_toggled);
			toolbar.menu.fullscreen.active = (saved_state.window_state == Settings.WindowState.FULLSCREEN);
			toolbar.menu.weeknumbers.active = saved_state.show_weeks;

			toolbar.month_switcher.left_clicked.connect (toolbar_month_switcher_left_clicked);
			toolbar.month_switcher.right_clicked.connect (toolbar_month_switcher_right_clicked);
			toolbar.year_switcher.left_clicked.connect (toolbar_year_switcher_left_clicked);
			toolbar.year_switcher.right_clicked.connect (toolbar_year_switcher_right_clicked);

			calview = new View.CalendarView (calmodel, saved_state.show_weeks);
            calview.today();

			sidebar = new View.Sidebar ();

			var vbox = new Gtk.VBox (false, 0);
			hpaned = new Gtk.HPaned ();
			vbox.pack_start (toolbar, false, false, 0);
			vbox.pack_end (hpaned);
			hpaned.add (calview);
			hpaned.add (sidebar);
			hpaned.position = saved_state.hpaned_position;
			window.add (vbox);

            add_window(window);

			saved_state.changed["show-weeks"].connect (saved_state_show_weeks_changed);
			prefs.changed["week-starts-on"].connect (prefs_week_starts_on_changed);

            calmodel.source_loaded.connect (calview.on_source_loaded);
            calmodel.parameters_changed.connect (on_model_parameters_changed);

			if (saved_state.window_state == Settings.WindowState.MAXIMIZED)
				window.maximize ();
			else if (saved_state.window_state == Settings.WindowState.FULLSCREEN)
				window.fullscreen ();
        }

		void update_saved_state () {

            debug("Updating saved state");

			// Save window state
			if ((window.get_window().get_state() & Settings.WindowState.MAXIMIZED) != 0)
				saved_state.window_state = Settings.WindowState.MAXIMIZED;
			else if ((window.get_window().get_state() & Settings.WindowState.FULLSCREEN) != 0)
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

		private void toggle_fullscreen () {

			if (toolbar.menu.fullscreen.active)
				window.fullscreen ();
			else
				window.unfullscreen ();
		}

        //--- SIGNAL HANDLERS ---//

        void on_model_parameters_changed () {
            toolbar.set_switcher_date (calmodel.month_start);
        }

        void prefs_week_starts_on_changed () {
            calmodel.week_starts_on = prefs.week_starts_on;
        }

        void saved_state_show_weeks_changed () {
            calview.show_weeks = saved_state.show_weeks;
        }

        bool window_delete_event_cb (Gdk.EventAny event) {
            update_saved_state();
            return false;
        }

        void toolbar_add_clicked () {
		    var add_dialog = new View.AddEventDialog (window);
		    add_dialog.present ();
        }

        void toolbar_sources_clicked () {
		    source_selector_view.show_all();
        }

        void toolbar_month_switcher_left_clicked () {
            calmodel.month_start = calmodel.month_start.add_months (-1);
        }

        void toolbar_month_switcher_right_clicked () {
            calmodel.month_start = calmodel.month_start.add_months (1);
        }

        void toolbar_year_switcher_left_clicked () {
            calmodel.month_start = calmodel.month_start.add_years (-1);
        }

        void toolbar_year_switcher_right_clicked () {
            calmodel.month_start = calmodel.month_start.add_years (1);
        }

        void menu_today_toggled () {

            var today = new DateTime.now_local();

            if (calmodel.month_start.get_month() != today.get_month())
                calmodel.month_start = get_start_of_month ();

            calview.today();
        }

        void menu_show_weeks_toggled () {
            saved_state.show_weeks = toolbar.menu.weeknumbers.active;
        }

        void source_selector_toggled (E.SourceGroup group, string path) {
            source_selection_model.toggle_source_status (group, path);
        }
	}

}

