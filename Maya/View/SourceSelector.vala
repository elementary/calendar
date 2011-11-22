namespace Maya.View {

class SourceGroupTreeView : Gtk.TreeView {

    Gtk.CellRendererText r_name;
    Gtk.CellRendererToggle r_enabled;

    public SourceGroupTreeView (Gtk.TreeModelSort model) {

        set_model (model);

        get_selection().mode = Gtk.SelectionMode.SINGLE;

        var column = new Gtk.TreeViewColumn ();

        r_enabled = new Gtk.CellRendererToggle ();
        column.pack_start (r_enabled, false);
        column.set_cell_data_func (r_enabled, data_func_enabled);

        r_name = new Gtk.CellRendererText ();
        column.pack_start (r_name, true);
        column.set_cell_data_func (r_name, data_func_name);

        column.set_expand (true);
        append_column (column);

        headers_visible = false;
        set_show_expanders (true);

        expand_all ();
    }

    Model.SourceDecorator get_source_for_iter (Gtk.TreeModel model, Gtk.TreeIter iter_outer) {

        assert((model as Gtk.TreeModelSort).iter_is_valid(iter_outer));

        Gtk.TreeIter iter_inner;
        (model as Gtk.TreeModelSort).convert_iter_to_child_iter(out iter_inner, iter_outer);
        assert(((model as Gtk.TreeModelSort).get_model() as Gtk.ListStore).iter_is_valid(iter_inner));

        Value v;
        (model as Gtk.TreeModelSort).get_model().get_value(iter_inner, 0, out v);

        return (v as Model.SourceDecorator);
    }

    void data_func_name (Gtk.CellLayout cell_layout, Gtk.CellRenderer cell, Gtk.TreeModel model, Gtk.TreeIter iter) {
        var source = get_source_for_iter(model, iter);
        (cell as Gtk.CellRendererText).text = source.esource.peek_name();
    }

    void data_func_enabled (Gtk.CellLayout cell_layout, Gtk.CellRenderer cell, Gtk.TreeModel model, Gtk.TreeIter iter) {
        var source = get_source_for_iter(model, iter);
        (cell as Gtk.CellRendererToggle).active = source.enabled;
    }
}

class SourceGroupBox : Gtk.VBox {

    Gtk.Label label;
    SourceGroupTreeView tview;

    public SourceGroupBox (E.SourceGroup group, Gtk.TreeModelSort tmodel) {

        Object (homogeneous:false, spacing:0);

        label = new Gtk.Label (group.peek_name());
        label.xalign = 0.0f;

        var evbox = new Gtk.EventBox();
        evbox.add(label);
        pack_start (evbox, false, false, 0);

        tview = new SourceGroupTreeView (tmodel);
        pack_start (tview, false, false, 0);

        evbox.modify_bg (Gtk.StateType.NORMAL, tview.style.base[Gtk.StateType.NORMAL]);
        label.margin_top = 8;
        label.margin_bottom = 2;

        show_all();
    }
}

class SourceSelector : Gtk.Window {

    SourceGroupTreeView tree_view;
    Gee.Map<E.SourceGroup, Gtk.Widget> group_widget;

    public SourceSelector(Gtk.Window window, Model.SourceSelector model) {

        modal = false;
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
        transient_for = window;

        group_widget = new Gee.HashMap<E.SourceGroup, Gtk.Widget>();

        set_title ("Calendars");

        var vbox_widget = new Gtk.VBox (false, 0);

        foreach (var group in model.groups) {
            
            var tmodel = model.group_tree_model.get (group);
            var box = new SourceGroupBox (group, tmodel);

            box.no_show_all = true;
            box.visible = model.get_show_group(group);

            vbox_widget.pack_start (box, false, false, 0);
        }

        var vbox_window = new Gtk.VBox (false, 0);
        add (vbox_window);
        vbox_window.pack_start (vbox_widget, false, false, 0);

        delete_event.connect (hide_on_delete);
    }

}

}
