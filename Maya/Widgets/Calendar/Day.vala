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
using Cairo;
		
namespace Maya.Widgets {
				
	public class Day : Gtk.EventBox {
	
		private MayaWindow window;
	
		private VBox vbox;
	
		private Label label;
		public DateTime date { get; set; }
	 
		public Day (MayaWindow window) {
		
			this.window = window;
			
			vbox = new VBox (false, 0);
			label = new Label ("");
			
			// EventBox Properties
			can_focus = true;
			set_visible_window (true);
			events |= EventMask.BUTTON_PRESS_MASK;
			get_style_context ().add_provider (window.style_provider, 600);
			get_style_context ().add_class ("cell");
			
			label.halign = Align.END;
			label.get_style_context ().add_provider (window.style_provider, 600);
			label.name = "date";
			vbox.pack_start (label, false, false, 0);
			
			add (Utilities.set_margins (vbox, 3, 3, 3, 3));
			
			// Signals and handlers
			button_press_event.connect (on_button_press);
			focus_in_event.connect (on_focus_in);
			focus_out_event.connect (on_focus_out);
			
			notify["date"].connect (() => label.label = date.get_day_of_month ().to_string ());
		}
		
		private bool on_button_press (EventButton event) {
			grab_focus ();
			return true;
		}
		
		private bool on_focus_in (EventFocus event) {
			window.toolbar.add_button.sensitive = true;
			return false;
		}
		
		private bool on_focus_out (EventFocus event) {
			window.toolbar.add_button.sensitive = false;
			return false;
		}
		
	}
	
}

