/*
 * Copyright 2014-2018 elementary, Inc. (https://elementary.io)
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

public class Maya.View.Widgets.CalendarButton : Gtk.MenuButton {
    private const string STYLE = """
        .cal-color {
            background-color: %s;
            border-radius: 50%;
        }
    """;

    public GLib.List<E.Source> sources;
    private E.Source _current_source;
    public E.Source current_source {
        get {
            return _current_source;
        }
        set {
            _current_source = value;
            calendar_grid.source = value;
            tooltip_text = "%s - %s".printf (calendar_grid.label, calendar_grid.location);
        }
    }

    private Gtk.SearchEntry search_entry;
    private CalendarGrid calendar_grid;

    construct {
        sources = new GLib.List<E.Source> ();
        var event_store = Calendar.Store.get_event_store ();
        foreach (var src in event_store.sources_list ()) {
            if (src.writable == true && src.enabled == true && event_store.source_is_readonly (src) == false) {
                sources.append (src);
            }
        }

        _current_source = event_store.source_get_default ();

        calendar_grid = new CalendarGrid (current_source);
        calendar_grid.halign = Gtk.Align.START;
        calendar_grid.hexpand = true;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.add (calendar_grid);
        grid.add (new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU));

        add (grid);

        current_source = event_store.source_get_default ();

        search_entry = new Gtk.SearchEntry ();
        search_entry.margin = 12;
        search_entry.margin_bottom = 6;
        search_entry.placeholder_text = _("Search Calendars");

        var placeholder = new Granite.Widgets.AlertView (
            _("No Results"),
            _("Try changing search terms."),
            ""
        );
        placeholder.show_all ();

        var list_box = new Gtk.ListBox ();
        list_box.activate_on_single_click = true;
        list_box.set_placeholder (placeholder);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled.add (list_box);
        scrolled.max_content_height = 300;
        scrolled.propagate_natural_height = true;

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_bottom = 6;
        popover_grid.attach (search_entry, 0, 0);
        popover_grid.attach (scrolled, 0, 1);
        popover_grid.show_all ();

        popover = new Gtk.Popover (this);
        popover.width_request = 310;
        popover.add (popover_grid);

        list_box.set_filter_func (filter_function);
        list_box.set_header_func (header_update_func);

        list_box.set_sort_func ((row1, row2) => {
            var child1 = (CalendarGrid)row1.get_child ();
            var child2 = (CalendarGrid)row2.get_child ();
            var comparison = child1.location.collate (child2.location);
            if (comparison == 0) {
                return child1.label.collate (child2.label);
            } else {
                return comparison;
            }
        });

        list_box.move_cursor.connect ((mvmt, count) => {
            var row = list_box.get_selected_row ().get_index ();
            if (row == 0 && count == -1) {
                search_entry.grab_focus ();
            }
        });

        list_box.row_activated.connect ((row) => {
            current_source = ((CalendarGrid)row.get_child ()).source;
            popover.popdown ();
        });

        popover.unmap.connect (() => {
            search_entry.text = "";
        });

        search_entry.activate.connect (() => {
            foreach (unowned Gtk.Widget child in list_box.get_children ()) {
                if (child.get_child_visible ()) {
                    ((Gtk.ListBoxRow) child).activate ();
                }
            }
        });

        search_entry.search_changed.connect (() => {
            list_box.invalidate_filter ();
            list_box.unselect_all ();
        });

        foreach (var source in sources) {
            var calgrid = new CalendarGrid (source);
            calgrid.margin = 6;
            calgrid.margin_start = 12;

            var row = new Gtk.ListBoxRow ();
            row.add (calgrid);
            row.show_all ();

            list_box.add (row);

            if (source.dup_uid () == current_source.dup_uid ()) {
                list_box.select_row (row);
            }
        }
    }

    [CCode (instance_pos = -1)]
    private bool filter_function (Gtk.ListBoxRow row) {
        var search_term = search_entry.text.down ();

        if (search_term in ((CalendarGrid)row.get_child ()).label.down ()) {
            return true;
        }

        return false;
    }

    private void header_update_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
        var row_location = ((CalendarGrid)row.get_child ()).location;
        if (before != null) {
            var before_row_location = ((CalendarGrid)before.get_child ()).location;
            if (before_row_location == row_location) {
                row.set_header (null);
                return;
            }
        }

        var header = new Granite.HeaderLabel (row_location);
        header.margin = 6;
        header.margin_bottom = 0;

        row.set_header (header);

        header.show_all ();
        if (before == null) {
            header.margin_top = 0;
        }
    }

    public class CalendarGrid : Gtk.Grid {
        public string label { public get; private set; }
        public string location { public get; private set; }
        private E.Source _source;
        public E.Source source {
            get {
                return _source;
            }

            set {
                _source = value;
                apply_source ();
            }
        }

        private Gtk.StyleContext calendar_color_context;

        public CalendarGrid (E.Source source) {
            Object (source: source);
        }

        construct {
            column_spacing = 6;

            var calendar_color = new Gtk.Grid ();
            calendar_color.height_request = 12;
            calendar_color.valign = Gtk.Align.CENTER;
            calendar_color.width_request = 12;

            calendar_color_context = calendar_color.get_style_context ();
            calendar_color_context.add_class ("cal-color");

            var calendar_name_label = new Gtk.Label ("");
            calendar_name_label.xalign = 0;
            calendar_name_label.hexpand = true;
            calendar_name_label.ellipsize = Pango.EllipsizeMode.MIDDLE;

            add (calendar_color);
            add (calendar_name_label);

            bind_property ("label", calendar_name_label, "label");
        }

        private void apply_source () {
            E.SourceCalendar cal = (E.SourceCalendar)_source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            label = _source.dup_display_name ();
            location = Calendar.Store.get_event_store ().source_get_location (_source);

            var css_color = STYLE.printf (cal.dup_color ());
            var style_provider = new Gtk.CssProvider ();

            try {
                style_provider.load_from_data (css_color, css_color.length);
                calendar_color_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (Error e) {
                warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, css_color);
            }
        }
    }
}
