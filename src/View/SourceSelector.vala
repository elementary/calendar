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
    
    private Gtk.TreeStore tree_store;
    private Gtk.TreeView tree_view;
    private Gee.HashMap<string, Gtk.TreeIter?> iter_map;
    private Gtk.TreeIter default_iter;

    private enum Columns {
        TOGGLE,
        TEXT,
        COLOR,
        SOURCE,
        VISIBLE,
        DEFAULT,
        N_COLUMNS
    }
    
    public SourceSelector () {
        
        var main_grid = new Gtk.Grid ();
        
        tree_store = new Gtk.TreeStore (Columns.N_COLUMNS, typeof (bool), typeof (string), typeof (string), typeof (E.Source), typeof (bool), typeof (bool));
        tree_view = new Gtk.TreeView.with_model (tree_store);
        iter_map = new Gee.HashMap<string, Gtk.TreeIter?>();

        var toggle = new Gtk.CellRendererToggle ();
        toggle.toggled.connect ((toggle, path) => {
            var tree_path = new Gtk.TreePath.from_string (path);
            Gtk.TreeIter iter;
            tree_store.get_iter (out iter, tree_path);
            tree_store.set (iter, Columns.TOGGLE, !toggle.active);
            GLib.Value src;
            tree_store.get_value (iter, 3, out src);
            E.SourceCalendar cal = (E.SourceCalendar)((E.Source)src).get_extension (E.SOURCE_EXTENSION_CALENDAR);
            if (!cal.selected == true) {
                app.calmodel.add_source ((E.Source)src);
            } else {
                app.calmodel.remove_source ((E.Source)src);
            }
            cal.set_selected (!cal.selected);
            ((E.Source)src).write_sync ();
        });
        
        var radio = new Gtk.CellRendererToggle ();
        radio.radio = true;
        radio.toggled.connect ((toggle, path) => {
            var tree_path = new Gtk.TreePath.from_string (path);
            Gtk.TreeIter iter;
            tree_store.get_iter (out iter, tree_path);
            tree_store.set (default_iter, Columns.DEFAULT, false);
            tree_store.set (iter, Columns.DEFAULT, true);
            default_iter = iter;
            GLib.Value src;
            tree_store.get_value (iter, 3, out src);
            var registry = new E.SourceRegistry.sync (null);
            registry.default_calendar = (E.Source)src;
        });

        var text = new Gtk.CellRendererText ();
        var column = new Gtk.TreeViewColumn ();
        column.pack_start (text, true);
        column.add_attribute (text, "text", Columns.TEXT);
        column.add_attribute (text, "cell_background", Columns.COLOR);
        tree_view.append_column (column);

        column = new Gtk.TreeViewColumn ();
        column.pack_start (toggle, false);
        column.add_attribute (toggle, "active", Columns.TOGGLE);
        column.add_attribute (toggle, "cell_background", Columns.COLOR);
        column.add_attribute (toggle, "visible", Columns.VISIBLE);
        tree_view.append_column (column);

        column = new Gtk.TreeViewColumn ();
        column.pack_start (radio, false);
        column.add_attribute (radio, "active", Columns.DEFAULT);
        column.add_attribute (radio, "cell_background", Columns.COLOR);
        column.add_attribute (radio, "visible", Columns.VISIBLE);
        tree_view.append_column (column);
 
        tree_view.set_headers_visible (false);
        
        var backend_map = new Gee.HashMap<string, Gtk.TreeIter?>();
        
        var registry = new E.SourceRegistry.sync (null);
        var sources = registry.list_sources (E.SOURCE_EXTENSION_CALENDAR);
        
        foreach (var backend in backends_manager.backends) {
            Gtk.TreeIter? b_iter = null;
            foreach (var src in sources) {
                Gtk.TreeIter iter;
                if (src.parent == backend.get_uid ()) {
                    if (b_iter == null) {
                        tree_store.append (out b_iter, null);
                        tree_store.set (b_iter, Columns.TEXT, backend.get_name (), Columns.VISIBLE, false);
                        backend_map.set (backend.get_uid (), b_iter);
                    }
                    E.SourceCalendar cal = (E.SourceCalendar)src.get_extension (E.SOURCE_EXTENSION_CALENDAR);
                    tree_store.append (out iter, b_iter);
                    tree_store.set (iter, Columns.TOGGLE, cal.selected, Columns.TEXT, src.dup_display_name (), 
                                           Columns.COLOR, cal.dup_color(), Columns.SOURCE, src, 
                                           Columns.VISIBLE, true, Columns.DEFAULT, src.get_uid() == registry.default_calendar.uid);
                    if (src.get_uid() == registry.default_calendar.uid)
                        default_iter = iter;
                    iter_map.set (src.dup_uid (), iter);
                }
            }
        }
        
        Gtk.TreeIter? other = null;
        foreach (var src in sources) {
            if (!backend_map.keys.contains (src.parent)) {
                if (other == null) {
                    tree_store.append (out other, null);
                    tree_store.set (other, Columns.TEXT, _("Other"), Columns.VISIBLE, false);
                }
                Gtk.TreeIter iter;
                E.SourceCalendar cal = (E.SourceCalendar)src.get_extension (E.SOURCE_EXTENSION_CALENDAR);
                tree_store.append (out iter, other);
                tree_store.set (iter, Columns.TOGGLE, cal.selected, Columns.TEXT, src.dup_display_name (), 
                                           Columns.COLOR, cal.dup_color(), Columns.SOURCE, src, 
                                           Columns.VISIBLE, true, Columns.DEFAULT, src.get_uid() == registry.default_calendar.uid);
                if (src.get_uid() == registry.default_calendar.uid)
                    default_iter = iter;
                iter_map.set (src.dup_uid (), iter);
            }
        }
        
        tree_view.expand_all ();
        
        registry.source_removed.connect (source_removed);
        registry.source_added.connect (source_added);
        registry.source_disabled.connect (source_disabled);
        registry.source_enabled.connect (source_enabled);
        registry.source_changed.connect (source_changed);
        
        var scroll = new Gtk.ScrolledWindow (null, null);
        scroll.set_size_request (150, 150);
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        scroll.shadow_type = Gtk.ShadowType.IN;
        scroll.expand = true;
        scroll.add (tree_view);

        var toolbar = new Gtk.Toolbar();
        toolbar.set_style (Gtk.ToolbarStyle.ICONS);
        toolbar.get_style_context ().add_class ("inline-toolbar");
        toolbar.set_icon_size (Gtk.IconSize.SMALL_TOOLBAR);
        toolbar.set_show_arrow (false);
        toolbar.hexpand = true;

        scroll.get_style_context ().set_junction_sides (Gtk.JunctionSides.BOTTOM);
        toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        toolbar.get_style_context ().set_junction_sides (Gtk.JunctionSides.TOP);
        
        var add_button = new Gtk.ToolButton (null, _("Add…"));
        add_button.set_tooltip_text (_("Add…"));
        add_button.set_icon_name ("list-add-symbolic");
        add_button.clicked.connect (create_source);
        
        var remove_button = new Gtk.ToolButton (null, _("Remove"));
        remove_button.set_tooltip_text (_("Remove"));
        remove_button.set_icon_name ("list-remove-symbolic");
        remove_button.clicked.connect (remove_source);
        
        var edit_button = new Gtk.ToolButton (null, _("Edit…"));
        edit_button.set_tooltip_text (_("Edit…"));
        edit_button.set_icon_name ("document-properties-symbolic");
        edit_button.clicked.connect (edit_source);
        
        toolbar.insert (add_button, -1);
        toolbar.insert (remove_button, -1);
        toolbar.insert (edit_button, -1);
        
        var container = (Gtk.Container) get_content_area ();
        container.add (main_grid);
        main_grid.attach (scroll, 0, 0, 1, 1);
        main_grid.attach (toolbar, 0, 1, 1, 1);
    }
    
    private void source_removed (E.Source source) {
        if (iter_map.has_key (source.dup_uid ())) {
            var iter = iter_map.get (source.dup_uid ());
            tree_store.remove (ref iter);
            iter_map.unset (source.dup_uid (), null);
        }
    }
    
    private void source_added (E.Source source) {
        Gtk.TreeIter iter;
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
        tree_store.append (out iter, null);
        tree_store.set (iter, Columns.TOGGLE, cal.selected, Columns.TEXT, source.dup_display_name ());
        iter_map.set (source.dup_uid (), iter);
    }
    
    private void source_disabled (E.Source source) {
        
    }
    
    private void source_enabled (E.Source source) {
        
    }
    
    private void source_changed (E.Source source) {
        
    }
    
    private void create_source () {
        var dialog = new SourceDialog ();
        this.hide ();
        dialog.present ();
    }
    
    private void remove_source () {
    
    }
    
    private void edit_source () {
    
    }
    
}
