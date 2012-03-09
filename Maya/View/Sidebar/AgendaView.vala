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
     * The AgendaView shows all events for the currently selected date,
     * even with fancy colors!
     */
	public class AgendaView : Gtk.VBox {

        Gee.Map<E.Source, SourceWidget> source_widgets;

		public AgendaView (Model.SourceManager sourcemgr, Model.CalendarModel calmodel) {

			// VBox properties
			spacing = 0;
			homogeneous = false;

            source_widgets = new Gee.HashMap<E.Source, SourceWidget> (
                (HashFunc) Util.source_hash_func,
                (EqualFunc) Util.source_equal_func,
                null);

            Gee.List<E.SourceGroup> groups = sourcemgr.groups;
            
            foreach (E.SourceGroup group in groups) {
                foreach (E.Source source in group.peek_sources () ) {
                    add_source (source);
                }
            }

            calmodel.events_added.connect (on_events_added);
            calmodel.events_removed.connect (on_events_removed);
            calmodel.events_updated.connect (on_events_updated);
		}

//      public signal void events_added (E.Source source, Gee.Collection<E.CalComponent> events);
//      public signal void events_updated (E.Source source, Gee.Collection<E.CalComponent> events);
//      public signal void events_removed (E.Source source, Gee.Collection<E.CalComponent> events);


        // TODO: listen to event_added / event_modified / event_removed
        // TODO: listen to source_added / source_removed
        // TODO: only show current date's events
        

        void add_source (E.Source source) {
            var widget = new SourceWidget (source);
            pack_start (widget, false, true, 0);

            source_widgets.set (source, widget);
        }

        void remove_source (E.Source source) {
            var widget = source_widgets.get (source);
            widget.destroy ();
        }

        void on_events_added (E.Source source, Gee.Collection<E.CalComponent> events) {
            if (!source_widgets.has_key (source))
                return;

            foreach (var event in events)
                if (event != null)
                    source_widgets.get (source).add_event (event);
        }

        void on_events_updated (E.Source source, Gee.Collection<E.CalComponent> events) {
            if (!source_widgets.has_key (source))
                return;

            foreach (var event in events)
                source_widgets.get (source).update_event (event);
        }

        void on_events_removed (E.Source source, Gee.Collection<E.CalComponent> events) {
            if (!source_widgets.has_key (source))
                return;

            foreach (var event in events)
                source_widgets.get (source).remove_event (event);
        }

        public void set_selected_date (DateTime date) {
            foreach (var widget in source_widgets.values )
                widget.set_selected_date (date);
        }

	}

}

