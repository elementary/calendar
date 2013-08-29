//
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
     * A widget containing one source to be displayed in the sidebar.
     */
    public class SourceWidget : Gtk.Grid {

        // The label displaying the name of this source.
        Gtk.Label name_label;

        // The selected date
        DateTime selected_date;

        // All of the events of the current date range in the CalendarView
        Gee.ArrayList<E.CalComponent> current_events;

        // All the widgets associated with the current day
        Gee.Map<E.CalComponent, EventWidget> event_widgets;

        // Count how many events are shown (+1)
        int number_of_events = 1;

        // Whether this source is currently selected in the source selector
        public bool selected {get; set;}

        // Sent out when the visibility of this widget changes.
        public signal void shown_changed (bool old, bool new);

        public signal void event_removed (E.CalComponent event);
        public signal void event_modified (E.CalComponent event);

        E.Source source;

        // The previous visibility status for this widget.
        bool old_shown = false;

        // The current text in the search_bar
        string search_text = "";

        /**
         * Creates a new source widget for the given source.
         */
        public SourceWidget (E.Source source) {
            set_row_spacing (5);

            this.source = source;

            // TODO: hash and equal funcs are in util but cause a crash
            // (both for map and list)
            event_widgets = new Gee.HashMap<E.CalComponent, EventWidget> (
                null,
                null,
                null);

            current_events = new Gee.ArrayList<E.CalComponent> (null);

            name_label = new Gtk.Label ("");
            name_label.set_markup ("<b>" + Markup.escape_text (source.dup_display_name()) + "</b>");
            name_label.set_alignment (0, 0.5f);
            attach (name_label, 0, 0, 1, 1);
            name_label.show ();

            notify["selected"].connect (update_visibility);
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
         * Indicates if this source widget is shown (selected and contains visible events)
         */
        public bool is_shown () {
            return selected && event_widgets.size > 0;
        }

        /**
         * Called when the given event for this source is added.
         */
        public void add_event (E.CalComponent event) {
            if (event_widgets.has_key (event))
                remove_event (event);

            current_events.add (event);

            update_widget_for (event);

            reorder_widgets ();
            update_visibility ();
        }

        /**
         * Called when the given event for this source is removed.
         */
        public void remove_event (E.CalComponent event) {
            if (!current_events.contains (event))
                return;

            current_events.remove (event);

            if (event_widgets.has_key (event)) {
                hide_event (event);
            }

            update_visibility ();
        }

        /**
         * Called when the given event for this source is updated.
         */
        public void update_event (E.CalComponent event) {
            if (!current_events.contains (event))
                return;

            current_events.remove (event);
            current_events.add (event);

            bool shown = event_in_current_date (event);

            if (event_widgets.has_key (event) && shown) {
                event_widgets.get (event).update (event);
            }
            if (!shown)
                hide_event (event);

            reorder_widgets ();
            update_visibility ();
        }

        void reorder_widgets () {
            // Sort events list
            current_events.sort (compare_comps);
            number_of_events = 1;
            foreach (var event in current_events) {
                bool has_widget = event_widgets.has_key (event);

                if (has_widget) {
                    Gtk.Widget temp_widget = event_widgets.get (event);
                    remove (event_widgets.get (event));
                    attach (temp_widget, 0, number_of_events, 1, 1);
                    number_of_events++;
                }
            }
        }

        /**
         * Compares the given buttons according to date.
         */
        static CompareFunc<E.CalComponent> compare_comps = (comp1, comp2) => {
            return Util.compare_events (comp1, comp2);
        };

        /**
         * Called when the selected date in the calendarview is changed.
         */
        public void set_selected_date (DateTime date) {
            selected_date = date;

            update_current_date_events ();

            update_visibility ();
        }

        /**
         * Updates the event widgets to the events in the current date.
         *
         * All events in the currently selected date have an event widget associated with it,
         * even the ones that don't pass the search filter.
         */
        void update_current_date_events () {
            foreach (var event in current_events) {
               update_widget_for (event);
            }
        }

        /**
         * Creates / destroys and shows / hides the widget for the given event,
         * depending on respectively the date and the search filter.
         */
        void update_widget_for (E.CalComponent event) {
            bool shown = event_in_current_date (event);
            bool has_widget = event_widgets.has_key (event);
            if (shown && !has_widget) {
                show_event (event);
                has_widget = true;
            } else if (!shown && has_widget) {
                hide_event (event);
                has_widget = false;
            }

            if (has_widget)
                update_show_hide_for (event);
        }

        /**
         * Shows / hides the event widgets that do / don't pass the filter.
         */
        void update_filter_events () {
            foreach (var event in event_widgets.keys) {
                update_show_hide_for (event);
            }

        }

        /**
         * Shows / hides the event widget for the given event.
         */
        void update_show_hide_for (E.CalComponent event) {
            bool passes = event_passes_search_filter (event);
            if (passes)
                event_widgets.get (event).show_all ();
            else
                event_widgets.get (event).hide ();
        }

        /**
         * Creates a widget to show the given event.
         */
        void show_event (E.CalComponent event) {
            EventWidget widget = new EventWidget (this.source, event);
            attach (widget, 0, number_of_events, 1, 1);
            number_of_events++;
            widget.modified.connect ((event) => (event_modified (event)));
            widget.removed.connect ((event) => (event_removed (event)));

            event_widgets.set (event, widget);
        }

        /**
         * Destroys the widget associated with the given event.
         */
        void hide_event (E.CalComponent event) {
            var widget = event_widgets.get (event);
            event_widgets.unset (event);
            widget.destroy ();
        }

        /**
         * Indicates if the given event is in the currently selected date.
         */
        bool event_in_current_date (E.CalComponent event) {
            if (selected_date == null)
                return false;

            Util.DateRange dt_range = Util.event_date_range (event);

            if (dt_range.contains (selected_date))
                return true;
            else
                return false;
        }

        /**
         * Indicates if the given event passes the current search filter.
         */
        bool event_passes_search_filter (E.CalComponent event) {
            E.CalComponentText summary = E.CalComponentText ();
            event.get_summary (out summary);

            string[] filter_strings = Regex.split_simple (" ", search_text);

            foreach (string filter_string in filter_strings) {
                if (!Regex.match_simple (filter_string, summary.value, RegexCompileFlags.CASELESS))
                    return false;
            }

            return true;
        }

        /**
         * Removes all events from the event list.
         */
        public void remove_all_events () {
            foreach (var widget in event_widgets.values) {
                widget.destroy ();
            }
            current_events.clear ();
            event_widgets.clear ();

            update_visibility ();
        }

        /**
         * Called when the user searches for the given text.
         */
        public void set_search_text (string text) {
            search_text = text;
            update_filter_events ();
        }

    }

}
