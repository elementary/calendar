namespace Maya.View {
    public class EventWidget : Gtk.VBox {
        
        Gtk.Label name_label;

        public EventWidget (E.CalComponent event) {
            // TODO: style
            name_label = new Gtk.Label (get_label (event));
            name_label.set_alignment (0, 0.5f);
            pack_start (name_label, false, true, 0);
        }

        public void update (E.CalComponent event) {
            name_label.label = get_label (event);
        }

        string get_label (E.CalComponent event) {
            E.CalComponentText summary = E.CalComponentText ();
            event.get_summary (out summary);

            return "    " + summary.value;
        }

    }
}
