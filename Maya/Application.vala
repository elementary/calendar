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

    namespace Option {

		private static bool ADD_EVENT = false;
    }

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

		public static const OptionEntry[] app_options = {
			{ "add-event", 'a', 0, OptionArg.NONE, out Option.ADD_EVENT, "Just show an add event dialog", null },
			{ null }
		};

		Settings.SavedState saved_state;
		Settings.MayaSettings prefs;

        Gtk.Window window;
		View.MayaToolbar toolbar;
		View.CalendarView calview;
		View.Sidebar sidebar;
        Gtk.HPaned hpaned;

        Model.SourceManager sourcemgr;
        Model.CalendarModel calmodel;
        View.SourceSelector source_selector;

		protected override void activate () {

			if (get_windows () != null) {
				get_windows ().data.present (); // present window if app is already running
			    return;
			}

			if (Option.ADD_EVENT) {
			    // TODO: NOT IMPLEMENTED
			} else {
                init_prefs ();
                init_models ();
                init_gui ();
			    window.show_all ();
			}
		}

        void init_prefs () {

			saved_state = new Settings.SavedState ();
			saved_state.changed["show-weeks"].connect (on_saved_state_show_weeks_changed);

			prefs = new Settings.MayaSettings ();
			prefs.changed["week-starts-on"].connect (on_prefs_week_starts_on_changed);
        }

        void init_models () {

            sourcemgr = new Model.SourceManager();

            calmodel = new Model.CalendarModel(sourcemgr, prefs.week_starts_on);

            calmodel.parameters_changed.connect (on_model_parameters_changed);
        }

        void init_gui () {

            window = new Gtk.Window ();
			window.title = "Maya";
			window.icon_name = "office-calendar";
			window.set_size_request (700, 400);
			window.default_width = saved_state.window_width;
			window.default_height = saved_state.window_height;
            window.delete_event.connect (on_window_delete_event);
            window.destroy.connect( () => Gtk.main_quit() );

            source_selector = new View.SourceSelector (window, sourcemgr);
            foreach (var group in sourcemgr.groups) {
                var tview = source_selector.get_group_box(group).tview;
                tview.r_enabled.toggled.connect ((path) => on_source_selector_toggled (group,path));
            }

			toolbar = new View.MayaToolbar (calmodel.month_start);
			toolbar.button_add.clicked.connect(on_tb_add_clicked);
			toolbar.button_calendar_sources.clicked.connect(on_tb_sources_clicked);
			toolbar.menu.today.activate.connect (on_menu_today_toggled);
			toolbar.menu.fullscreen.toggled.connect (on_toggle_fullscreen);
			toolbar.menu.weeknumbers.toggled.connect (on_menu_show_weeks_toggled);
			toolbar.menu.fullscreen.active = (saved_state.window_state == Settings.WindowState.FULLSCREEN);
			toolbar.menu.weeknumbers.active = saved_state.show_weeks;

			toolbar.month_switcher.left_clicked.connect (on_tb_month_switcher_left_clicked);
			toolbar.month_switcher.right_clicked.connect (on_tb_month_switcher_right_clicked);
			toolbar.year_switcher.left_clicked.connect (on_tb_year_switcher_left_clicked);
			toolbar.year_switcher.right_clicked.connect (on_tb_year_switcher_right_clicked);

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

        void edit_event (E.CalComponent event, bool add_event) {

		    View.EventDialog dialog;

            E.CalComponent event_clone = event.clone ();
            
            if (add_event)
                dialog = new View.AddEventDialog (window, sourcemgr, event_clone);
            else
                dialog = new View.EditEventDialog (window, sourcemgr, event_clone);

            dialog.response.connect ((response_id) => on_event_dialog_response(dialog, response_id, add_event));
		    dialog.present ();
        }

        //--- SIGNAL HANDLERS ---//

		void on_toggle_fullscreen () {

			if (toolbar.menu.fullscreen.active)
				window.fullscreen ();
			else
				window.unfullscreen ();
		}

        void on_event_dialog_response (View.EventDialog dialog, int response_id, bool add_event)  {

            E.CalComponent event = dialog.ecal;
            E.Source source = dialog.source;
            E.CalObjModType mod_type = dialog.mod_type;

            dialog.save ();
            dialog.dispose();

		    if (response_id != Gtk.ResponseType.APPLY)
                return;
            
            if (add_event)
                calmodel.add_event (source, event);
            else
                calmodel.update_event (source, event, mod_type);
        }

        void on_model_parameters_changed () {
            toolbar.set_switcher_date (calmodel.month_start);
        }

        void on_prefs_week_starts_on_changed () {
            calmodel.week_starts_on = prefs.week_starts_on;
        }

        void on_saved_state_show_weeks_changed () {
            calview.show_weeks = saved_state.show_weeks;
        }

        bool on_window_delete_event (Gdk.EventAny event) {
            update_saved_state();
            return false;
        }

        void on_tb_add_clicked () {
            
            var event = new E.CalComponent ();
			event.set_new_vtype (E.CalComponentVType.EVENT);

            edit_event (event, true);
        }

        void on_tb_sources_clicked (Gtk.Widget widget) {
            source_selector.move_to_widget (widget);
            source_selector.show_all ();
		    source_selector.run ();
            source_selector.hide ();
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

        void on_menu_today_toggled () {

            var today = new DateTime.now_local();

            if (calmodel.month_start.get_month() != today.get_month())
                calmodel.month_start = Util.get_start_of_month ();

            calview.today();
        }

        void on_menu_show_weeks_toggled () {
            saved_state.show_weeks = toolbar.menu.weeknumbers.active;
        }

        void on_source_selector_toggled (E.SourceGroup group, string path) {
            sourcemgr.toggle_source_status (group, path);
        }
	}

}

