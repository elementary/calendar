
/**
 * This class represents an event as shown in the agenda view.
 */
public class AgendaEvent : Gtk.HBox {
        
    public AgendaEvent () {
        
        set_spacing (3);

        create_time_label ();
        create_subject_label ();
    }

    /**
     * Creates the label containing the given time.
     */
    void create_time_label (DateTime time) {

        // Date.format (format)
        string time_string = time.format (Settings.TimeFormat ());

        Gtk.Label time_label = new Gtk.Label (time_string);
        time_label.set_width_chars (8);

        pack_start (time_label, false, false, 0);
    }

    /**
     * Creates a label containing the event subject
     */
    void create_subject_label (string subject) {
        Gtk.Label subject_label = new Gtk.Label (subject);

        pack_start (subject_label, true, true, 0);
    }

}
