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

using Gtk;
using Gdk;

using Granite.Widgets;
using Granite.Services;

using Maya;

namespace Maya.Widgets {

	public class MayaWindow : Gtk.Window {
	
		private VBox vbox;
		public MayaToolbar toolbar { get; private set; }
		public HPaned hpaned { get; private set; }
		public CalendarView calendar_view { get; private set; }
		public Sidebar sidebar { get; private set; }
		
		public MayaWindow () {
			
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
		
		protected override bool delete_event (Event event) {
			update_saved_state ();
			return false;
		}
		
		private void restore_saved_state () {
			
			// Restore window state
			default_width = Maya.saved_state.get_int ("window-width");
			default_height = Maya.saved_state.get_int ("window-height");
			
			if (Maya.saved_state.get_enum ("window-state") == 1)
				maximize ();
			else if (Maya.saved_state.get_enum ("window-state") == 2)
				fullscreen ();
			
			hpaned.position = Maya.saved_state.get_int ("hpaned-position");
		}
		
		private void update_saved_state () {
			
			// Save window state
			if ((get_window ().get_state () & WindowState.MAXIMIZED) != 0)
				Maya.saved_state.set_enum ("window-state", 1);
			else if ((get_window ().get_state () & WindowState.FULLSCREEN) != 0)
				Maya.saved_state.set_enum ("window-state", 2);
			else
				Maya.saved_state.set_enum ("window-state", 0);
			
			// Save window size
			if (Maya.saved_state.get_enum ("window-state") == 0) {
				int width, height;
				get_size (out width, out height);
				Maya.saved_state.set_int ("window-width", width);
				Maya.saved_state.set_int ("window-height", height);
			}
			
			Maya.saved_state.set_int ("hpaned-position", hpaned.position);
		}
		
	}
	
}

