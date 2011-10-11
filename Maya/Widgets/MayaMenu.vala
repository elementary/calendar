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
		public CheckMenuItem weeknumbers { get; private set; }

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
			fullscreen.active = (window.saved_state.window_state == MayaWindowState.FULLSCREEN);

			weeknumbers = new CheckMenuItem.with_label ("Show week numbers");
			weeknumbers.active = window.saved_state.show_weeks;

			sync = new MenuItem.with_label ("Sync...");

			// Append in correct order
			append (today);

			append (new SeparatorMenuItem ());

			append (import);
			append (export);

			append (new SeparatorMenuItem ());

			append (fullscreen);
			append (weeknumbers);

			append (new SeparatorMenuItem ());

			append (sync);

			// Callbacks
			today.activate.connect ( () => window.calendar_view.calendar.focus_today ());
			fullscreen.toggled.connect (toggle_fullscreen);
			weeknumbers.toggled.connect (toggle_weeknumbers);
		}

		private void toggle_fullscreen () {

			if (fullscreen.active)
				window.fullscreen ();
			else
				window.unfullscreen ();
		}

		private void toggle_weeknumbers () {

		    if (weeknumbers.active)
		        window.calendar_view.weeks.show ();
		    else
		        window.calendar_view.weeks.hide  ();
		}

	}

}

