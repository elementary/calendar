/*
 * Copyright 2011-2018 elementary, Inc. (https://elementary.io)
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
 * Authored by: Maxwell Barvian
 *              Niels Avonds <niels.avonds@gmail.com>
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.AgendaView : Gtk.Grid {
    public signal void event_removed (E.CalComponent event);
    public signal void event_modified (E.CalComponent event);

    private Gtk.Label day_label;
    private Gtk.Label weekday_label;
    private Gtk.ListBox selected_date_events_list;
    private Gtk.ListBox upcoming_events_list;
    private DateTime selected_date;
    private HashTable<string, AgendaEventRow> row_table;
    private HashTable<string, AgendaEventRow> row_table2;

    construct {
        weekday_label = new Gtk.Label ("");
        weekday_label.xalign = 0;
        weekday_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        day_label = new Gtk.Label ("");
        day_label.xalign = 0;
        day_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var selected_data_grid = new Gtk.Grid ();
        selected_data_grid.margin = 6;
        selected_data_grid.margin_start = selected_data_grid.margin_end = 12;
        selected_data_grid.row_spacing = 3;
        selected_data_grid.orientation = Gtk.Orientation.VERTICAL;
        selected_data_grid.add (weekday_label);
        selected_data_grid.add (day_label);

        var placeholder_label = new Gtk.Label (_("Your upcoming events will be displayed here when you select a date with events."));
        placeholder_label.wrap = true;
        placeholder_label.wrap_mode = Pango.WrapMode.WORD;
        placeholder_label.margin_start = 12;
        placeholder_label.margin_end = 12;
        placeholder_label.justify = Gtk.Justification.CENTER;
        placeholder_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        placeholder_label.show_all ();

        selected_date_events_list = new Gtk.ListBox ();
        selected_date_events_list.margin_start = selected_date_events_list.margin_end = 6;
        selected_date_events_list.selection_mode = Gtk.SelectionMode.SINGLE;
        selected_date_events_list.set_header_func (header_update_func);
        selected_date_events_list.set_placeholder (placeholder_label);
        selected_date_events_list.set_sort_func ((child1, child2) => {
            var row1 = (AgendaEventRow) child1;
            var row2 = (AgendaEventRow) child2;
            if (row1.is_allday) {
                if (row2.is_allday) {
                    return row1.summary.collate (row2.summary);
                } else {
                    return -1;
                }
            } else {
                if (row2.is_allday) {
                    return 1;
                } else {
                    unowned iCal.Component ical_event1 = row1.calevent.get_icalcomponent ();
                    DateTime start_date1, end_date1;
                    Util.get_local_datetimes_from_icalcomponent (ical_event1, out start_date1, out end_date1);
                    unowned iCal.Component ical_event2 = row2.calevent.get_icalcomponent ();
                    DateTime start_date2, end_date2;
                    Util.get_local_datetimes_from_icalcomponent (ical_event2, out start_date2, out end_date2);
                    var comp = start_date1.compare (start_date2);
                    if (comp != 0) {
                        return comp;
                    } else {
                        comp = end_date1.compare (end_date2);
                        if (comp != 0) {
                            return comp;
                        }
                    }

                    return row1.summary.collate (row2.summary);
                }
            }
        });

        selected_date_events_list.set_filter_func ((row) => {
            if (selected_date == null) {
                return false;
            }

            var event_row = (AgendaEventRow) row;
            unowned iCal.Component comp = event_row.calevent.get_icalcomponent ();

            var stripped_time = new DateTime.local (selected_date.get_year (), selected_date.get_month (), selected_date.get_day_of_month (), 0, 0, 0);
            var range = new Util.DateRange (stripped_time, stripped_time.add_days (1));
            Gee.Collection<Util.DateRange> event_ranges = Util.event_date_ranges (comp, range);

            foreach (Util.DateRange event_range in event_ranges) {
                if (Util.is_day_in_range (stripped_time, event_range)) {
                    return true;
                }
            }

            return false;
        });

        var selected_scrolled = new Gtk.ScrolledWindow (null, null);
        selected_scrolled.expand = true;
        selected_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        selected_scrolled.add (selected_date_events_list);

        upcoming_events_list = new Gtk.ListBox ();
        upcoming_events_list.margin_start = upcoming_events_list.margin_end = 6;
        upcoming_events_list.selection_mode = Gtk.SelectionMode.SINGLE;
        upcoming_events_list.set_header_func (upcoming_header_update_func);
        upcoming_events_list.set_sort_func ((child1, child2) => {
            var row1 = (AgendaEventRow) child1;
            var row2 = (AgendaEventRow) child2;

            unowned iCal.Component ical_event1 = row1.calevent.get_icalcomponent ();
            DateTime start_date1, end_date1;
            Util.get_local_datetimes_from_icalcomponent (ical_event1, out start_date1, out end_date1);
            unowned iCal.Component ical_event2 = row2.calevent.get_icalcomponent ();
            DateTime start_date2, end_date2;
            Util.get_local_datetimes_from_icalcomponent (ical_event2, out start_date2, out end_date2);
            var comp = start_date1.compare (start_date2);
            if (comp != 0) {
                return comp;
            } else {
                comp = end_date1.compare (end_date2);
                if (comp != 0) {
                    return comp;
                }
            }

            return row1.summary.collate (row2.summary);
        });

        upcoming_events_list.set_filter_func ((row) => {
            var event_row = (AgendaEventRow) row;

            DateTime now = new DateTime.now_local ();
            unowned iCal.Component comp = event_row.calevent.get_icalcomponent ();
            var stripped_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
            stripped_time = stripped_time.add_days (1);
            var stripped_time_end = new DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);
            stripped_time_end = stripped_time_end.add_months (2);

            var range = new Util.DateRange (stripped_time, stripped_time_end);

            return Util.is_event_in_range (comp, range);
        });

        var upcoming_scrolled = new Gtk.ScrolledWindow (null, null);
        upcoming_scrolled.expand = true;
        upcoming_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        upcoming_scrolled.add (upcoming_events_list);

        orientation = Gtk.Orientation.VERTICAL;
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        add (selected_data_grid);
        add (selected_scrolled);
        add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        add (upcoming_scrolled);

        row_table = new HashTable<string, AgendaEventRow> (str_hash, str_equal);
        row_table2 = new HashTable<string, AgendaEventRow> (str_hash, str_equal);

        // Listen to changes for events
        var calmodel = Model.CalendarModel.get_default ();
        calmodel.events_added.connect (on_events_added);
        calmodel.events_removed.connect (on_events_removed);
        calmodel.events_updated.connect (on_events_updated);
        set_selected_date (Settings.SavedState.get_default ().get_selected ());
        show_all ();
    }

    private void header_update_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        var row = (AgendaEventRow) lbrow;
        if (lbbefore != null) {
            var before = (AgendaEventRow) lbbefore;
            if (row.is_allday == before.is_allday) {
                row.set_header (null);
                return;
            }

            if (row.is_allday != before.is_allday) {
                row.set_header (new Granite.HeaderLabel (_("During the day")));
                return;
            }
        } else {
            if (row.is_allday) {
                var allday_header = new Granite.HeaderLabel (_("All day"));
                row.set_header (allday_header);
            }
            return;
        }
    }

    private static int get_event_type (AgendaEventRow row) {
        unowned iCal.Component comp = row.calevent.get_icalcomponent ();
        DateTime now = new DateTime.now_local ();

        var stripped_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
        stripped_time = stripped_time.add_days (1);
        var stripped_time_end = stripped_time.add_days (1);
        var range = new Util.DateRange (stripped_time, stripped_time_end);
        if (Util.is_event_in_range (comp, range)) {
            return 1; // Tomorrow
        }

        stripped_time_end = stripped_time_end.add_days (7 - stripped_time.get_day_of_week ());
        range = new Util.DateRange (stripped_time, stripped_time_end);
        if (Util.is_event_in_range (comp, range)) {
            return 2; // This Week
        }

        stripped_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
        stripped_time = stripped_time.add_days (8 - stripped_time.get_day_of_week ());
        stripped_time_end = stripped_time.add_days (7);
        range = new Util.DateRange (stripped_time, stripped_time_end);
        if (Util.is_event_in_range (comp, range)) {
            return 3; // Next Week
        }

        stripped_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
        stripped_time_end = new DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);
        stripped_time_end = stripped_time_end.add_months (1);
        range = new Util.DateRange (stripped_time, stripped_time_end);
        if (Util.is_event_in_range (comp, range)) {
            return 4; // This Month
        }

        stripped_time = new DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);
        stripped_time = stripped_time.add_months (1);
        stripped_time_end = stripped_time.add_months (1);
        range = new Util.DateRange (stripped_time, stripped_time_end);
        if (Util.is_event_in_range (comp, range)) {
            return 5; // Next Month
        }
        return -1;
    }

    private void upcoming_header_update_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        var row = (AgendaEventRow) lbrow;
        int rowType = get_event_type (row);

        if (lbbefore != null) {
            var before = (AgendaEventRow) lbbefore;
            int beforeType = get_event_type (before);

            if (rowType == beforeType) {
                row.set_header (null);
                return;
            }

            switch (rowType) {
                case 1: row.set_header (new Granite.HeaderLabel (_("Tomorrow")));
                        break;
                case 2: row.set_header (new Granite.HeaderLabel (_("This Week")));
                        break;
                case 3: row.set_header (new Granite.HeaderLabel (_("Next Week")));
                        break;
                case 4: row.set_header (new Granite.HeaderLabel (_("This Month")));
                        break;
                case 5: row.set_header (new Granite.HeaderLabel (_("Next Month")));
                        break;
                default: break;
            }
        } else {
            switch (rowType) {
                case 1: row.set_header (new Granite.HeaderLabel (_("Tomorrow")));
                        break;
                case 2: row.set_header (new Granite.HeaderLabel (_("This Week")));
                        break;
                case 3: row.set_header (new Granite.HeaderLabel (_("Next Week")));
                        break;
                case 4: row.set_header (new Granite.HeaderLabel (_("This Month")));
                        break;
                case 5: row.set_header (new Granite.HeaderLabel (_("Next Month")));
                        break;
                default: break;
            }
        }
    }

    /**
     * Events have been added to the given source.
     */
    private void on_events_added (E.Source source, Gee.Collection<E.CalComponent> events) {
        foreach (var event in events) {
            unowned iCal.Component comp = event.get_icalcomponent ();

            if (!row_table.contains (comp.get_uid ())) {
                var row = new AgendaEventRow (source, event, false);
                row.modified.connect ((event) => (event_modified (event)));
                row.removed.connect ((event) => (event_removed (event)));
                row.show_all ();
                row_table.set (comp.get_uid (), row);
                selected_date_events_list.add (row);
            }

            if (!row_table2.contains (comp.get_uid ())) {
                var row2 = new AgendaEventRow (source, event, true);
                row2.modified.connect ((event) => (event_modified (event)));
                row2.removed.connect ((event) => (event_removed (event)));
                row2.show_all ();
                row_table2.set (comp.get_uid (), row2);
                upcoming_events_list.add (row2);
            }
        }
    }

    /**
     * Events for the given source have been updated.
     */
    private void on_events_updated (E.Source source, Gee.Collection<E.CalComponent> events) {
        foreach (var event in events) {
            unowned iCal.Component comp = event.get_icalcomponent ();

            var row = (AgendaEventRow)row_table.get (comp.get_uid ());
            row.update (event);

            var row2 = (AgendaEventRow)row_table2.get (comp.get_uid ());
            row2.update (event);
        }
    }

    /**
     * Events for the given source have been removed.
     */
    private void on_events_removed (E.Source source, Gee.Collection<E.CalComponent> events) {
        foreach (var event in events) {
            unowned iCal.Component comp = event.get_icalcomponent ();

            var row = (AgendaEventRow)row_table.get (comp.get_uid ());
            row_table.remove (comp.get_uid ());
            if (row is Gtk.Widget) {
                row.revealer.set_reveal_child (false);
                GLib.Timeout.add (row.revealer.transition_duration, () => {
                    row.destroy ();
                    return GLib.Source.REMOVE;
                });
            }

            var row2 = (AgendaEventRow)row_table2.get (comp.get_uid ());
            row_table2.remove (comp.get_uid ());
            if (row2 is Gtk.Widget) {
                row2.revealer.set_reveal_child (false);
                GLib.Timeout.add (row2.revealer.transition_duration, () => {
                    row2.destroy ();
                    return GLib.Source.REMOVE;
                });
            }
        }
    }

    /**
     * The given date has been selected.
     */
    public void set_selected_date (DateTime date) {
        selected_date = date;
        string formated_weekday = date.format ("%A");
        string new_value = formated_weekday.substring (formated_weekday.index_of_nth_char (1));
        new_value = formated_weekday.get_char (0).totitle ().to_string () + new_value;
        weekday_label.label = new_value;
        day_label.label = date.format (Settings.DateFormat ());
        selected_date_events_list.invalidate_filter ();
    }
}
