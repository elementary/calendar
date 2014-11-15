// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014 Maya Developers (http://launchpad.net/maya)
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

public class Maya.View.Widgets.CalendarButton : Gtk.ToggleButton {
    public GLib.List<E.Source> sources;
    private E.Source _current_source;
    public E.Source current_source {
        get {
            return _current_source;
        }

        set {
            _current_source = value;
            button_grid.source = value;
            tooltip_text = "%s - %s".printf (button_grid.label, button_grid.location);
        }
    }

    private Gtk.Popover popover;
    private Gtk.ListBox list_box;
    private CalendarGrid button_grid;

    public CalendarButton () {
        set_alignment (0, 0.5f);
        sources = new GLib.List<E.Source> ();
        var calmodel = Model.CalendarModel.get_default ();
        var registry = calmodel.registry;
        foreach (var src in registry.list_sources (E.SOURCE_EXTENSION_CALENDAR)) {
            if (src.writable == true && src.enabled == true && calmodel.calclient_is_readonly(src)) {
                sources.append (src);
            }
        }

        _current_source = registry.default_calendar;
        button_grid = new CalendarGrid (current_source);
        image = button_grid;
        current_source = registry.default_calendar;
        create_popover ();

        toggled.connect (() => {
            if (active) {
                popover.show_all ();
            } else {
                popover.hide ();
            }
        });

        popover.hide.connect (() => {
            active = false;
        });
    }

    private void create_popover () {
        popover = new Gtk.Popover (this);
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        list_box = new Gtk.ListBox ();
        list_box.activate_on_single_click = true;
        list_box.add.connect ((widget) => {
            widget.show_all ();
            int minimum_height;
            int natural_height;
            widget.get_preferred_height (out minimum_height, out natural_height);
            var number_of_children = list_box.get_children ().length ();
            var real_size = natural_height * number_of_children;
            if (real_size > 150) {
                scrolled.set_size_request (-1, 150);
            } else {
                scrolled.set_size_request (-1, (int)real_size);
            }
        });

        list_box.set_header_func (header_update_func);

        list_box.set_sort_func ((row1, row2) => {
            var child1 = row1.get_child ();
            var child2 = row2.get_child ();
            var comparison = ((CalendarGrid)child1).location.collate (((CalendarGrid)child2).location);
            if (comparison == 0)
                return ((CalendarGrid)child1).label.collate (((CalendarGrid)child2).label);
            else
                return comparison;
        });

        list_box.row_activated.connect ((row) => {
            current_source = ((CalendarGrid)row.get_child ()).source;
        });

        foreach (var source in sources) {
            add_source (source);
        }

        scrolled.add (list_box);
        scrolled.margin_top = 6;
        scrolled.margin_bottom = 6;
        popover.add (scrolled);
    }

    private void add_source (E.Source source) {
        var calgrid = new CalendarGrid (source);
        calgrid.margin = 6;
        calgrid.margin_start = 12;
        var row = new Gtk.ListBoxRow ();
        row.add (calgrid);
        list_box.add (row);
        if (source.dup_uid () == current_source.dup_uid ()) {
            list_box.select_row (row);
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

        var header = new SourceItemHeader (row_location);
        header.margin_start = 6;
        row.set_header (header);
        header.show_all ();
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

        private Gtk.Label calendar_name_label;
        private Gtk.Label calendar_color_label;
        public CalendarGrid (E.Source source) {
            orientation = Gtk.Orientation.HORIZONTAL;
            column_spacing = 6;

            calendar_color_label = new Gtk.Label ("  ");
            calendar_name_label = new Gtk.Label ("");
            calendar_name_label.xalign = 0;
            calendar_name_label.hexpand = true;
            calendar_name_label.ellipsize = Pango.EllipsizeMode.MIDDLE;

            add (calendar_color_label);
            add (calendar_name_label);
            show_all ();
            _source = source;
            apply_source ();
        }

        private void apply_source () {
            E.SourceCalendar cal = (E.SourceCalendar)_source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            calendar_name_label.label = _source.dup_display_name ();
            label = calendar_name_label.label;
            location = Maya.Util.get_source_location (_source);
            var color = Gdk.RGBA ();
            color.parse (cal.dup_color());
            calendar_color_label.override_background_color (Gtk.StateFlags.NORMAL, color);
        }
    }
}
