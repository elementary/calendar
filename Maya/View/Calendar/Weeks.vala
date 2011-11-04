//
//  Copyright (C) 2011 Maxwell Barvian, Jaap Broekhuizen
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

namespace Maya.View.Calendar {

	public class Weeks : Gtk.EventBox {

		private Gtk.Table table;
		private Gtk.Label[] labels;

		public Weeks (Gtk.CssProvider style_provider) {

			table = new Gtk.Table (1, 6, false);
			table.row_spacing = 1;

			// EventBox properties
			set_visible_window (true); // needed for style
			get_style_context ().add_provider (style_provider, 600);
			get_style_context ().add_class ("weeks");

			labels = new Gtk.Label[table.n_columns];
			for (int c = 0; c < table.n_columns; c++) {
				labels[c] = new Gtk.Label ("");
				labels[c].valign = Gtk.Align.START;
				table.attach_defaults (labels[c], 0, 1, c, c + 1);
			}

			add (Utilities.set_margins (table, 20, 0, 0, 0));
		}

		public void update (DateTime date, bool show_weeks) {

			if (show_weeks) {
			    if (!visible)
			        show ();

			    var next = date;
		    	foreach (var label in labels) {
		    		label.label = next.get_week_of_year ().to_string();
		    		next = next.add_weeks (1);
		    	}
		    } else {
		        hide ();
		    }
		}

	}

}

