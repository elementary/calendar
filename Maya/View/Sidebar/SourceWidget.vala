namespace Maya.View {
    
    public class SourceWidget : Gtk.VBox {

        Gtk.Label name_label;

        Gee.Map<E.CalComponent, EventWidget> event_widgets;

        public SourceWidget (E.Source source) {
            
            // TODO: hash and equal funcs are in util but cause a crash
            event_widgets = new Gee.HashMap<E.CalComponent, EventWidget> (
                null,
                null,
                null);

            name_label = new Gtk.Label (source.peek_name ());
            name_label.set_alignment (0, 0.5f);
            pack_start (name_label, false, true, 0);

        }

        public void add_event (E.CalComponent event) {
            stdout.printf ("ADDED\n");

            EventWidget widget = new EventWidget (event);
            pack_start (widget, true, true, 0);
            show_all ();

            stdout.printf ("ADDED OK\n");


            event_widgets.set (event, widget);

        }

        public void remove_event (E.CalComponent event) {
            stdout.printf ("REMOVED\n");
            if (!event_widgets.has_key (event))
                return;

            stdout.printf ("REMOVED OK\n");

            var widget = event_widgets.get (event);
            widget.destroy ();
        }

        public void update_event (E.CalComponent event) {
            stdout.printf ("UPDATED\n");
            if (!event_widgets.has_key (event))
                return;

            stdout.printf ("UPDATED OK\n");

            event_widgets.get(event).update (event);
        }

        public void set_selected_date (DateTime date) {
            foreach (var widget in event_widgets.values )
                widget.set_selected_date (date);
        }

    }

}
