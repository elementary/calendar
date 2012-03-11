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

		public Gtk.EventBox label_box { get; private set; }
		public AgendaView agenda_view { get; private set; }

        Gtk.ScrolledWindow scrolled_window;

        // Sent out when an event is selected.
        public signal void event_selected (E.CalComponent event);

        // Sent out when an event is deselected.
        public signal void event_deselected (E.CalComponent event);
    
        public signal void event_removed (E.CalComponent event);
        public signal void event_modified (E.CalComponent event);

	    public Sidebar (Model.SourceManager sourcemgr, Model.CalendarModel calmodel) {

			scrolled_window = new Gtk.ScrolledWindow (null, null);
			scrolled_window.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
			scrolled_window.set_shadow_type (Gtk.ShadowType.NONE);

            label_box = new Gtk.EventBox ();

			// label settings
			Gtk.Label label = new Gtk.Label (_("Your upcoming events will be displayed here when you select a date with events."));
			label.sensitive = false;
			label.wrap = true;
			label.wrap_mode = Pango.WrapMode.WORD;
			label.margin_left = 15;
			label.margin_right = 15;
			label.justify = Gtk.Justification.CENTER;

			agenda_view = new AgendaView (sourcemgr, calmodel);

			// VBox properties
			spacing = 0;
			homogeneous = false;

			var viewport = new Gtk.Viewport (null, null);
			viewport.shadow_type = Gtk.ShadowType.NONE;
			viewport.add (agenda_view);
            viewport.show ();
			scrolled_window.add (viewport);

            label_box.add (label);

			pack_start (label_box, true, true, 0);
			pack_start (scrolled_window, true, true, 0);

            scrolled_window.hide ();

            var style_provider = Util.Css.get_css_provider ();

            label_box.get_style_context().add_provider (style_provider, 600);
            label_box.get_style_context().add_class ("sidebar");

            viewport.get_style_context().add_provider (style_provider, 600);
            viewport.get_style_context().add_class ("sidebar");

            label_box.show ();
            label.show ();
            agenda_view.shown_changed.connect (on_agenda_view_shown_changed);
            agenda_view.event_selected.connect ((event) => (event_selected (event)));
            agenda_view.event_deselected.connect ((event) => (event_deselected (event)));
            agenda_view.event_removed.connect ((event) => (event_removed (event)));
            agenda_view.event_modified.connect ((event) => (event_modified (event)));
		}

        public void set_selected_date (DateTime date) {
            agenda_view.set_selected_date (date);
        }

        void on_agenda_view_shown_changed (bool old_shown, bool shown) {
            if (shown) {
                scrolled_window.show ();
                label_box.hide ();
            } else {
                scrolled_window.hide ();
                label_box.show ();
            }
        }

	}

}

