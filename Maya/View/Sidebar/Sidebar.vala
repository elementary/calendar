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

	/**
	 * Sidebar is a container for widgets that belong in the sidebar,
	 * like the AgendaView
	 */
	public class Sidebar : Gtk.VBox {

		public Gtk.Label label { get; private set; }
		public AgendaView agenda_view { get; private set; }

	    public Sidebar (Model.SourceManager sourcemgr, Model.CalendarModel calmodel) {

			var scrolled_window = new Gtk.ScrolledWindow (null, null);
			scrolled_window.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
			scrolled_window.set_shadow_type (Gtk.ShadowType.NONE);
/*
			// label settings
			label = new Gtk.Label (_("Your upcoming events will be displayed here when you select a date with events."));
			label.sensitive = false;
			label.wrap = true;
			label.wrap_mode = Pango.WrapMode.WORD;
			label.margin_left = 15;
			label.margin_right = 15;
			label.justify = Gtk.Justification.CENTER;
*/
			agenda_view = new AgendaView (sourcemgr, calmodel);

			// VBox properties
			spacing = 0;
			homogeneous = false;

			var viewport = new Gtk.Viewport (null, null);
			viewport.shadow_type = Gtk.ShadowType.NONE;
			viewport.add (agenda_view);
			scrolled_window.add (viewport);

//			pack_start (label, true, true, 0);
			pack_start (scrolled_window, true, true, 0);
		}

        public void set_selected_date (DateTime date) {
            agenda_view.set_selected_date (date);
        }

	}

}

