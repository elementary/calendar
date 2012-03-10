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
     * A widget displaying one event in the sidebar.
     */
    public class EventWidget : Gtk.EventBox {
        
        // A label displaying the name of the event
        Gtk.Label name_label;

        // A label displaying the start date of the event
        Gtk.Label date_label;

        // A label displaying the location of the event
        Gtk.Label location_label;

        // A Vbox containing the labels
        Gtk.VBox vbox;

        // Signal sent out when the event is selected.
        public signal void selected ();

        // Signal sent out when the event is deselected.
        public signal void deselected ();

        /**
         * Creates a new event widget for the given event.
         */
        public EventWidget (E.CalComponent event) {

            var style_provider = Util.Css.get_css_provider ();

            get_style_context().add_provider (style_provider, 600);
            get_style_context().add_class ("sidebarevent");

            vbox = new Gtk.VBox (false, 3);

            name_label = new Gtk.Label ("");
            name_label.set_alignment (0, 0.5f);
            vbox.pack_start (name_label, false, true, 0);

            date_label = new Gtk.Label ("");
            date_label.set_alignment (0, 0.5f);
            vbox.pack_start (date_label, false, true, 0);

            location_label = new Gtk.Label ("");
            location_label.set_alignment (0, 0.5f);
            location_label.no_show_all = true;
            vbox.pack_start (location_label, false, true, 0);

            vbox.show ();
            add (vbox);

            can_focus = true;
            set_visible_window (true);
            events |= Gdk.EventMask.BUTTON_PRESS_MASK;
            button_press_event.connect (on_button_press);

            focus_in_event.connect (on_focus_in);
            focus_out_event.connect (on_focus_out);

            // Fill in the information
            update (event);

            vbox.margin_left = 20;
        }

        private bool on_button_press (Gdk.EventButton event) {

            grab_focus ();
            return true;
        }

        private bool on_focus_in (Gdk.EventFocus event) {
                        
            selected ();
            return false;
        }

        private bool on_focus_out (Gdk.EventFocus event) {
                        
            deselected ();
            return false;
        }

        /**
         * Updates the event to match the given event.
         */
        public void update (E.CalComponent event) {
     
            name_label.set_markup ("<big>" + Markup.escape_text (get_label (event)) + "</big>");
            date_label.set_markup ("<span weight=\"light\">" + get_date (event) + "</span>");

            unowned iCal.icalcomponent ical_event = event.get_icalcomponent ();

            string location = ical_event.get_location ();

            if (location != null && location != "") {
                location_label.set_markup ("<span weight=\"light\">" + location + "</span>");
                location_label.show ();
            } else
                location_label.hide ();
        }

        /**
         * Returns the name that should be displayed for the given event.
         */
        string get_label (E.CalComponent event) {
            E.CalComponentText summary = E.CalComponentText ();
            event.get_summary (out summary);

            return summary.value;
        }

        /**
         * Returns the date that should be displayed for the given event.
         */
        string get_date (E.CalComponent event) {
            E.CalComponentDateTime date = E.CalComponentDateTime ();

            event.get_dtstart (out date);

            DateTime date_time = Util.ical_to_date_time (*date.value);

            string date_string = date_time.format ("%A, %b %d");
            string time_string = date_time.format (Settings.TimeFormat ());

            return date_string + " at " + time_string;
        }
    }
}
