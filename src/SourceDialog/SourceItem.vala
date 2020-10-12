// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2015 Maya Developers (http://launchpad.net/maya)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class Calendar.SourceItem : Gtk.ListBoxRow {
    public signal void remove_request (E.Source source);
    public signal void edit_request (E.Source source);

    public string location { public get; private set; }
    public string label { public get; private set; }
    public E.Source source { public get; private set; }

    private Gtk.Stack stack;
    private Gtk.Grid info_grid;

    private Gtk.Button delete_button;
    private Gtk.Revealer delete_revealer;
    private Gtk.Button edit_button;
    private Gtk.Revealer edit_revealer;

    private Gtk.Label calendar_name_label;
    private Gtk.Label message_label;
    private Gtk.CheckButton visible_checkbutton;

    public SourceItem (E.Source source) {
        this.source = source;

        // Source widget
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        calendar_name_label = new Gtk.Label (source.dup_display_name ());
        calendar_name_label.xalign = 0;
        calendar_name_label.hexpand = true;

        label = source.dup_display_name ();
        location = Maya.Util.get_source_location (source);

        visible_checkbutton = new Gtk.CheckButton ();
        visible_checkbutton.active = cal.selected;
        visible_checkbutton.toggled.connect (() => {
            var calmodel = Calendar.EventStore.get_default ();
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

        style_calendar_color (cal.dup_color ());

        delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.MENU);
        delete_button.tooltip_text = source.removable ? _("Remove") : _("Not Removable");
        delete_button.relief = Gtk.ReliefStyle.NONE;
        delete_button.sensitive = source.removable;
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        delete_revealer = new Gtk.Revealer ();
        delete_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        delete_revealer.add (delete_button);
        delete_revealer.show_all ();
        delete_revealer.set_reveal_child (false);

        edit_button = new Gtk.Button.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU);
        edit_button.tooltip_text = source.writable ? _("Edit…"): _("Not Editable");
        edit_button.relief = Gtk.ReliefStyle.NONE;
        edit_button.sensitive = source.writable;

        edit_revealer = new Gtk.Revealer ();
        edit_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        edit_revealer.add (edit_button);
        edit_revealer.show_all ();
        edit_revealer.set_reveal_child (false);

        var calendar_grid = new Gtk.Grid ();
        calendar_grid.column_spacing = 6;
        calendar_grid.margin_start = 8;
        calendar_grid.margin_end = 6;
        calendar_grid.attach (visible_checkbutton, 0, 0, 1, 1);
        calendar_grid.attach (calendar_name_label, 2, 0, 1, 1);
        calendar_grid.attach (delete_revealer, 3, 0, 1, 1);
        calendar_grid.attach (edit_revealer, 4, 0, 1, 1);

        var calendar_event_box = new Gtk.EventBox ();
        calendar_event_box.add (calendar_grid);
        calendar_event_box.show ();

        var undo_button = new Gtk.Button.with_label (_("Undo"));
        undo_button.margin_end = 6;

        var close_button = new Gtk.Button.from_icon_name ("process-stop-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        close_button.relief = Gtk.ReliefStyle.NONE;

        message_label = new Gtk.Label (_("\"%s\" removed").printf (source.display_name));
        message_label.hexpand = true;
        message_label.xalign = 0.0f;

        info_grid = new Gtk.Grid ();
        info_grid.column_spacing = 12;
        info_grid.row_spacing = 6;
        info_grid.add (close_button);
        info_grid.add (message_label);
        info_grid.add (undo_button);

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.OVER_RIGHT_LEFT;
        stack.add_named (info_grid, "info");
        stack.add_named (calendar_event_box, "calendar");
        stack.visible_child_name = "calendar";

        add (stack);

        close_button.clicked.connect (() => {
            hide ();
            destroy ();
        });

        delete_button.clicked.connect (() => {remove_request (source);});

        edit_button.clicked.connect (() => {edit_request (source);});

        undo_button.clicked.connect (() => {
            Calendar.EventStore.get_default ().restore_calendar ();
            stack.set_visible_child_name ("calendar");
        });

        calendar_event_box.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        calendar_event_box.enter_notify_event.connect ((event) => {
            delete_revealer.set_reveal_child (true);
            edit_revealer.set_reveal_child (true);
            return false;
        });

        calendar_event_box.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR)
                return false;

            delete_revealer.set_reveal_child (false);
            edit_revealer.set_reveal_child (false);
            return false;
        });

        source.changed.connect (source_has_changed);
    }

    private void style_calendar_color (string color) {
        var css_color = "@define-color colorAccent %s;".printf (color);

        var style_provider = new Gtk.CssProvider ();

        try {
            style_provider.load_from_data (css_color, css_color.length);
            visible_checkbutton.get_style_context ().add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, css_color);
        }
    }

    public void source_has_changed () {
        calendar_name_label.label = source.dup_display_name ();
        message_label.label = _("\"%s\" removed").printf (source.display_name);

        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        style_calendar_color (cal.dup_color ());

        visible_checkbutton.active = cal.selected;
    }

    public void show_calendar_removed () {
        stack.set_visible_child_name ("info");
    }
}
