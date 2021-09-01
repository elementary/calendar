class Calendar.DeleteDialog : Granite.MessageDialog {
    private E.Source? original_source;
    private ECal.Component ecal;
    private ECal.ObjModType mod_type;

    public DeleteDialog (E.Source? _original_source,ECal.Component _ecal, ECal.ObjModType _mod_type) {
        original_source = _original_source;
        ecal = _ecal;
        mod_type = _mod_type;
    }

    construct {
        this = new Granite.MessageDialog.with_image_from_icon_name (
            _("Delete event?"),
            _("This event and all its occurrences will be permanently deleted."),
            "dialog-warning",
            Gtk.ButtonsType.CANCEL
        );

        unowned Gtk.Widget trash_button = add_button (_("Delete Event"), Gtk.ResponseType.YES);
        trash_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        trash_button.clicked.connect (confirm_delete);
    }

    void confirm_delete () {

    }
}
