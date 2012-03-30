//
//  Copyright (C) 2011-2012 Maxwell Barvian
//  Copyright (C) 2011-2012 Niels Avonds <niels.avonds@gmail.com>
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
	public class AgendaView : Gtk.Grid {

        // All of the sources to be displayed and their widgets.
        Gee.Map<E.Source, SourceWidget> source_widgets;

        // Sent out when the visibility of this widget changes.
        public signal void shown_changed (bool old, bool new);

        // The previous visibility status for this widget.
        bool old_shown = false;

        // 
        int row_number = 0;

        // Sent out when an event is selected.
        public signal void event_selected (E.CalComponent event);

        // Sent out when an event is deselected.
        public signal void event_deselected (E.CalComponent event);
    
        public signal void event_removed (E.CalComponent event);
        public signal void event_modified (E.CalComponent event);

        // The current text in the search_bar
        string search_text = "";

        /**
         * Creates a new agendaview.
         */
		public AgendaView (Model.SourceManager sourcemgr, Model.CalendarModel calmodel) {

            // Gtk.Grid properties
            set_column_homogeneous (true);
            set_row_homogeneous (true);
            column_spacing = 0;
            row_spacing = 0;

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

            // Listen to changes for events
            calmodel.events_added.connect (on_events_added);
            calmodel.events_removed.connect (on_events_removed);
            calmodel.events_updated.connect (on_events_updated);

            // Listen to changes in the displayed month
            calmodel.parameters_changed.connect (on_model_parameters_changed);

            // Listen to changes in the sources
            sourcemgr.status_changed.connect (on_source_status_changed);
            sourcemgr.source_added.connect (on_source_added);
            sourcemgr.source_removed.connect (on_source_removed);
		}

        /**
         * Called when a source is checked/unchecked in the source selector.
         */
        void on_source_status_changed (E.Source source, bool enabled) {
            if (!source_widgets.has_key (source))
                return;

            source_widgets.get (source).selected = enabled;
        }

        /**
         * Called when a source is removed.
         */
        void on_source_removed (E.SourceGroup group, E.Source source) {
            if (!source_widgets.has_key (source))
                return;

            remove_source (source);
        }

        /**
         * Called when a source is added.
         */
        void on_source_added (E.SourceGroup group, E.Source source) {
            add_source (source);
        }

        /**
         * The selected month has changed, all events should be cleared.
         */
        void on_model_parameters_changed () {
            foreach (var widget in source_widgets.values)
                widget.remove_all_events ();
        }

        /**
         * Adds the given source to the list.
         */
        void add_source (E.Source source) {
            var widget = new SourceWidget (source);
            attach (widget, 0, row_number, 1, 1);
            row_number++;

            source_widgets.set (source, widget);
            widget.shown_changed.connect (on_source_shown_changed);
            widget.event_selected.connect ((event) => (event_selected (event)));
            widget.event_deselected.connect ((event) => (event_deselected (event)));
            widget.event_modified.connect ((event) => (event_modified (event)));
            widget.event_removed.connect ((event) => (event_removed (event)));
            widget.selected = true;
            widget.set_search_text (search_text);
        }

        /**
         * Called when the shown status of a source changes.
         */
        void on_source_shown_changed (bool old, bool new) {
            update_visibility ();
        }

        /**
         * Removes the given source from the list.
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

        /**
         * Updates whether this widget should currently be shown or not.
         */
        void update_visibility () {
            if (is_shown () == old_shown)
                return;

            if (is_shown ())
                show ();
            else
                hide ();

            shown_changed (old_shown, is_shown ());

            old_shown = is_shown ();
        }

        /**
         * Returns whether this widget is currently shown.
         */
        public bool is_shown () {
            return nr_of_visible_sources () > 0;
        }

        /**
         * Returns the number of source currently selected and containing any shown events.
         */
        public int nr_of_visible_sources () {
            int result = 0;
            foreach (var widget in source_widgets.values)
                if (widget.is_shown ())
                    result++;
            return result;
        }

        /**
         * Called when the user searches for the given text.
         */
        public void set_search_text (string text) {
            search_text = text;
            foreach (var widget in source_widgets.values) {
                widget.set_search_text (text);
            }
        }

	}

}

