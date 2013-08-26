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

public class Maya.View.SourceSelector : Granite.Widgets.PopOver {
    
    private Gtk.ListStore list_store;
    private Gtk.TreeView tree_view;

    private enum Columns {
        TOGGLE,
        TEXT,
        N_COLUMNS
    }
    
    public SourceSelector () {
        
        list_store = new Gtk.ListStore (Columns.N_COLUMNS, typeof (bool), typeof (string));
        tree_view = new Gtk.TreeView.with_model (list_store);

        var toggle = new Gtk.CellRendererToggle ();
        toggle.toggled.connect ((toggle, path) => {
            var tree_path = new Gtk.TreePath.from_string (path);
            Gtk.TreeIter iter;
            list_store.get_iter (out iter, tree_path);
            list_store.set (iter, Columns.TOGGLE, !toggle.active);
        });

        var column = new Gtk.TreeViewColumn ();
        column.pack_start (toggle, false);
        column.add_attribute (toggle, "active", Columns.TOGGLE);
        tree_view.append_column (column);

        var text = new Gtk.CellRendererText ();

        column = new Gtk.TreeViewColumn ();
        column.pack_start (text, true);
        column.add_attribute (text, "text", Columns.TEXT);
        tree_view.append_column (column);
 
        tree_view.set_headers_visible (false);
        tree_view.get_selection().mode = Gtk.SelectionMode.NONE;
 
        Gtk.TreeIter iter;
        var registry = new E.SourceRegistry.sync (null);
        foreach (var src in registry.list_sources(E.SOURCE_EXTENSION_CALENDAR)) {
            list_store.append (out iter);
            list_store.set (iter, Columns.TOGGLE, src.enabled, Columns.TEXT, src.dup_display_name ());
        }
        var container = (Gtk.Container) get_content_area ();
        container.add (tree_view);
    }
}