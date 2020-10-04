// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2018 elementary, Inc. (https://elementary.io)
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

public class Maya.View.SourceDialog : Gtk.Grid {
    public EventType event_type { get; private set; default=EventType.EDIT;}

    private Gtk.Entry name_entry;
    private string hex_color = "#da3d41";
    private Backend current_backend;
    private Gee.Collection<PlacementWidget> backend_widgets;
    private Gtk.Grid main_grid;
    private Gee.HashMap<string, bool> widgets_checked;
    private Gtk.Button create_button;
    private Gtk.ComboBox type_combobox;
    private Gtk.ListStore list_store;
    private Gtk.CheckButton is_default_check;
    private E.Source source = null;

    private Gtk.RadioButton color_button_red;
    private Gtk.RadioButton color_button_orange;
    private Gtk.RadioButton color_button_yellow;
    private Gtk.RadioButton color_button_green;
    private Gtk.RadioButton color_button_blue;
    private Gtk.RadioButton color_button_purple;
    private Gtk.RadioButton color_button_brown;
    private Gtk.RadioButton color_button_slate;
    private Gtk.RadioButton color_button_none;

    public signal void go_back ();

    construct {
        widgets_checked = new Gee.HashMap<string, bool> (null, null);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        create_button = new Gtk.Button.with_label (_("Create"));

        create_button.clicked.connect (save);
        cancel_button.clicked.connect (() => go_back ());

        var buttonbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        buttonbox.layout_style = Gtk.ButtonBoxStyle.END;
        buttonbox.spacing = 6;
        buttonbox.pack_end (cancel_button);
        buttonbox.pack_end (create_button);

        var name_label = new Gtk.Label (_("Name:"));
        name_label.xalign = 1;

        name_entry = new Gtk.Entry ();
        name_entry.placeholder_text = _("Calendar Name");
        name_entry.changed.connect (() => {check_can_validate ();});

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

        var type_label = new Gtk.Label (_("Type:"));
        type_label.xalign = 1.0f;

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

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/calendar/ColorButton.css");

        var color_label = new Gtk.Label (_("Color:"));
        color_label.xalign = 1;

        color_button_red = new Gtk.RadioButton (null);

        var color_button_red_context = color_button_red.get_style_context ();
        color_button_red_context.add_class ("color-button");
        color_button_red_context.add_class ("red");
        color_button_red_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        color_button_orange = new Gtk.RadioButton.from_widget (color_button_red);

        var color_button_orange_context = color_button_orange.get_style_context ();
        color_button_orange_context.add_class ("color-button");
        color_button_orange_context.add_class ("orange");
        color_button_orange_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        color_button_yellow = new Gtk.RadioButton.from_widget (color_button_red);

        var color_button_yellow_context = color_button_yellow.get_style_context ();
        color_button_yellow_context.add_class ("color-button");
        color_button_yellow_context.add_class ("yellow");
        color_button_yellow_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        color_button_green = new Gtk.RadioButton.from_widget (color_button_red);

        var color_button_green_context = color_button_green.get_style_context ();
        color_button_green_context.add_class ("color-button");
        color_button_green_context.add_class ("green");
        color_button_green_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        color_button_blue = new Gtk.RadioButton.from_widget (color_button_red);

        var color_button_blue_context = color_button_blue.get_style_context ();
        color_button_blue_context.add_class ("color-button");
        color_button_blue_context.add_class ("blue");
        color_button_blue_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        color_button_purple = new Gtk.RadioButton.from_widget (color_button_red);

        var color_button_purple_context = color_button_purple.get_style_context ();
        color_button_purple_context.add_class ("color-button");
        color_button_purple_context.add_class ("purple");
        color_button_purple_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        color_button_brown = new Gtk.RadioButton.from_widget (color_button_red);

        var color_button_brown_context = color_button_brown.get_style_context ();
        color_button_brown_context.add_class ("color-button");
        color_button_brown_context.add_class ("brown");
        color_button_brown_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        color_button_slate = new Gtk.RadioButton.from_widget (color_button_red);

        var color_button_slate_context = color_button_slate.get_style_context ();
        color_button_slate_context.add_class ("color-button");
        color_button_slate_context.add_class ("slate");
        color_button_slate_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        color_button_none = new Gtk.RadioButton.from_widget (color_button_red);

        var color_grid = new Gtk.Grid ();
        color_grid.column_spacing = 12;
        color_grid.add (color_button_red);
        color_grid.add (color_button_orange);
        color_grid.add (color_button_yellow);
        color_grid.add (color_button_green);
        color_grid.add (color_button_blue);
        color_grid.add (color_button_purple);
        color_grid.add (color_button_brown);
        color_grid.add (color_button_slate);

        is_default_check = new Gtk.CheckButton.with_label (_("Mark as default calendar"));

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

        color_button_blue.toggled.connect (() => {
            hex_color = "#3689e6";
        });

        color_button_purple.toggled.connect (() => {
            hex_color = "#a56de2";
        });

        color_button_brown.toggled.connect (() => {
            hex_color = "#8a715e";
        });

        color_button_slate.toggled.connect (() => {
            hex_color = "#667885";
        });

        main_grid = new Gtk.Grid ();
        main_grid.row_spacing = 6;
        main_grid.column_spacing = 12;
        main_grid.attach (type_label, 0, 0);
        main_grid.attach (type_combobox, 1, 0);
        main_grid.attach (name_label, 0, 1);
        main_grid.attach (name_entry, 1, 1);
        main_grid.attach (color_label, 0, 2);
        main_grid.attach (color_grid, 1, 2);
        main_grid.attach (is_default_check, 1, 3);

        margin = 12;
        margin_bottom = 8;
        row_spacing = 24;
        attach (main_grid, 0, 0);
        attach (buttonbox, 0, 1);

        show_all ();
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
                // Prevent source from being "unset" as default, which is undefined
                is_default_check.sensitive = !source_is_default;
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
                case "#3689e6":
                    color_button_blue.active = true;
                    break;
                case "#a56de2":
                    color_button_purple.active = true;
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
