namespace Maya.View {
    public class EventWidget : Gtk.VBox {
        
        Gtk.Label name_label;
        E.CalComponent shown_event;
        DateTime selected_date;

        public EventWidget (E.CalComponent event) {
            // TODO: style
            name_label = new Gtk.Label (get_label (event));
            name_label.set_alignment (0, 0.5f);
            pack_start (name_label, false, true, 0);

            shown_event = event;
        }

        public void update (E.CalComponent event) {
            name_label.label = get_label (event);
            shown_event = event;
        }

        string get_label (E.CalComponent event) {
            E.CalComponentText summary = E.CalComponentText ();
            event.get_summary (out summary);

            return "    " + summary.value;
        }

        public void set_selected_date (DateTime date) {
            selected_date = date;
            update_visibility ();
        }

        void update_visibility () {

            unowned iCal.icalcomponent comp = shown_event.get_icalcomponent ();

            iCal.icaltimetype time = comp.get_dtstart ();

            DateTime start_date = Util.ical_to_date_time (time);

            if (start_date.get_year () == selected_date.get_year () && 
                start_date.get_day_of_year () == selected_date.get_day_of_year ())
                show ();
            else
                hide ();
        }

    }
}
