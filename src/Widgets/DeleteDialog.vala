class Calendar.DeleteEventDialog : Granite.MessageDialog {
    public E.Source? source { get; construct; }
    public ECal.Component ecal_event { get; construct; }
    public ECal.ObjModType mod_type_prop { get; construct; }
    public string delete_button_text {get; construct; }

    public DeleteEventDialog (E.Source? source, ECal.Component ecal_event, ECal.ObjModType mod_type_prop) {
        string title, description, delete_text;
        var summary = ecal_event.get_summary ();
        if (ecal_event.has_recurrences ()) {
            if (mod_type_prop == ECal.ObjModType.THIS) {
                if (summary == null) {
                    title = _("Delete this occurrence of event?");
                } else {
                    title = _("Delete this occurrence of event “%s”?").printf (((!)summary).get_value ()); // Should question mark be in or out of quotes?
                }
                description = _("This occurrence will be permanently deleted, but all other occurrences will remain unchanged.");
                delete_text = _("Delete Occurrence");
            } else {
                if (mod_type_prop != ECal.ObjModType.ALL) {
                    warning (@"Creating delete dialog for unknown ObjModType: $mod_type_prop; defaulting to modify all");
                }

                if (summary == null) {
                    title = _("Delete event?");
                } else {
                    title = _("Delete event “%s”?").printf (((!)summary).get_value ()); // Should question mark be in or out of quotes?
                }
                description = _("This event and all its occurrences will be permanently deleted.");
                delete_text = _("Delete Event");
            }
        } else {
            if (summary == null) {
                title = _("Delete event?");
            } else {
                title = _("Delete event “%s”?").printf (((!)summary).get_value ()); // Should question mark be in or out of quotes?
            }
            description = _("This event will be permanently deleted.");
            delete_text = _("Delete Event");
        }

        Object (
            source: source,
            ecal_event: ecal_event,
            mod_type_prop: mod_type_prop,
            primary_text: title,
            secondary_text: description,
            image_icon: new ThemedIcon ("dialog-warning"),
            buttons: Gtk.ButtonsType.CANCEL,
            delete_button_text: delete_text
        );
    }

    construct {
        unowned var trash_button = add_button (delete_button_text, Gtk.ResponseType.YES);
        trash_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
    }

    public Gtk.ResponseType run_dialog () {
        var response = (Gtk.ResponseType) this.run ();
        if (response == Gtk.ResponseType.YES) {
            var calmodel = Calendar.EventStore.get_default ();
            calmodel.remove_event (source, ecal_event, mod_type_prop);
        }
        this.destroy ();
        return response;
    }
}
