namespace Maya.View {

    /**
     * A widget displaying one event in the sidebar.
     */
    public class EventWidget : Gtk.VBox {
        
        // A label displaying the name of the event
        Gtk.Label name_label;

        /**
         * Creates a new event widget for the given event.
         */
        public EventWidget (E.CalComponent event) {
            // TODO: style
            name_label = new Gtk.Label (get_label (event));
            name_label.set_alignment (0, 0.5f);
            pack_start (name_label, false, true, 0);
        }

        /**
         * Updates the event to match the given event.
         */
        public void update (E.CalComponent event) {
            name_label.label = get_label (event);
        }

        /**
         * Returns the name that should be displayed for the given event.
         */
        string get_label (E.CalComponent event) {
            E.CalComponentText summary = E.CalComponentText ();
            event.get_summary (out summary);

            return "    " + summary.value;
        }

    }
}
