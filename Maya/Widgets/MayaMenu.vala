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

using Granite;
using Granite.Services;

using Maya;
using Maya.Dialogs;

namespace Maya.Widgets {

	public class MayaMenu : Gtk.Menu {
	
		private MayaWindow window;
	
		public MenuItem today { get; private set; }
		
		public MenuItem import { get; private set; }
		public MenuItem export { get; private set; }
		
		public CheckMenuItem fullscreen { get; private set; }
		
		public MenuItem sync { get; private set; }

		public MayaMenu (MayaWindow window) {
		
			this.window = window;
		
			// Create everything
			today = new MenuItem.with_label ("Today");
			
			import = new MenuItem.with_label ("Import...");

			var export_submenu = new Menu ();
			var outlook = new MenuItem.with_label ("To Outlook (.csv)");
			var ical = new MenuItem.with_label ("To iCal (.ics)");
			export_submenu.append (outlook);
			export_submenu.append (ical);
			export = new MenuItem.with_label ("Export...");
			export.set_submenu (export_submenu);
			
			fullscreen = new CheckMenuItem.with_label ("Fullscreen");
			fullscreen.active = Maya.saved_state.get_enum ("window-state") == 2;
			
			sync = new MenuItem.with_label ("Sync...");
			
			var help = new MenuItem.with_label( "Get Help Online...");
			var translate = new MenuItem.with_label ("Translate This Application...");
			var report = new MenuItem.with_label ("Report a Problem...");
			
			var about = new MenuItem.with_label ("About");
			
			// Append in correct order
			append (today);
			
			append (new SeparatorMenuItem ());
			
			append (import);
			append (export);
			
			append (new SeparatorMenuItem ());
			
			append (fullscreen);
			
			append (new SeparatorMenuItem ());
			
			append (sync);
			
			append (new SeparatorMenuItem ());
			
			append (help);
			append (translate);
			append (report);
			
			append (new SeparatorMenuItem ());
			
			append (about);
						
			// Callbacks
			today.activate.connect ( () => window.calendar_view.calendar.focus_today ());
			fullscreen.toggled.connect (toggle_fullscreen);			
			about.activate.connect ( () => AppFactory.app.show_about ());
			
			help.activate.connect ( () => System.open_uri ("https://answers.launchpad.net/maya"));
			translate.activate.connect ( () => System.open_uri ("https://translations.launchpad.net/maya"));
			report.activate.connect ( () => System.open_uri ("https://bugs.launchpad.net/maya"));
		}
		
		private void toggle_fullscreen () {
		
			if (fullscreen.active)
				window.fullscreen ();
			else
				window.unfullscreen ();
		}
	
	}

}
