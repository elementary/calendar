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
    private Gee.Collection<PlacementWidget> backend_widgets;
    private Gtk.Grid main_grid;
    private Gtk.Grid general_grid;
    private Gee.HashMap<string, bool> widgets_checked;
    private Gtk.Button create_button;
    private E.Source source;

    public SourceDialog (E.Source? source = null) {
        widgets_checked = new Gee.HashMap<string, bool> (null, null);
        
        if (source == null) {
            title = _("Add Calendar");
            event_type = EventType.ADD;
        } else {
            title = _("Edit Calendar");
            this.source = source;
        }

        // Dialog properties
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
        type_hint = Gdk.WindowTypeHint.DIALOG;
        transient_for = ((Maya.Application)GLib.Application.get_default ()).window;

        main_grid = new Gtk.Grid ();
        main_grid.set_row_spacing (6);
        main_grid.set_column_spacing (12);
        
        general_grid = new Gtk.Grid ();
        general_grid.margin_left = 12;
        general_grid.margin_right = 12;
        general_grid.margin_top = 12;
        general_grid.margin_bottom = 12;
        general_grid.set_row_spacing (6);
        general_grid.set_column_spacing (12);
        
        // Buttons
        
        var buttonbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        buttonbox.set_layout (Gtk.ButtonBoxStyle.END);
        

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
        
        // Name
        
        var name_label = new Gtk.Label (_("Name:"));
        name_label.xalign = 1;
        name_entry = new Gtk.Entry ();
        name_entry.placeholder_text = _("Calendar Name");
        name_entry.changed.connect (() => {check_can_validate ();});
        if (event_type == EventType.EDIT) {
            name_entry.text = source.display_name;
        }
        
        // Type Combobox
        Gtk.ListStore list_store = new Gtk.ListStore (2, typeof (string), typeof (Backend));
        Gtk.TreeIter iter;
        int number = 0;
        int i =0;
        foreach (var backend in backends_manager.backends) {
            list_store.append (out iter);
            list_store.set (iter, 0, backend.get_name (), 1, backend);
            if (event_type == EventType.EDIT) {
                if (backend.get_uid () == source.dup_parent ()) {
                    number = i;
                }
            }
            i++;
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
            remove_backend_widgets ();
            backend_widgets = ((Backend)backend).get_new_calendar_widget (source);
            add_backend_widgets ();
        });
        
        type_combobox.set_active (number);
        
        var type_label = new Gtk.Label (_("Type:"));
        type_label.expand = true;
        type_label.xalign = 1;
        
        if (backends_manager.backends.size == 1) {
            type_combobox.no_show_all = true;
            type_label.no_show_all = true;
        }
        
        if (event_type == EventType.EDIT) {
            type_combobox.sensitive = false;
        }
        
        // Color
        var rgba = Gdk.RGBA ();
        if (event_type == EventType.EDIT) {
            var cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            rgba.parse (cal.dup_color ());
        } else {
            rgba.red = 0.13;
            rgba.green = 0.42;
            rgba.blue = 0.70;
        }
        var color_label = new Gtk.Label (_("Color:"));
        color_label.xalign = 1;
        color_button = new Gtk.ColorButton.with_rgba (rgba);
        color_button.use_alpha = false;
        
        
        var check_button = new Gtk.CheckButton.with_label (_("Mark as default calendar"));

        check_button.toggled.connect (() => {
            set_as_default = !set_as_default;
        });

        main_grid.attach (type_label,    0, 0, 1, 1);
        main_grid.attach (type_combobox, 1, 0, 1, 1);
        main_grid.attach (name_label,    0, 1, 1, 1);
        main_grid.attach (name_entry,    1, 1, 1, 1);
        main_grid.attach (color_label,   0, 2, 1, 1);
        main_grid.attach (color_button,  1, 2, 1, 1);
        main_grid.attach (check_button,  1, 3, 1, 1);
        
        general_grid.attach (main_grid,  0, 0, 2, 1);
        general_grid.attach (buttonbox,  0, 1, 2, 1);
        
        this.add (general_grid);
        
        show_all ();
    }
    
    private void remove_backend_widgets () {
        if (backend_widgets == null)
            return;
        foreach (var widget in backend_widgets) {
            widget.widget.hide ();
        }
        backend_widgets.clear ();
    }
    
    private void add_backend_widgets () {
        foreach (var widget in backend_widgets) {
            main_grid.attach (widget.widget, widget.column, 4 + widget.row, 1, 1);
            if (widget.needed == true && widget.widget is Gtk.Entry) {
                var entry = widget.widget as Gtk.Entry;
                entry.changed.connect (() => {entry_changed (widget);});
                widgets_checked.set (widget.ref_name, ((Gtk.Entry)widget.widget).text != "");
            }
            widget.widget.show ();
        }
        check_can_validate ();
    }
    
    private void entry_changed (PlacementWidget widget) {
        widgets_checked.unset (widget.ref_name);
        widgets_checked.set (widget.ref_name, ((Gtk.Entry)widget.widget).text != "");
        check_can_validate ();
    }
    
    private void check_can_validate () {
        bool result = true;
        foreach (var valid in widgets_checked.values) {
            if (valid == false) {
                result = false;
                break;
            }
        }
        if (result == true && name_entry.text != "") {
            create_button.sensitive = true;
        } else {
            create_button.sensitive = false;
        }
    }

    //--- Public Methods ---//
    
    
    public void save () {
        
        if (event_type == EventType.ADD) {
            current_backend.add_new_calendar (name_entry.text, Util.get_hexa_color (color_button.rgba), set_as_default, backend_widgets);
            this.destroy();
        } else {
            current_backend.modify_calendar (name_entry.text, Util.get_hexa_color (color_button.rgba), set_as_default, backend_widgets, source);
            this.destroy();
        }
    }
}