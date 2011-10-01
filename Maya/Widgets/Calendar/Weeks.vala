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

using Gtk;
using Cairo;

using Maya.Services;

namespace Maya.Widgets {

	public class Weeks : Gtk.EventBox {
	
		private MayaWindow window;
	
		private Table table;
		private Label[] labels;
		
		private DateHandler handler;
	
		public Weeks (MayaWindow window, DateHandler handler) {
			
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
				labels[c].draw.connect (on_draw);
				table.attach_defaults (labels[c], 0, 1, c, c + 1);
			}
			update ();
			
			add (Utilities.set_margins (table, 20, 0, 0, 0));
			
			// Signals and handlers
			window.prefs.changed["show-weeks"].connect (update);
			handler.changed.connect(update);
		}
		
		~Header () {
			window.prefs.changed["show-weeks"].disconnect (update);
		}
		
		private void update () {
		
			if (window.prefs.show_weeks) {
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
		
		private bool on_draw (Widget widget, Context cr) {
		
			Allocation size;
			widget.get_allocation (out size);
			
			// Draw left border
			cr.move_to (0.5, size.height); // start in bottom left. 0.5 accounts for cairo's default stroke offset of 1/2 pixels
			cr.line_to (0.5, 0.5); // move to upper left corner
			
			cr.set_source_rgba (0.0, 0.0, 0.0, 0.25);
			cr.set_line_width (1.0);
			cr.set_antialias (Antialias.NONE);
			cr.stroke ();
			
			return false;
		}
		
	}

}

