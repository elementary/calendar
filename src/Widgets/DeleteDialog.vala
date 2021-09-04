class Calendar.DeleteEventDialog : Granite.MessageDialog {
    private unowned E.Source? source;
    private unowned ECal.Component ecal_event;
    private unowned ECal.ObjModType mod_type_prop;

    public DeleteEventDialog (E.Source? _original_source, ECal.Component _ecal, ECal.ObjModType _mod_type) {
        this.source = _original_source;
        this.ecal_event = _ecal;
        // source = ecal.get_data<E.Source> ("source");
        this.mod_type_prop = _mod_type;
        // debug (ecal.get_summary ().get_value ());

        string title, description;
        var summary = _ecal.get_summary ();
        if (_ecal.has_recurrences ()) {
            if (mod_type_prop == ECal.ObjModType.THIS) {
                if (summary == null) {
                    title = _("Delete this occurrence of event?");
                } else {
                    title = _("Delete this occurrence of event “%s”?").printf (((!)summary).get_value ()); // Should question mark be in or out of quotes?
                }
                description = _("This occurrence will be permanently deleted, but all other occurrences will remain unchanged.");
            } else {
                if (summary == null) {
                    title = _("Delete event?");
                } else {
                    title = _("Delete event “%s”?").printf (((!)summary).get_value ()); // Should question mark be in or out of quotes?
                }
                description = _("This event and all its occurrences will be permanently deleted.");
            }
        } else {
            if (summary == null) {
                title = _("Delete event?");
            } else {
                title = _("Delete event “%s”?").printf (((!)summary).get_value ()); // Should question mark be in or out of quotes?
            }
            description = _("This event will be permanently deleted.");
        }
        base.with_image_from_icon_name (title, description, "dialog-warning", Gtk.ButtonsType.CANCEL);

        // trash_button.clicked.connect (confirm_delete);
    }

    construct {
        unowned var trash_button = add_button (_("Delete Event"), Gtk.ResponseType.YES);
        trash_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
    }

    public void run_dialog () {
        var response = (Gtk.ResponseType) this.run ();
        if (response == Gtk.ResponseType.YES) {
            var calmodel = Calendar.EventStore.get_default ();
            calmodel.remove_event (source, ecal_event, mod_type_prop);
        }
        this.destroy ();
    }
}
