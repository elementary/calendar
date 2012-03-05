namespace Maya.View {

/**
 * Represents a single event on the grid.
 */
class EventButton : Gtk.HBox {

    public E.CalComponent comp;
    public signal void removed (E.CalComponent comp);
    public signal void modified (E.CalComponent comp);
    
    Gtk.Label label;
    Gtk.Button close_button;
    Gtk.Button edit_button;
    public EventButton (E.CalComponent comp) {
        
        E.CalComponentText ct;
        this.comp = comp;
        comp.get_summary (out ct);
        label = new Granite.Widgets.WrapLabel(ct.value);
        pack_start (label, true, true, 0);
        label.hexpand = true;
        label.valign = Gtk.Align.CENTER;
        close_button = new Gtk.Button ();
        edit_button = new Gtk.Button ();
        close_button.add (new Gtk.Image.from_stock ("gtk-close", Gtk.IconSize.MENU));
        edit_button.add (new Gtk.Image.from_stock ("gtk-edit", Gtk.IconSize.MENU));
        close_button.set_relief (Gtk.ReliefStyle.NONE);
        edit_button.set_relief (Gtk.ReliefStyle.NONE);
        
        pack_end (edit_button, false, false, 0);
        pack_end (close_button, false, false, 0);
        
        close_button.clicked.connect( () => { removed(comp); });
        edit_button.clicked.connect( () => { modified(comp); });
    }
}

}
