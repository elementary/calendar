//
//  Copyright (C) 2011-2012 Jaap Broekhuizen
//
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

#if USE_GRANITE_DECORATED_WINDOW
public class Maya.View.SourceDialog : Granite.Widgets.LightWindow {
#else
public class Maya.View.SourceDialog : Gtk.Window {
#endif

    public EventType event_type { get; private set; default=EventType.EDIT;}
    
    private Gtk.Entry name_entry;
    private Gtk.ColorButton color_button;
    private bool set_as_default = false;
    private Backend current_backend;
    private Gtk.Widget backend_widget;

    public SourceDialog (E.Source? source = null) {
        if (source == null) {
            title = _("Add Calendar");
            event_type = EventType.ADD;
        } else {
            title = _("Edit Calendar");
        }

        // Dialog properties
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
        type_hint = Gdk.WindowTypeHint.DIALOG;
        transient_for = app.window;

        var main_grid = new Gtk.Grid ();
        main_grid.margin_left = 12;
        main_grid.margin_right = 12;
        main_grid.margin_top = 12;
        main_grid.margin_bottom = 12;
        main_grid.set_row_spacing (6);
        main_grid.set_column_spacing (12);

        // Type Combobox
        Gtk.ListStore list_store = new Gtk.ListStore (2, typeof (string), typeof (Backend));
        Gtk.TreeIter iter;
        foreach (var backend in backends_manager.backends) {
            list_store.append (out iter);
            list_store.set (iter, 0, backend.get_name (), 1, backend);
        }
        
        var type_combobox = new Gtk.ComboBox.with_model (list_store);

        Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
        type_combobox.pack_start (renderer, true);
        type_combobox.add_attribute (renderer, "text", 0);

        type_combobox.changed.connect (() => {
            GLib.Value backend;
            
            Gtk.TreeIter b_iter;
            type_combobox.get_active_iter (out b_iter);
            list_store.get_value (b_iter, 1, out backend);
            current_backend = ((Backend)backend);
            if (backend_widget != null) {
                backend_widget.hide ();
            }
            backend_widget = ((Backend)backend).get_new_calendar_widget ();
            main_grid.attach (backend_widget,  0, 4, 2, 1);
            backend_widget.show ();
        });
        type_combobox.set_active (0);
        
        var type_label = new Gtk.Label (_("Type:"));
        
        if (backends_manager.backends.size == 1) {
            type_combobox.no_show_all = true;
            type_label.no_show_all = true;
        }
        
        // Name
        
        var name_label = new Gtk.Label (_("Name:"));
        name_entry = new Gtk.Entry ();
        
        // Color
        
        var color_label = new Gtk.Label (_("Color:"));
        color_button = new Gtk.ColorButton ();
        color_button.use_alpha = false;
        
        
        var check_button = new Gtk.CheckButton.with_label (_("Mark as default calendar"));

        check_button.toggled.connect (() => {
            set_as_default = !set_as_default;
        });
        
        // Buttons
        
        var buttonbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        buttonbox.set_layout (Gtk.ButtonBoxStyle.END);
        
        Gtk.Button create_button;

        var cancel_button = new Gtk.Button.from_stock (Gtk.Stock.CANCEL);
        if (event_type == EventType.ADD) {
            create_button = new Gtk.Button.with_label (_("Create Calendar"));
        } else {
            create_button = new Gtk.Button.from_stock (Gtk.Stock.SAVE);
        }

        create_button.clicked.connect (save);
        cancel_button.clicked.connect (() => {this.destroy();});

        buttonbox.pack_end (cancel_button);
        buttonbox.pack_end (create_button);

        main_grid.attach (type_label,    0, 0, 1, 1);
        main_grid.attach (type_combobox, 1, 0, 1, 1);
        main_grid.attach (name_label,    0, 1, 1, 1);
        main_grid.attach (name_entry,    1, 1, 1, 1);
        main_grid.attach (color_label,   0, 2, 1, 1);
        main_grid.attach (color_button,  1, 2, 1, 1);
        main_grid.attach (check_button,  0, 3, 2, 1);
        main_grid.attach (buttonbox,  0, 5, 2, 1);
        this.add (main_grid);
        
        show_all ();
    }

    //--- Public Methods ---//
    
    
    public void save () {
        
        if (event_type == EventType.ADD) {
            current_backend.add_new_calendar (name_entry.text, Util.get_hexa_color (color_button.rgba), backend_widget);
            this.destroy();
        } else {
            
        }
    }
}
