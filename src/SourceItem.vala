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
    private Gtk.Grid main_grid;

    private Gtk.Button delete_button;
    private Gtk.Revealer delete_revealer;
    private Gtk.Button edit_button;
    private Gtk.Revealer edit_revealer;

    private Gtk.Label calendar_name_label;
    private Gtk.Label user_name_label;
    private Gtk.Label backend_label;
    private Gtk.Label calendar_color_label;
    private Gtk.CheckButton visible_checkbutton;

    public signal void remove_request (E.Source source);
    public signal void edit_request (E.Source source);

    public SourceItem (E.Source source) {
        this.source = source;

        main_grid = new Gtk.Grid ();

        // Source widget
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
        revealer = new Gtk.Revealer ();
        revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        revealer.set_reveal_child (true);

        var revealer_grid = new Gtk.Grid ();
        revealer_grid.column_spacing = 6;

        calendar_name_label = new Gtk.Label (source.dup_display_name ());
        calendar_name_label.set_markup ("<b>%s</b>".printf (GLib.Markup.escape_text (source.dup_display_name ())));
        calendar_name_label.xalign = 0;

        Maya.Backend selected_backend = null;
        foreach (var backend in BackendsManager.get_default ().backends) {
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

        if (source.has_extension (E.SOURCE_EXTENSION_AUTHENTICATION)) {
            var collection = (E.SourceAuthentication)source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
            if (collection.user != null) {
                user_name_label = new Gtk.Label (collection.user);
            }
        }

        if (user_name_label == null)
            user_name_label = new Gtk.Label (GLib.Environment.get_real_name ());

        user_name_label.xalign = 0;

        calendar_color_label = new Gtk.Label ("  ");
        var color = Gdk.RGBA ();
        color.parse (cal.dup_color());
        calendar_color_label.override_background_color (Gtk.StateFlags.NORMAL, color);

        visible_checkbutton = new Gtk.CheckButton ();
        visible_checkbutton.active = cal.selected;
        visible_checkbutton.toggled.connect (() => {
            var calmodel = Model.CalendarModel.get_default ();
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
        delete_revealer = new Gtk.Revealer ();
        delete_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        delete_revealer.add (delete_button);
        delete_revealer.show_all ();
        delete_revealer.set_reveal_child (false);

        edit_button = new Gtk.Button.from_icon_name ("document-properties-symbolic", Gtk.IconSize.MENU);
        edit_button.set_tooltip_text (_("Edit…"));
        edit_button.clicked.connect (() => {edit_request (source);});
        edit_button.relief = Gtk.ReliefStyle.NONE;
        edit_revealer = new Gtk.Revealer ();
        edit_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        edit_revealer.add (edit_button);
        edit_revealer.show_all ();
        edit_revealer.set_reveal_child (false);

        revealer_grid.attach (visible_checkbutton, 0, 0, 1, 2);
        revealer_grid.attach (calendar_color_label, 1, 0, 1, 2);
        revealer_grid.attach (calendar_name_label, 2, 0, 1, 1);
        revealer_grid.attach (backend_label, 3, 0, 1, 1);
        revealer_grid.attach (user_name_label, 2, 1, 2, 1);

        revealer_grid.attach (delete_revealer, 4, 0, 1, 2);
        revealer_grid.attach (edit_revealer, 5, 0, 1, 2);

        revealer.add (revealer_grid);

        // Info bar
        info_revealer = new Gtk.Revealer ();
        info_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        info_revealer.no_show_all = true;
        var info_revealer_grid = new Gtk.Grid ();
        info_revealer_grid.column_spacing = 6;
        info_revealer_grid.row_spacing = 12;
        info_revealer.add (info_revealer_grid);
        var undo_button = new Gtk.Button.with_label (_("Undo"));
        undo_button.clicked.connect (() => {
            revealer.show ();
            Model.CalendarModel.get_default ().restore_calendar ();
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
            if (source.removable == true)
                delete_revealer.set_reveal_child (true);
            if (source.writable == true)
                edit_revealer.set_reveal_child (true);
            return false;
        });

        leave_notify_event.connect ((event) => {
            if (source.removable == true)
                delete_revealer.set_reveal_child (false);
            if (source.writable == true)
                edit_revealer.set_reveal_child (false);
            return false;
        });

        source.changed.connect (source_has_changed);
    }

    public void source_has_changed () {
        calendar_name_label.set_markup ("<b>%s</b>".printf (GLib.Markup.escape_text (source.dup_display_name ())));
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