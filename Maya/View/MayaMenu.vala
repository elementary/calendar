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

namespace Maya.View {

	public class MayaMenu : Gtk.Menu {

		public Gtk.MenuItem today { get; private set; }

		public Gtk.MenuItem import { get; private set; }
		public Gtk.MenuItem export { get; private set; }

		public Gtk.CheckMenuItem fullscreen { get; private set; }
		public Gtk.CheckMenuItem weeknumbers { get; private set; }

		public Gtk.MenuItem sync { get; private set; }

		public MayaMenu () {

			// Create everything
			today = new Gtk.MenuItem.with_label ("Today");

			import = new Gtk.MenuItem.with_label ("Import...");

			var export_submenu = new Gtk.Menu ();
			var outlook = new Gtk.MenuItem.with_label ("To Outlook (.csv)");
			var ical = new Gtk.MenuItem.with_label ("To iCal (.ics)");
			export_submenu.append (outlook);
			export_submenu.append (ical);
			export = new Gtk.MenuItem.with_label ("Export...");
			export.set_submenu (export_submenu);

			fullscreen = new Gtk.CheckMenuItem.with_label ("Fullscreen");

			weeknumbers = new Gtk.CheckMenuItem.with_label ("Show Week Numbers");

			sync = new Gtk.MenuItem.with_label ("Sync...");

			// Append in correct order
			append (today);

			append (new Gtk.SeparatorMenuItem ());

			append (import);
			append (export);

			append (new Gtk.SeparatorMenuItem ());

			append (fullscreen);
			append (weeknumbers);

			append (new Gtk.SeparatorMenuItem ());

			append (sync);
		}

	}

}

