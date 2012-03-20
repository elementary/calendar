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

        public Gtk.MenuItem about { get; private set; }

		public MayaMenu () {

			// Create everything
			today = new Gtk.MenuItem.with_label (_("Today"));

			fullscreen = new Gtk.CheckMenuItem.with_label (_("Fullscreen"));

			weeknumbers = new Gtk.CheckMenuItem.with_label (_("Show Week Numbers"));

			import = new Gtk.MenuItem.with_label (_("Import..."));

			sync = new Gtk.MenuItem.with_label (_("Sync..."));

            about = new Gtk.MenuItem.with_label (_("About"));

			// Append in correct order
			append (today);

			append (new Gtk.SeparatorMenuItem ());

			append (fullscreen);
			append (weeknumbers);

            /*
            * TODO : Will be done in Maya 0.2
			append (new Gtk.SeparatorMenuItem ());

			append (import);
			append (sync);
            */

			append (new Gtk.SeparatorMenuItem ());

            append (about);
		}

	}

}

