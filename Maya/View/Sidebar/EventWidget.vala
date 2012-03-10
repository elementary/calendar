namespace Maya.View {

    /**
     * A widget displaying one event in the sidebar.
     */
    public class EventWidget : Gtk.VBox {
        
        // A label displaying the name of the event
        Gtk.Label name_label;

        // A label displaying the start date of the event
        Gtk.Label date_label;

        // A label displaying the location of the event
        Gtk.Label location_label;

        /**
         * Creates a new event widget for the given event.
         */
        public EventWidget (E.CalComponent event) {
            // TODO: style
            name_label = new Gtk.Label ("");
            name_label.set_alignment (0, 0.5f);
            pack_start (name_label, false, true, 0);

            date_label = new Gtk.Label ("");
            date_label.set_alignment (0, 0.5f);
            pack_start (date_label, false, true, 0);

            location_label = new Gtk.Label ("");
            location_label.set_alignment (0, 0.5f);
            location_label.no_show_all = true;
            pack_start (location_label, false, true, 0);

            // Fill in the information
            update (event);

            margin_left = 20;
        }

        /**
         * Updates the event to match the given event.
         */
        public void update (E.CalComponent event) {
     
            name_label.set_markup ("<big>" + Markup.escape_text (get_label (event)) + "</big>");
            date_label.set_markup ("<small>" + Markup.escape_text (get_date (event)) + "</small>");

            unowned iCal.icalcomponent ical_event = event.get_icalcomponent ();

            string location = ical_event.get_location ();

            if (location != null && location != "") {
                location_label.set_markup ("<small>" + Markup.escape_text (location) + "</small>");
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
