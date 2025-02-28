/*
 * Copyright 2014-2021 elementary, Inc. (https://elementary.io)
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

public class Maya.View.Widgets.CalendarChooser : Gtk.Grid {

    /** A searchable list of calendars for the user to choose from.
    *
    * The current selection is exposed as a E.Source through the current_source property.
    * The selection defaults to the current default calendar.
    */

    public GLib.List<E.Source> sources;
    public E.Source current_source { get; set; }

    private Calendar.EventStore calmodel;
    private E.SourceRegistry registry;
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox list_box;

    construct {
        calmodel = Calendar.EventStore.get_default ();
        registry = calmodel.registry;
        current_source = registry.default_calendar;

        // GUI setup
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

        list_box = new Gtk.ListBox ();
        list_box.activate_on_single_click = true;
        list_box.set_placeholder (placeholder);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled.add (list_box);
        scrolled.max_content_height = 300;
        scrolled.propagate_natural_height = true;

        margin_bottom = 6;
        attach (search_entry, 0, 0);
        attach (scrolled, 0, 1);
        show_all ();

        list_box.set_filter_func (filter_function);
        list_box.set_header_func (header_update_func);

        // Signal handlers

        list_box.set_sort_func ((row1, row2) => {
            var child1 = (CalendarRow)row1.get_child ();
            var child2 = (CalendarRow)row2.get_child ();
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
            current_source = ((CalendarRow) (row.get_child ())).source;

            // Clear selected property
            foreach (unowned Gtk.Widget deselect_row in list_box.get_children ()) {
                var calrow = ((Gtk.ListBoxRow) deselect_row).get_child ();
                ((CalendarRow) calrow).selected = false;
            }

            // Select new row
            var calrow = row.get_child ();
            ((CalendarRow) calrow).selected = true;
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
            // TODO Should active calendar be re-selected?
        });

        // Parse registry list_sources and render list_box;
        render_sources ();

        // Re-render sources when a new source connects;
        calmodel.connected.connect (() => render_sources ());
    }

    private void render_sources () {
        // Set up sources list
        sources = new GLib.List<E.Source> ();
        foreach (var src in registry.list_sources (E.SOURCE_EXTENSION_CALENDAR)) {
            if (src.writable == true && src.enabled == true && calmodel.calclient_is_readonly (src) == false) {
                sources.append (src);
            }
        }

        // Render sources into list_box
        list_box.foreach (element => list_box.remove (element));
        foreach (var source in sources) {
            var calrow = new CalendarRow (source);
            calrow.margin = 6;
            calrow.margin_start = 12;

            var row = new Gtk.ListBoxRow ();
            row.add (calrow);
            row.show_all ();

            list_box.add (row);

            if (source.dup_uid () == current_source.dup_uid ()) {
                list_box.select_row (row);
                calrow.selected = true;
            }
        }
    }

    [CCode (instance_pos = -1)]
    private bool filter_function (Gtk.ListBoxRow row) {
        var search_term = search_entry.text.down ();

        if (search_term in ((CalendarRow)row.get_child ()).label.down ()) {
            return true;
        }

        return false;
    }

    private void header_update_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
        var row_location = ((CalendarRow)row.get_child ()).location;
        if (before != null) {
            var before_row_location = ((CalendarRow)before.get_child ()).location;
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

    public void clear_search_entry () {
        search_entry.text = "";
    }
}
