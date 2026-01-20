/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2013-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class Calendar.SourceRow : Gtk.ListBoxRow {
    public signal void remove_request (E.Source source);
    public signal void edit_request (E.Source source);

    public string location { public get; private set; }
    public string label { public get; private set; }
    public E.Source source { public get; private set; }

    private Gtk.Stack stack;
    private Gtk.Box info_box;

    private Gtk.Button delete_button;
    private Gtk.Button edit_button;

    private Gtk.Label calendar_name_label;
    private Gtk.Label message_label;
    private Gtk.CheckButton visible_checkbutton;

    public SourceRow (E.Source source) {
        this.source = source;

        // Source widget
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        calendar_name_label = new Gtk.Label (source.dup_display_name ()) {
            hexpand = true,
            xalign = 0
        };

        label = source.dup_display_name ();
        location = Maya.Util.get_source_location (source);

        visible_checkbutton = new Gtk.CheckButton () {
            active = cal.selected
        };

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

        delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", MENU) {
            sensitive = source.removable,
            tooltip_text = source.removable ? _("Remove") : _("Not Removable")
        };

        edit_button = new Gtk.Button.from_icon_name ("edit-symbolic", MENU) {
            sensitive = source.writable,
            tooltip_text = source.writable ? _("Edit…"): _("Not Editable")
        };

        var calendar_box = new Gtk.Box (HORIZONTAL, 6) {
            margin_top = 3,
            margin_end = 12,
            margin_bottom = 3,
            margin_start = 12
        };
        calendar_box.append (visible_checkbutton);
        calendar_box.append (calendar_name_label);
        calendar_box.append (delete_button);
        calendar_box.append (edit_button);

        var undo_button = new Gtk.Button.with_label (_("Undo")) {
            margin_end = 6
        };

        var close_button = new Gtk.Button.from_icon_name ("process-stop-symbolic", SMALL_TOOLBAR) {
            relief = NONE
        };

        message_label = new Gtk.Label (_("\"%s\" removed").printf (source.display_name)) {
            hexpand = true,
            xalign = 0
        };

        info_box = new Gtk.Box (HORIZONTAL, 12);
        info_box.append (close_button);
        info_box.append (message_label);
        info_box.append (undo_button);

        stack = new Gtk.Stack () {
            transition_type = OVER_RIGHT_LEFT
        };
        stack.add (calendar_box);
        stack.add (info_box);
        stack.visible_child = calendar_box;

        add (stack);

        close_button.clicked.connect (() => {
            hide ();
            destroy ();
        });

        delete_button.clicked.connect (() => {remove_request (source);});

        edit_button.clicked.connect (() => {edit_request (source);});

        undo_button.clicked.connect (() => {
            Calendar.EventStore.get_default ().restore_calendar ();
            stack.visible_child = calendar_box;
        });

        source.changed.connect (source_has_changed);
    }

    private void style_calendar_color (string color) {
        var css_color = "@define-color accent_color %s;".printf (color.slice (0, 7));

        var style_provider = new Gtk.CssProvider ();

        try {
            style_provider.load_from_string (css_color);
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
        stack.visible_child = info_box;
    }
}
