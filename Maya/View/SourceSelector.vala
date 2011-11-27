namespace Maya.View {

class SourceGroupTreeView : Gtk.TreeView {

    public Gtk.CellRendererText r_name { get; private set; }
    public Gtk.CellRendererToggle r_enabled { get; private set; }
    public Gtk.TreeViewColumn column { get; private set; }

    public SourceGroupTreeView (Gtk.TreeModelSort model) {

        set_model (model);

        column = new Gtk.TreeViewColumn ();

        r_enabled = new Gtk.CellRendererToggle ();
        column.pack_start (r_enabled, false);

        r_name = new Gtk.CellRendererText ();
        column.pack_start (r_name, true);

        column.set_expand (true);
        append_column (column);

        headers_visible = false;
        get_selection().mode = Gtk.SelectionMode.NONE; // XXX: temporary
    }
}

class SourceGroupBox : Gtk.VBox {

    Gtk.Label label;
    public E.SourceGroup group { get; private set; }
    public SourceGroupTreeView tview { get; private set; }

    public SourceGroupBox (E.SourceGroup group, Gtk.TreeModelSort tmodel) {

        Object (homogeneous:false, spacing:0);

        this.group = group;

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
    Model.SourceSelector model;

    Gee.Map<E.SourceGroup, SourceGroupBox> _group_box;
    public Gee.Map<E.SourceGroup, SourceGroupBox> group_box {
        owned get { return _group_box.read_only_view; }
    }

    public SourceSelector(Gtk.Window window, Model.SourceSelector model) {

        transient_for = window;
        this.model = model;

        modal = false;
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

        _group_box = new Gee.HashMap<E.SourceGroup, SourceGroupBox>();

        set_title ("Calendars");

        var vbox_widget = new Gtk.VBox (false, 0);

        foreach (var group in model.groups) {
            
            var tmodel = model.group_tree_model.get (group);

            var box = new SourceGroupBox (group, tmodel);
            box.no_show_all = true;
            box.visible = model.get_sources(group).size > 0;
            _group_box.set (group, box);

            vbox_widget.pack_start (box, false, false, 0);

            box.tview.get_selection().changed.connect(() => {treeview_selection_changed (box);});

            box.tview.column.set_cell_data_func (box.tview.r_name, data_func_name);
            box.tview.column.set_cell_data_func (box.tview.r_enabled, data_func_enabled);
        }

        var vbox_window = new Gtk.VBox (false, 0);
        add (vbox_window);
        vbox_window.pack_start (vbox_widget, false, false, 0);

        delete_event.connect (hide_on_delete);
    }

    void data_func_name (Gtk.CellLayout cell_layout, Gtk.CellRenderer cell, Gtk.TreeModel tmodel, Gtk.TreeIter iter) {

        var source = model.get_source_for_iter(tmodel as Gtk.TreeModelSort, iter);
        (cell as Gtk.CellRendererText).text = source.peek_name();
    }

    void data_func_enabled (Gtk.CellLayout cell_layout, Gtk.CellRenderer cell, Gtk.TreeModel tmodel, Gtk.TreeIter iter) {

        var source = model.get_source_for_iter(tmodel as Gtk.TreeModelSort, iter);
        (cell as Gtk.CellRendererToggle).active = model.get_source_enabled(source);
    }

    /*
    * Ensure that only one row is selected in a treeview at any time
    */
    void treeview_selection_changed (SourceGroupBox box) {

        // prevent recursion
        if (box.tview.get_selection().count_selected_rows()==0)
            return; 

        var groups_to_clear = new Gee.HashSet<E.SourceGroup>();
        groups_to_clear.add_all (model.groups);
        groups_to_clear.remove (box.group);

        foreach (var group in groups_to_clear) {
            var box_clear = group_box.get (group);
            box_clear.tview.get_selection().unselect_all();
        }
    }
}

}
