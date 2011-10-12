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

using Pango;

namespace Maya.Widgets {

	public class Sidebar : Gtk.VBox {

		private MayaWindow window;

		public Label label { get; private set; }
		public AgendaView agenda_view { get; private set; }

		/**
		 * Sidebar is a container for widgets that belong in the sidebar,
		 * like the AgendaView
		 */
		public Sidebar (MayaWindow window) {

			this.window = window;

			var scrolled_window = new ScrolledWindow (null, null);
			scrolled_window.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
			scrolled_window.set_shadow_type (ShadowType.NONE);

			// label settings
			label = new Label (_("Your upcoming events will be displayed here when you select a date with events."));
			label.sensitive = false;
			label.wrap = true;
			label.wrap_mode = Pango.WrapMode.WORD;
			label.margin_left = 15;
			label.margin_right = 15;
			label.justify = Justification.CENTER;

			agenda_view = new AgendaView (window);

			// VBox properties
			spacing = 0;
			homogeneous = false;

			var viewport = new Viewport (null, null);
			viewport.shadow_type = ShadowType.NONE;
			viewport.add (agenda_view);
			scrolled_window.add (viewport);

			pack_start (label, true, true, 0);
			pack_end (scrolled_window, false, true, 0);
			scrolled_window.hide ();
		}

	}

}

