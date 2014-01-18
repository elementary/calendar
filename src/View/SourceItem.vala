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

public class Maya.View.SourceItem : Gtk.EventBox {
    
    private E.Source source;
    
    private Gtk.Revealer revealer;
    private Gtk.Revealer info_revealer;
    private Model.CalendarModel calmodel;
    private Gtk.Grid main_grid;
    
    private Gtk.Button delete_button;
    private Gtk.Button edit_button;
    
    private Gtk.Label calendar_name_label;
    private Gtk.Label backend_label;
    private Gtk.Label calendar_color_label;
    private Gtk.CheckButton visible_checkbutton;
    
    public signal void remove_request (E.Source source);
    public signal void edit_request (E.Source source);
    
    public SourceItem (E.Source source, Model.CalendarModel calmodel) {
        
        this.source = source;
        this.calmodel = calmodel;
        
        main_grid = new Gtk.Grid ();
        
        // Source widget
        
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
        revealer = new Gtk.Revealer ();
        revealer.set_reveal_child (true);
        
        var revealer_grid = new Gtk.Grid ();
        revealer_grid.column_spacing = 6;
        revealer_grid.row_spacing = 12;
        
        calendar_name_label = new Gtk.Label (source.dup_display_name ());
        calendar_name_label.set_markup ("<b>%s</b>".printf (source.dup_display_name ()));
        calendar_name_label.xalign = 0;
        
        Maya.Backend selected_backend = null;
        foreach (var backend in backends_manager.backends) {
            if (source.dup_parent () == backend.get_uid ()) {
                selected_backend = backend;
                break;
            }
        }
        if (selected_backend == null) {
            backend_label = new Gtk.Label ("");
        } else {
            backend_label = new Gtk.Label (selected_backend.get_name ());
        }
        backend_label.hexpand = true;
        backend_label.xalign = 0;
        
        calendar_color_label = new Gtk.Label ("  ");
        var color = Gdk.RGBA ();
        color.parse (cal.dup_color());
        calendar_color_label.override_background_color (Gtk.StateFlags.NORMAL, color);
        
        visible_checkbutton = new Gtk.CheckButton ();
        visible_checkbutton.active = cal.selected;
        visible_checkbutton.toggled.connect (() => {
            if (visible_checkbutton.active == true) {
                calmodel.add_source (source);
            } else {
                calmodel.remove_source (source);
            }
            cal.set_selected (visible_checkbutton.active);
            try {
                source.write_sync ();
            } catch (GLib.Error error) {
                critical (error.message);
            }
        });
        
        delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.MENU);
        delete_button.set_tooltip_text (_("Remove"));
        delete_button.clicked.connect (() => {remove_request (source);});
        delete_button.relief = Gtk.ReliefStyle.NONE;
        delete_button.no_show_all = true;
        
        edit_button = new Gtk.Button.from_icon_name ("document-properties-symbolic", Gtk.IconSize.MENU);
        edit_button.set_tooltip_text (_("Edit…"));
        edit_button.clicked.connect (() => {edit_request (source);});
        edit_button.relief = Gtk.ReliefStyle.NONE;
        edit_button.no_show_all = true;
        
        revealer_grid.attach (visible_checkbutton, 0, 0, 1, 2);
        revealer_grid.attach (calendar_color_label, 1, 0, 1, 2);
        revealer_grid.attach (calendar_name_label, 2, 0, 1, 1);
        revealer_grid.attach (backend_label, 3, 0, 1, 1);
        revealer_grid.attach (delete_button, 4, 0, 1, 2);
        revealer_grid.attach (edit_button, 5, 0, 1, 2);
        
        revealer.add (revealer_grid);
        
        // Info bar
        info_revealer = new Gtk.Revealer ();
        info_revealer.no_show_all = true;
        var info_revealer_grid = new Gtk.Grid ();
        info_revealer_grid.column_spacing = 6;
        info_revealer_grid.row_spacing = 12;
        info_revealer.add (info_revealer_grid);
        var undo_button = new Gtk.Button.with_label (_("Undo"));
        undo_button.clicked.connect (() => {
            revealer.show ();
            calmodel.restore_calendar ();
            revealer.set_reveal_child (true);
            info_revealer.set_reveal_child (false);
            info_revealer.hide ();
        });
        var close_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        close_button.relief = Gtk.ReliefStyle.NONE;
        close_button.clicked.connect (() => {
            info_revealer.set_reveal_child (false);
            info_revealer.hide ();
            hide ();
            destroy ();
        });
        var message_label = new Gtk.Label (_("Calendar \"%s\" removed.").printf (source.display_name));
        message_label.hexpand = true;
        message_label.xalign = 0;
        info_revealer_grid.attach (message_label, 0, 0, 1, 1);
        info_revealer_grid.attach (undo_button, 1, 0, 1, 1);
        info_revealer_grid.attach (close_button, 2, 0, 1, 1);
        
        main_grid.attach (info_revealer, 0, 0, 1, 1);
        main_grid.attach (revealer, 0, 1, 1, 1);
        add (main_grid);
        
        add_events (Gdk.EventMask.ENTER_NOTIFY_MASK|Gdk.EventMask.LEAVE_NOTIFY_MASK);
        enter_notify_event.connect ((event) => {
            delete_button.visible = true;
            edit_button.visible = true;
            return false;
        });
        leave_notify_event.connect_after ((event) => {
            delete_button.visible = false;
            edit_button.visible = false;
            return false;
        });
    }
    
    // We need a custom one because the buttons are hidden if the calendar is not shown.
    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        base.get_preferred_width (out minimum_width, out natural_width);
        int total_natural_width = 0;
        int _minimum_width;
        int _natural_width;
        if (edit_button.visible == false && info_revealer.visible == false) {
            edit_button.show ();
            edit_button.get_preferred_width (out _minimum_width, out _natural_width);
            edit_button.hide ();
            // +6 because the grid has a 6px margin between every columns
            total_natural_width = total_natural_width + _natural_width + 6;
        }
        if (delete_button.visible == false && info_revealer.visible == false) {
            delete_button.show ();
            delete_button.get_preferred_width (out _minimum_width, out _natural_width);
            delete_button.hide ();
            // +6 because the grid has a 6px margin between every columns
            total_natural_width = total_natural_width + _natural_width + 6;
        }
        minimum_width = minimum_width + total_natural_width;
        natural_width = natural_width + total_natural_width;
    }
    
    public void source_has_changed () {
        
        calendar_name_label.set_markup ("<b>%s</b>".printf (source.dup_display_name ()));
        
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
        
        var color = Gdk.RGBA ();
        color.parse (cal.dup_color());
        calendar_color_label.override_background_color (Gtk.StateFlags.NORMAL, color);
        
        visible_checkbutton.active = cal.selected;
    }
    
    public void show_calendar_removed () {
        info_revealer.no_show_all = false;
        info_revealer.show_all ();
        revealer.set_reveal_child (false);
        revealer.hide ();
        info_revealer.set_reveal_child (true);
    }
    
}