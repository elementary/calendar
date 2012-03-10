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

    // TODO: listen to source_added / source_removed (+ checked / unchecked)
    // TODO: destroy empty sources (see how it's done in SourceWidget for eventwidgets)

    /**
     * The AgendaView shows all events for the currently selected date,
     * even with fancy colors!
     */
	public class AgendaView : Gtk.VBox {

        // All of the sources to be displayed and their widgets.
        Gee.Map<E.Source, SourceWidget> source_widgets;

        /**
         * Creates a new agendaview.
         */
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

            calmodel.parameters_changed.connect (on_model_parameters_changed);
		}

        /**
         * The selected month has changed, all events should be cleared.
         */
        void on_model_parameters_changed () {
            foreach (var widget in source_widgets.values)
                widget.remove_all_events ();
        }

        /**
         * A source has been added.
         */
        void add_source (E.Source source) {
            var widget = new SourceWidget (source);
            pack_start (widget, false, true, 0);

            source_widgets.set (source, widget);
        }

        /**
         * A source has been removed.
         */
        void remove_source (E.Source source) {
            var widget = source_widgets.get (source);
            widget.destroy ();
        }

        /**
         * Events have been added to the given source.
         */
        void on_events_added (E.Source source, Gee.Collection<E.CalComponent> events) {
            if (!source_widgets.has_key (source))
                return;

            foreach (var event in events)
                if (event != null)
                    source_widgets.get (source).add_event (event);
        }

        /**
         * Events for the given source have been updated.
         */
        void on_events_updated (E.Source source, Gee.Collection<E.CalComponent> events) {
            if (!source_widgets.has_key (source))
                return;

            foreach (var event in events)
                source_widgets.get (source).update_event (event);
        }

        /**
         * Events for the given source have been removed.
         */
        void on_events_removed (E.Source source, Gee.Collection<E.CalComponent> events) {
            if (!source_widgets.has_key (source))
                return;

            foreach (var event in events)
                source_widgets.get (source).remove_event (event);
        }

        /**
         * The given date has been selected.
         */
        public void set_selected_date (DateTime date) {
            foreach (var widget in source_widgets.values )
                widget.set_selected_date (date);
        }

	}

}

