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
		private Label label;
		private VBox vbox;

		public DateTime date { get; set; }

		//public EventsList eventslist { get; private set; }

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

            //eventslist = new EventsList (this);
            //vbox.pack_start (eventslist, true, false, 0);

			add (Utilities.set_margins (vbox, 3, 3, 3, 3));

			// Signals and handlers
			button_press_event.connect (on_button_press);
			focus_in_event.connect (on_focus_in);
			focus_out_event.connect (on_focus_out);
			draw.connect (on_draw);

			notify["date"].connect (() => label.label = date.get_day_of_month ().to_string ());

			/*// DEBUGGING:
			eventslist.add_event(new Maya.Widgets.Event(window));
			eventslist.add_event(new Maya.Widgets.Event(window));
			eventslist.add_event(new Maya.Widgets.Event(window));
			eventslist.add_event(new Maya.Widgets.Event(window));
			eventslist.add_event(new Maya.Widgets.Event(window));
			eventslist.add_event(new Maya.Widgets.Event(window));*/
		}

		private bool on_date_change (EventFocus event) {

		    label.label = date.get_day_of_month ().to_string ();
		    return true;
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

		private bool on_draw (Widget widget, Context cr) {

			Allocation size;
			widget.get_allocation (out size);

			// Draw left and top black strokes
			cr.move_to (0.5, size.height); // start in bottom left. 0.5 accounts for cairo's default stroke offset of 1/2 pixels
			cr.line_to (0.5, 0.5); // move to upper left corner
			cr.line_to (size.width + 0.5, 0.5); // move to upper right corner

			cr.set_source_rgba (0.0, 0.0, 0.0, 0.95);
			cr.set_line_width (1.0);
			cr.set_antialias (Antialias.NONE);
			cr.stroke ();

			// Draw inner highlight stroke
			cr.rectangle (1.5, 1.5, size.width - 1.5, size.height - 1.5);
			cr.set_source_rgba (1.0, 1.0, 1.0, 0.2);
			cr.stroke ();

			return false;
		}

	}

}

