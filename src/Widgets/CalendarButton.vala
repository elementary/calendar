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

    private CalendarGrid calendar_grid;

    construct {
        sources = new GLib.List<E.Source> ();
        var calmodel = Model.CalendarModel.get_default ();
        var registry = calmodel.registry;
        foreach (var src in registry.list_sources (E.SOURCE_EXTENSION_CALENDAR)) {
            if (src.writable == true && src.enabled == true && calmodel.calclient_is_readonly (src) == false) {
                sources.append (src);
            }
        }

        _current_source = registry.default_calendar;

        calendar_grid = new CalendarGrid (current_source);
        calendar_grid.halign = Gtk.Align.START;
        calendar_grid.hexpand = true;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.add (calendar_grid);
        grid.add (new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU));

        add (grid);

        current_source = registry.default_calendar;

        var list_box = new Gtk.ListBox ();
        list_box.activate_on_single_click = true;

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled.add (list_box);
        scrolled.margin_top = 6;
        scrolled.margin_bottom = 6;
        scrolled.max_content_height = 300;
        scrolled.propagate_natural_height = true;
        scrolled.show_all ();

        popover = new Gtk.Popover (this);
        popover.width_request = 310;
        popover.add (scrolled);

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

        list_box.row_activated.connect ((row) => {
            current_source = ((CalendarGrid)row.get_child ()).source;
            popover.popdown ();
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

        private Gtk.Grid calendar_color;

        public CalendarGrid (E.Source source) {
            Object (source: source);
        }

        construct {
            column_spacing = 6;

            calendar_color = new Gtk.Grid ();
            calendar_color.height_request = 12;
            calendar_color.valign = Gtk.Align.CENTER;
            calendar_color.width_request = 12;

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
            location = Maya.Util.get_source_location (_source);
            Util.style_calendar_color (calendar_color, cal.dup_color (), true);
        }
    }
}
