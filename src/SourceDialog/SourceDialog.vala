// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2020 elementary, Inc. (https://elementary.io)
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
 * Authored by: Jaap Broekhuizen
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.SourceDialog : Granite.Dialog {
    public EventType event_type { get; private set; default=EventType.EDIT;}

    private Gtk.Box main_box;
    private Gtk.Entry name_entry;
    private string hex_color = "#da3d41";
    private Backend current_backend;
    private Gee.Collection<PlacementWidget> backend_widgets;
    private Gee.HashMap<string, bool> widgets_checked;
    private Gtk.Button create_button;
    private Gtk.ComboBox type_combobox;
    private Gtk.ListStore list_store;
    private Gtk.CheckButton is_default_check;
    private E.Source source = null;

    private Gtk.CheckButton color_button_blue;
    private Gtk.CheckButton color_button_mint;
    private Gtk.CheckButton color_button_green;
    private Gtk.CheckButton color_button_yellow;
    private Gtk.CheckButton color_button_orange;
    private Gtk.CheckButton color_button_red;
    private Gtk.CheckButton color_button_pink;
    private Gtk.CheckButton color_button_purple;
    private Gtk.CheckButton color_button_brown;
    private Gtk.CheckButton color_button_slate;
    private Gtk.CheckButton color_button_none;

    public signal void go_back ();

    construct {
        widgets_checked = new Gee.HashMap<string, bool> (null, null);

        var cancel_button = (Gtk.Button) add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        create_button = (Gtk.Button) add_button (_("Create") , Gtk.ResponseType.ACCEPT);

        create_button.clicked.connect (save);
        cancel_button.clicked.connect (() => go_back ());

        name_entry = new Gtk.Entry () {
            placeholder_text = _("e.g. “Work” or “Personal”")
        };
        name_entry.changed.connect (check_can_validate);

        var name_label = new Granite.HeaderLabel (_("Calendar Name")) {
            mnemonic_widget = name_entry
        };

        var name_box = new Gtk.Box (VERTICAL, 0) {
            margin_bottom = 12
        };
        name_box.add (name_label);
        name_box.add (name_entry);

        list_store = new Gtk.ListStore (2, typeof (string), typeof (Backend));

        var renderer = new Gtk.CellRendererText ();

        type_combobox = new Gtk.ComboBox.with_model (list_store);
        type_combobox.hexpand = true;
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

        var type_label = new Granite.HeaderLabel (_("Type")) {
            mnemonic_widget = type_combobox
        };

        var type_box = new Gtk.Box (VERTICAL, 0) {
            margin_bottom = 12
        };
        type_box.add (type_label);
        type_box.add (type_combobox);

        Gtk.TreeIter iter;
        var backends_manager = BackendsManager.get_default ();
        foreach (var backend in backends_manager.backends) {
            list_store.append (out iter);
            list_store.set (iter, 0, backend.get_name (), 1, backend);
        }

        if (backends_manager.backends.size <= 1) {
            type_combobox.no_show_all = true;
            type_label.no_show_all = true;
        }

        type_combobox.set_active (0);

        color_button_blue = new Gtk.CheckButton (null) {
            tooltip_text = _("Blueberry")
        };
        color_button_blue.get_style_context ().add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
        color_button_blue.get_style_context ().add_class ("blue");

        color_button_mint = new Gtk.CheckButton (null) {
            group = color_button_blue,
            tooltip_text = _("Mint")
        };
        color_button_mint.get_style_context ().add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
        color_button_mint.get_style_context ().add_class ("mint");

        color_button_green = new Gtk.CheckButton (null) {
            group = color_button_blue,
            tooltip_text = _("Lime")
        };
        color_button_green.get_style_context ().add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
        color_button_green.get_style_context ().add_class ("green");

        color_button_yellow = new Gtk.CheckButton (null) {
            group = color_button_blue,
            tooltip_text = _("Banana")
        };
        color_button_yellow.get_style_context ().add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
        color_button_yellow.get_style_context ().add_class ("yellow");

        color_button_orange = new Gtk.CheckButton (null) {
            group = color_button_blue,
            tooltip_text = _("Orange")
        };
        color_button_orange.get_style_context ().add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
        color_button_orange.get_style_context ().add_class ("orange");

        color_button_red = new Gtk.CheckButton (null) {
            group = color_button_blue,
            tooltip_text = _("Strawberry")
        };
        color_button_red.get_style_context ().add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
        color_button_red.get_style_context ().add_class ("red");

        color_button_pink = new Gtk.CheckButton (null) {
            group = color_button_blue,
            tooltip_text = _("Bubblegum")
        };
        color_button_pink.get_style_context ().add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
        color_button_pink.get_style_context ().add_class ("pink");

        color_button_purple = new Gtk.CheckButton (null) {
            group = color_button_blue,
            tooltip_text = _("Grape")
        };
        color_button_purple.get_style_context ().add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
        color_button_purple.get_style_context ().add_class ("purple");

        color_button_brown = new Gtk.CheckButton (null) {
            group = color_button_blue,
            tooltip_text = _("Cocoa")
        };
        color_button_brown.get_style_context ().add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
        color_button_brown.get_style_context ().add_class ("brown");

        color_button_slate = new Gtk.CheckButton (null) {
            group = color_button_blue,
            tooltip_text = _("Slate")
        };
        color_button_slate.get_style_context ().add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
        color_button_slate.get_style_context ().add_class ("slate");

        color_button_none = new Gtk.CheckButton (null) {
            group = color_button_blue
        };

        var color_button_box = new Gtk.Box (HORIZONTAL, 6);
        color_button_box.add (color_button_blue);
        color_button_box.add (color_button_mint);
        color_button_box.add (color_button_green);
        color_button_box.add (color_button_yellow);
        color_button_box.add (color_button_orange);
        color_button_box.add (color_button_red);
        color_button_box.add (color_button_pink);
        color_button_box.add (color_button_purple);
        color_button_box.add (color_button_brown);
        color_button_box.add (color_button_slate);

        var color_label = new Granite.HeaderLabel (_("Color")) {
            mnemonic_widget = color_button_box
        };

        var color_box = new Gtk.Box (VERTICAL, 0) {
            margin_bottom = 12
        };
        color_box.add (color_label);
        color_box.add (color_button_box);

        is_default_check = new Gtk.CheckButton.with_label (_("Mark as default calendar")) {
            margin_bottom = 12
        };

        color_button_red.toggled.connect (() => {
            hex_color = "#da3d41";
        });

        color_button_orange.toggled.connect (() => {
            hex_color = "#f37329";
        });

        color_button_yellow.toggled.connect (() => {
            hex_color = "#e6a92a";
        });

        color_button_green.toggled.connect (() => {
            hex_color = "#81c837";
        });

        color_button_mint.toggled.connect (() => {
            hex_color = "#0e9a83";
        });

        color_button_blue.toggled.connect (() => {
            hex_color = "#3689e6";
        });

        color_button_purple.toggled.connect (() => {
            hex_color = "#a56de2";
        });

        color_button_pink.toggled.connect (() => {
            hex_color = "#de3e80";
        });

        color_button_brown.toggled.connect (() => {
            hex_color = "#8a715e";
        });

        color_button_slate.toggled.connect (() => {
            hex_color = "#667885";
        });

        main_box = new Gtk.Box (VERTICAL, 0) {
            margin_end = 12,
            margin_start = 12,
            vexpand = true
        };
        main_box.add (type_box);
        main_box.add (name_box);
        main_box.add (color_box);
        main_box.add (is_default_check);
        main_box.show_all ();

        get_content_area ().add (main_box);
    }

    public void set_source (E.Source? source = null) {
        this.source = source;
        if (source == null) {
            event_type = EventType.ADD;
            name_entry.text = "";
            type_combobox.sensitive = true;
            color_button_red.active = true;
            create_button.set_label (_("Create Calendar"));
            is_default_check.sensitive = true;
            is_default_check.active = false;
        } else {
            event_type = EventType.EDIT;
            create_button.set_label (_("Save"));
            name_entry.text = source.display_name;
            type_combobox.sensitive = false;
            type_combobox.set_active (0);
            list_store.foreach (tree_foreach);

            try {
                var registry = new E.SourceRegistry.sync (null);
                var source_is_default = source.equal (registry.default_calendar);
                var source_is_readonly = Calendar.EventStore.get_default ().calclient_is_readonly (source);
                // Prevent source from being "unset" as default, which is undefined
                is_default_check.sensitive = !(source_is_default || source_is_readonly);
                is_default_check.active = source_is_default;
            } catch (GLib.Error error) {
                critical (error.message);
            }

            var cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            switch (cal.dup_color ()) {
                case "#da3d41":
                    color_button_red.active = true;
                    break;
                case "#f37329":
                    color_button_orange.active = true;
                    break;
                case "#e6a92a":
                    color_button_yellow.active = true;
                    break;
                case "#81c837":
                    color_button_green.active = true;
                    break;
                case "#0e9a83":
                    color_button_mint.active = true;
                    break;
                case "#3689e6":
                    color_button_blue.active = true;
                    break;
                case "#a56de2":
                    color_button_purple.active = true;
                    break;
                case "#de3e80":
                    color_button_pink.active = true;
                    break;
                case "#8a715e":
                    color_button_brown.active = true;
                    break;
                case "#667885":
                    color_button_slate.active = true;
                    break;
                default:
                    color_button_none.active = true;
                    hex_color = cal.dup_color ();
                    break;
            }

        }
    }

    private bool tree_foreach (Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter iter) {
        GLib.Value backend;
        list_store.get_value (iter, 1, out backend);
        var current_backend = ((Backend)backend);
        if (current_backend.get_uid () == source.dup_parent ()) {
            type_combobox.set_active_iter (iter);
            type_combobox.sensitive = true;
            return true;
        }

        return false;
    }

    private void remove_backend_widgets () {
        if (backend_widgets == null)
            return;

        foreach (var widget in backend_widgets) {
            widget.widget.hide ();
            widget.widget.destroy ();
        }

        backend_widgets.clear ();
    }

    private void add_backend_widgets () {
        widgets_checked.clear ();
        foreach (var widget in backend_widgets) {

            if (!(widget.widget is Granite.HeaderLabel)) {
                widget.widget.margin_bottom = 12;
            }

            main_box.add (widget.widget);

            if (widget.needed == true && widget.widget is Gtk.Entry) {
                var entry = widget.widget as Gtk.Entry;
                entry.changed.connect (() => {entry_changed (widget);});
                widgets_checked.set (widget.ref_name, ((Gtk.Entry)widget.widget).text != "");
            }
        }

        main_box.show_all ();
        check_can_validate ();
    }

    private void entry_changed (PlacementWidget widget) {
        widgets_checked.unset (widget.ref_name);
        widgets_checked.set (widget.ref_name, ((Gtk.Entry)widget.widget).text.chug ().char_count () > 0);
        check_can_validate ();
    }

    private void check_can_validate () {
        foreach (var valid in widgets_checked.values) {
            if (valid == false) {
                create_button.sensitive = false;
                return;
            }
        }

        if (name_entry.text != "") {
            create_button.sensitive = true;
        }
    }

    public void save () {
        if (event_type == EventType.ADD) {
            current_backend.add_new_calendar (name_entry.text, hex_color, is_default_check.active, backend_widgets);
            go_back ();
        } else {
            current_backend.modify_calendar (name_entry.text, hex_color, is_default_check.active, backend_widgets, source);
            go_back ();
        }
    }
}
