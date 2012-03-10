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
    public class SourceWidget : Gtk.VBox {

        // The label displaying the name of this source.
        Gtk.Label name_label;
        
        // The selected date
        DateTime selected_date;

        // All of the events of the current date range in the CalendarView
        Gee.ArrayList<E.CalComponent> events;

        // All the widgets associated with the current day
        Gee.Map<E.CalComponent, EventWidget> event_widgets;

        // Whether this source is currently selected in the source selector
        public bool selected {get; set;}

        // TODO style

        // Sent out when the visibility of this widget changes.
        public signal void shown_changed (bool old, bool new);

        // Sent out when an event is selected.
        public signal void event_selected (E.CalComponent event);

        // Sent out when an event is selected.
        public signal void event_deselected (E.CalComponent event);

        // The previous visibility status for this widget.
        bool old_shown = false;

        /**
         * Creates a new source widget for the given source.
         */
        public SourceWidget (E.Source source) {

            set_spacing (5);

            // TODO: hash and equal funcs are in util but cause a crash
            // (both for map and list)
            event_widgets = new Gee.HashMap<E.CalComponent, EventWidget> (
                null,
                null,
                null);

            events = new Gee.ArrayList<E.CalComponent> (null);

            name_label = new Gtk.Label ("");
            name_label.set_markup ("<b>" + Markup.escape_text (source.peek_name()) + "</b>");
            name_label.set_alignment (0, 0.5f);
            pack_start (name_label, false, true, 0);

            notify["selected"].connect (update_visibility);
        }

        /**
         * Updates whether this widget should currently be shown or not.
         */
        void update_visibility () {
            if (is_shown () == old_shown)
                return;

            if (is_shown ())
                show_all ();
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

            events.add (event);

            if (event_in_current_date (event)) {
                show_event (event);
            }

            update_visibility ();
        }

        /**
         * Called when the given event for this source is removed.
         */
        public void remove_event (E.CalComponent event) {
            if (!events.contains (event))
                return;

            events.remove (event);

            if (event_widgets.has_key (event)) {
                hide_event (event);
            }

            update_visibility ();
        }

        /**
         * Called when the given event for this source is updated.
         */
        public void update_event (E.CalComponent event) {
            if (!events.contains (event))
                return;

            events.remove (event);
            events.add (event);

            if (event_widgets.has_key (event)) {
                event_widgets.get (event).update (event);
            }

            update_visibility ();
        }

        /**
         * Called when the selected date in the calendarview is changed.
         */
        public void set_selected_date (DateTime date) {
            selected_date = date;

            foreach (var event in events) {
                if (event_in_current_date (event) && !event_widgets.has_key (event)) {
                    show_event (event);
                } else if (!event_in_current_date (event) && event_widgets.has_key (event)) {
                    var widget = event_widgets.get (event);
                    event_widgets.unset (event);
                    widget.destroy ();
                }
            }

            update_visibility ();
        }

        /**
         * Creates a widget to show the given event.
         */
        void show_event (E.CalComponent event) {
            EventWidget widget = new EventWidget (event);
            pack_start (widget, true, true, 0);
            widget.show_all ();
            widget.selected.connect (() => {event_selected (event);});
            widget.deselected.connect (() => {event_deselected (event);});

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

            unowned iCal.icalcomponent comp = event.get_icalcomponent ();

            iCal.icaltimetype time = comp.get_dtstart ();

            DateTime start_date = Util.ical_to_date_time (time);

            if (start_date.get_year () == selected_date.get_year () && 
                start_date.get_day_of_year () == selected_date.get_day_of_year ())
                return true;
            else
                return false;
        }

        /**
         * Removes all events from the event list.
         */
        public void remove_all_events () {
            foreach (var widget in event_widgets.values) {
                widget.destroy ();
            }
            events.clear ();
            event_widgets.clear ();

            update_visibility ();
        }

    }

}
