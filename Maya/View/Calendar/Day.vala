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

namespace Maya.View.Calendar {

	public class Day : Gtk.EventBox {

		private Gtk.Label label;
		private Gtk.VBox vbox;

		public Day (Gtk.CssProvider style_provider) {

			vbox = new Gtk.VBox (false, 0);
			label = new Gtk.Label ("");

			// EventBox Properties
			can_focus = true;
			set_visible_window (true);
			events |= Gdk.EventMask.BUTTON_PRESS_MASK;
			get_style_context ().add_provider (style_provider, 600);
			get_style_context ().add_class ("cell");

			label.halign = Gtk.Align.END;
			label.get_style_context ().add_provider (style_provider, 600);
			label.name = "date";
			vbox.pack_start (label, false, false, 0);

			add (Utilities.set_margins (vbox, 3, 3, 3, 3));

			// Signals and handlers
			button_press_event.connect (on_button_press);
			draw.connect (on_draw);
		}

        public void update_date (DateTime date) {

            label.label = date.get_day_of_month ().to_string ();
        }

		private bool on_button_press (Gdk.EventButton event) {

			grab_focus ();
			return true;
		}

		private bool on_draw (Gtk.Widget widget, Cairo.Context cr) {

			Gtk.Allocation size;
			widget.get_allocation (out size);

			// Draw left and top black strokes
			cr.move_to (0.5, size.height); // start in bottom left. 0.5 accounts for cairo's default stroke offset of 1/2 pixels
			cr.line_to (0.5, 0.5); // move to upper left corner
			cr.line_to (size.width + 0.5, 0.5); // move to upper right corner

			cr.set_source_rgba (0.0, 0.0, 0.0, 0.95);
			cr.set_line_width (1.0);
			cr.set_antialias (Cairo.Antialias.NONE);
			cr.stroke ();

			// Draw inner highlight stroke
			cr.rectangle (1.5, 1.5, size.width - 1.5, size.height - 1.5);
			cr.set_source_rgba (1.0, 1.0, 1.0, 0.2);
			cr.stroke ();

			return false;
		}

	}

}

