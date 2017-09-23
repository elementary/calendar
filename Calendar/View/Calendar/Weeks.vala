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
 * Authored by: Maxwell Barvian, Jaap Broekhuizen
 */

using Gtk;
using Cairo;

using Calendar.Services;

namespace Calendar.Widgets {

	public class Weeks : Gtk.EventBox {

		private CalendarWindow window;

		private Table table;
		private Label[] labels;

		private DateHandler handler;

		public Weeks (CalendarWindow window, DateHandler handler) {

			this.window = window;
			this.handler = handler;

			table = new Table (1, 6, false);
			table.row_spacing = 1;

			// EventBox properties
			set_visible_window (true); // needed for style
			get_style_context ().add_provider (window.style_provider, 600);
			get_style_context ().add_class ("weeks");

			labels = new Label[table.n_columns];
			for (int c = 0; c < table.n_columns; c++) {
				labels[c] = new Label ("");
				labels[c].valign = Align.START;
				table.attach_defaults (labels[c], 0, 1, c, c + 1);
			}
			update ();

			add (Utilities.set_margins (table, 20, 0, 0, 0));

			// Signals and handlers
			window.saved_state.changed["show-weeks"].connect (update);
			handler.changed.connect(update);
		}

		~Weeks () {
			window.saved_state.changed["show-weeks"].disconnect (update);
		}

		private void update () {

			if (window.saved_state.show_weeks) {
			    if (!visible)
			        show ();

			    var date = handler.date;
		    	foreach (var label in labels) {
		    		label.label = date.get_week_of_year ().to_string();
		    		date = date.add_weeks (1);
		    	}
		    } else {
		        hide ();
		    }
		}

	}

}

