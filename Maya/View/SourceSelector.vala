//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Maya.View {

/**
 * (All classes together) represent the popover that appears when the
 * select calendar button is clicked.
 */

/**
 * The treeview containing the groups.
 */
class SourceGroupTreeView : Gtk.TreeView {

    public Gtk.CellRendererText r_name { get; private set; }
    public Gtk.CellRendererToggle r_enabled { get; private set; }
    public Gtk.CellRendererPixbuf r_close {get; private set; }
    public Gtk.TreeViewColumn column { get; private set; }

    public SourceGroupTreeView (E.SourceGroup group, Gtk.TreeModelSort model, bool editable) {

        hexpand = true;
        set_model (model);

        column = new Gtk.TreeViewColumn ();

        r_enabled = new Gtk.CellRendererToggle ();
        column.pack_start (r_enabled, false);

        r_name = new Gtk.CellRendererText ();
        column.pack_start (r_name, true);

        column.set_expand (true);
        append_column (column);

        // Only show close buttons for the local group
        if (editable) {
            column = new Gtk.TreeViewColumn ();
            
            r_close = new Gtk.CellRendererPixbuf ();
            r_close.stock_id = "gtk-close";
            column.pack_start (r_close, false);

            column.set_expand (false);
            column.set_title ("closebuttons");
            append_column (column);
        }

        headers_visible = false;
        get_selection().mode = Gtk.SelectionMode.NONE; // XXX: temporary
    }
}

/**
 * The group box containing the different groups of calendars inside the popover.
 */
class SourceGroupBox : Gtk.Grid {

    Gtk.Label label;
    public E.SourceGroup group { get; private set; }
    public SourceGroupTreeView tview { get; private set; }

    public SourceGroupBox (E.SourceGroup group, Gtk.TreeModelSort tmodel, Model.SourceManager model, bool editable) {

        //Object (homogeneous:false, spacing:0);

        this.group = group;

        label = new Gtk.Label (group.peek_name());
        label.xalign = 0.0f;

        var evbox = new Gtk.EventBox();
        evbox.add(label);
        attach (evbox, 0, 0, 1, 1);

        tview = new SourceGroupTreeView (group, tmodel, editable);
        attach (tview, 0, 1, 1, 1);

        label.margin_top = 8;
        label.margin_bottom = 2;

        // Add entry to editable groups
        if (editable) {
            var entry = new Granite.Widgets.HintedEntry (_("Add calendar"));
            attach (entry, 0, 2, 1, 1);
            entry.activate.connect (() => {on_entry_activate (model, group, entry.text);entry.text = "";});
        }

        show_all();

        // Listen to clicks on the treeview
        tview.button_press_event.connect ((button) => (on_click(button, tmodel, model)));
    }

    bool on_click (Gdk.EventButton button, Gtk.TreeModelSort tmodel, Model.SourceManager model) {

        // Only react on single left click
        if (button.type != Gdk.EventType.BUTTON_PRESS || button.button != 1)
            return false;

        // Check where the user clicked
        Gtk.TreePath path;
        Gtk.TreeViewColumn col;
        tview.get_path_at_pos ((int) button.x, (int) button.y, out path, out col, null, null);
        
        // Column other than close was clicked, don't handle it
        if (col.get_title () != "closebuttons")
            return false;

        // Search for the corresponding source
        Gtk.TreeIter iter;
        bool result = tmodel.get_iter (out iter, path);

        var source = model.get_source_for_iter (tmodel, iter);

        // Destroy the source
        model.destroy_source (group, source);

        return true;
    }

    /**
     * Called when enter is pressed in the add source entry
     */
    void on_entry_activate (Model.SourceManager model, E.SourceGroup group, string entry_text) {

        var new_source = new E.Source (entry_text, entry_text);
        model.create_source (group, new_source);
    }

}

/**
 * The actual popover
 */
class SourceSelector : Granite.Widgets.PopOver {

    Model.SourceManager model;

    Gee.Map<E.SourceGroup, SourceGroupBox> _group_box;

    public SourceSelector(Gtk.Window window, Model.SourceManager model) {

        transient_for = window;
        this.model = model;

        modal = false;
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

        _group_box = new Gee.HashMap<E.SourceGroup, SourceGroupBox> (
            (HashFunc) Util.source_group_hash_func,
            (EqualFunc) Util.source_group_equal_func,
            null);

        set_title ("Calendars");

        var sources_grid = new Gtk.Grid ();
        int groupnumber = 0;
        foreach (var group in model.groups) {
            
            var tmodel = model.get_tree_model (group);

            // Only local group is editable for now
            bool editable = group.peek_base_uri() == "local:";
            
            var box = new SourceGroupBox (group, tmodel, model, editable);
            box.no_show_all = true;
            // Don't show empty groups (but always show editable groups)
            box.visible = model.get_sources(group).size > 0 || editable;
            _group_box.set (group, box);

            sources_grid.attach (box, 0, groupnumber, 1, 1);

            box.tview.get_selection().changed.connect(() => {treeview_selection_changed (box);});

            box.tview.column.set_cell_data_func (box.tview.r_name, data_func_name);
            box.tview.column.set_cell_data_func (box.tview.r_enabled, data_func_enabled);
            groupnumber++;
        }

        var container = (Gtk.Container) get_content_area ();
        container.add (sources_grid);

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

        var groups_to_clear = new Gee.HashSet<E.SourceGroup> (
            (HashFunc) Util.source_group_hash_func,
            (EqualFunc) Util.source_group_equal_func);

        groups_to_clear.add_all (model.groups);
        groups_to_clear.remove (box.group);

        foreach (var group in groups_to_clear) {
            var box_clear = _group_box [group];
            box_clear.tview.get_selection().unselect_all();
        }
    }

    public SourceGroupBox get_group_box (E.SourceGroup group) {

        return _group_box [group];
    }
}

}
