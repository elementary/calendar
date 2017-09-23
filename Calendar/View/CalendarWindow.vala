/*-
 * Copyright (c) 2011-2017 elementary LLC (https://elementary.io)
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
 * Authored by: Maxwell Barvian
 */

using Gtk;
using Gdk;

using Granite.Widgets;
using Granite.Services;

using Calendar;

namespace Calendar.Widgets {

	public class CalendarWindow : Gtk.Window {
		
		public static CssProvider style_provider { get; private set; default = null; }
		
		public static SavedState saved_state { get; private set; default = null; }
		
		public static MayaSettings prefs { get; private set; default = null; }
		
		private VBox vbox;
		public MayaToolbar toolbar { get; private set; }
		public HPaned hpaned { get; private set; }
		public CalendarView calendar_view { get; private set; }
		public Sidebar sidebar { get; private set; }
		
		public static Granite.Application app { get; private set; }
		
		public CalendarWindow (Granite.Application app) {
			
			this.app = app;
			
			// Set up global css provider
			style_provider = new CssProvider ();
			try {
				style_provider.load_from_path (Build.PKGDATADIR + "/style/default.css");
			} catch (Error e) {
				warning ("Could not add css provider. Some widgets will not look as intended. %s", e.message);
			}
			
			// Set up settings
			saved_state = new SavedState ();
			prefs = new MayaSettings ();
			
			vbox = new VBox (false, 0);
			toolbar = new MayaToolbar (this);
			hpaned = new HPaned ();
			calendar_view = new CalendarView (this);
			sidebar = new Sidebar (this);
			
			// Window Properties
			title = "Maya";
			icon_name = "office-calendar";
			set_size_request (700, 400);
			
			restore_saved_state ();
			
			// Initialize layout
			vbox.pack_start (toolbar, false, false, 0);
			vbox.pack_end (hpaned);

			hpaned.add (calendar_view);
			hpaned.add (sidebar);
			
			add (vbox);
			
			// Signals and callbacks
			destroy.connect (Gtk.main_quit);
		}
		
		protected override bool delete_event (EventAny event) {
			update_saved_state ();
			return false;
		}
		
		private void restore_saved_state () {
			
			// Restore window state
			default_width = saved_state.window_width;
			default_height = saved_state.window_height;
			
			if (saved_state.window_state == CalendarWindowState.MAXIMIZED)
				maximize ();
			else if (saved_state.window_state == CalendarWindowState.FULLSCREEN)
				fullscreen ();
			
			hpaned.position = saved_state.hpaned_position;
		}
		
		private void update_saved_state () {
			
			// Save window state
			if ((get_window ().get_state () & WindowState.MAXIMIZED) != 0)
				saved_state.window_state = CalendarWindowState.MAXIMIZED;
			else if ((get_window ().get_state () & WindowState.FULLSCREEN) != 0)
				saved_state.window_state = CalendarWindowState.FULLSCREEN;
			else
				saved_state.window_state = CalendarWindowState.NORMAL;
			
			// Save window size
			if (saved_state.window_state == CalendarWindowState.NORMAL) {
				int width, height;
				get_size (out width, out height);
				saved_state.window_width = width;
				saved_state.window_height = height;
			}
			
			saved_state.hpaned_position = hpaned.position;
		}
		
	}
	
}

