/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Maxwell Barvian
 *              Niels Avonds <niels.avonds@gmail.com>
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.AgendaView : Gtk.Box {
    public signal void event_removed (ECal.Component event);

    public Adw.HeaderBar header_bar { get; private set; }

    private Gtk.Label day_label;
    private Gtk.Label weekday_label;
    private Gtk.ListBox selected_date_events_list;
    private Gtk.ListBox upcoming_events_list;
    private DateTime selected_date;

    construct {
        var application_instance = ((Gtk.Application) GLib.Application.get_default ());

        var button_add = new Gtk.Button.from_icon_name ("appointment-new") {
            action_name = Maya.MainWindow.ACTION_PREFIX + Maya.MainWindow.ACTION_NEW_EVENT
        };
        button_add.tooltip_markup = Granite.markup_accel_tooltip (
            application_instance.get_accels_for_action (button_add.action_name),
            _("Create a new event")
        );

        weekday_label = new Gtk.Label ("") {
            margin_start = 6,
            xalign = 0
        };
        weekday_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        header_bar = new Adw.HeaderBar () {
            show_start_title_buttons = false,
            show_title = false
        };
        header_bar.pack_start (weekday_label);
        header_bar.pack_end (button_add);
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);

        day_label = new Gtk.Label ("") {
            margin_start = 12,
            margin_end = 12,
            xalign = 0
        };
        day_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        var placeholder_label = new Gtk.Label (_("Your upcoming events will be displayed here when you select a date with events.")) {
            wrap = true,
            wrap_mode = WORD,
            margin_start = 12,
            margin_end = 12,
            justify = CENTER
        };
        placeholder_label.add_css_class (Granite.CssClass.DIM);

        selected_date_events_list = new Gtk.ListBox () {
            activate_on_single_click = false,
            height_request = 128,
            hexpand = true,
            selection_mode = SINGLE
        };
        selected_date_events_list.set_header_func (header_update_func);
        selected_date_events_list.set_placeholder (placeholder_label);
        selected_date_events_list.set_sort_func (selected_sort_function);

        selected_date_events_list.set_filter_func ((row) => {
            if (selected_date == null) {
                return false;
            }

            unowned AgendaEventRow event_row = (AgendaEventRow) row;
            return Calendar.Util.ecalcomponent_is_on_day (event_row.calevent, selected_date);
        });

        upcoming_events_list = new Gtk.ListBox () {
            activate_on_single_click = false,
            margin_top = 24,
            hexpand = true,
            selection_mode = SINGLE
        };
        upcoming_events_list.set_header_func (upcoming_header_update_func);
        upcoming_events_list.set_sort_func (upcoming_sort_function);

        upcoming_events_list.set_filter_func ((row) => {
            var event_row = (AgendaEventRow) row;

            DateTime now = new DateTime.now_local ();
            unowned ICal.Component comp = event_row.calevent.get_icalcomponent ();
            var stripped_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
            stripped_time = stripped_time.add_days (1);
            var stripped_time_end = new DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);
            stripped_time_end = stripped_time_end.add_months (2);

            var range = new Calendar.Util.DateRange (stripped_time, stripped_time_end);

            return Calendar.Util.icalcomponent_is_in_range (comp, range);
        });

        var box = new Gtk.Box (VERTICAL, 0);
        box.append (day_label);
        box.append (selected_date_events_list);
        box.append (upcoming_events_list);

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = NEVER,
            child = box,
            vexpand = true
        };

        orientation = VERTICAL;
        append (header_bar);
        append (scrolled_window);
        add_css_class (Granite.STYLE_CLASS_VIEW);

        // Listen to changes for events
        var calmodel = Calendar.EventStore.get_default ();
        calmodel.events_added.connect (on_events_added);
        calmodel.events_removed.connect (on_events_removed);
        calmodel.events_updated.connect (on_events_updated);
        calmodel.parameters_changed.connect (on_model_parameters_changed);

        unowned var time_manager = Calendar.TimeManager.get_default ();
        time_manager.on_update_today.connect (on_today_changed);

        set_selected_date (Maya.Application.get_selected_datetime ());

        selected_date_events_list.row_activated.connect (activate_eventrow);
        upcoming_events_list.row_activated.connect (activate_eventrow);
    }

    private void activate_eventrow (Gtk.ListBoxRow row) {
        var calevent = ((AgendaEventRow) row).calevent;
        ((Maya.Application) GLib.Application.get_default ()).window.on_modified (calevent);
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
                var header_label = new Granite.HeaderLabel (_("During the day"));
                header_label.margin_start = header_label.margin_end = 6;

                row.set_header (header_label);
                return;
            }
        } else {
            if (row.is_allday) {
                var allday_header = new Granite.HeaderLabel (_("All day"));
                allday_header.margin_start = allday_header.margin_end = 6;

                row.set_header (allday_header);
            }
            return;
        }
    }

    [CCode (instance_pos = -1)]
    private int upcoming_sort_function (Gtk.ListBoxRow child1, Gtk.ListBoxRow child2) {
        return compare_rows ((AgendaEventRow) child1, (AgendaEventRow) child2);
    }

    [CCode (instance_pos = -1)]
    private int selected_sort_function (Gtk.ListBoxRow child1, Gtk.ListBoxRow child2) {
        var row1 = (AgendaEventRow) child1;
        var row2 = (AgendaEventRow) child2;

        if (row1.is_allday) {
            if (row2.is_allday) {
                return row1.summary.collate (row2.summary);
            } else {
                return -1;
            }
        } else if (row2.is_allday) {
            return 1;
        }

        return compare_rows (row1, row2);
    }

    private int compare_rows (AgendaEventRow row1, AgendaEventRow row2) {
        unowned ICal.Component ical_event1 = row1.calevent.get_icalcomponent ();
        DateTime start_date1, end_date1;
        Calendar.Util.icalcomponent_get_local_datetimes (ical_event1, out start_date1, out end_date1);

        unowned ICal.Component ical_event2 = row2.calevent.get_icalcomponent ();
        DateTime start_date2, end_date2;
        Calendar.Util.icalcomponent_get_local_datetimes (ical_event2, out start_date2, out end_date2);

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

    private static int get_event_type (AgendaEventRow row) {
        unowned ICal.Component comp = row.calevent.get_icalcomponent ();
        DateTime now = new DateTime.now_local ();

        var stripped_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
        stripped_time = stripped_time.add_days (1);
        var stripped_time_end = stripped_time.add_days (1);
        var range = new Calendar.Util.DateRange (stripped_time, stripped_time_end);
        if (Calendar.Util.icalcomponent_is_in_range (comp, range)) {
            return 1; // Tomorrow
        }

        stripped_time_end = stripped_time_end.add_days (7 - stripped_time.get_day_of_week ());
        range = new Calendar.Util.DateRange (stripped_time, stripped_time_end);
        if (Calendar.Util.icalcomponent_is_in_range (comp, range)) {
            return 2; // This Week
        }

        stripped_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
        stripped_time = stripped_time.add_days (8 - stripped_time.get_day_of_week ());
        stripped_time_end = stripped_time.add_days (7);
        range = new Calendar.Util.DateRange (stripped_time, stripped_time_end);
        if (Calendar.Util.icalcomponent_is_in_range (comp, range)) {
            return 3; // Next Week
        }

        stripped_time = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
        stripped_time_end = new DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);
        stripped_time_end = stripped_time_end.add_months (1);
        range = new Calendar.Util.DateRange (stripped_time, stripped_time_end);
        if (Calendar.Util.icalcomponent_is_in_range (comp, range)) {
            return 4; // This Month
        }

        stripped_time = new DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);
        stripped_time = stripped_time.add_months (1);
        stripped_time_end = stripped_time.add_months (1);
        range = new Calendar.Util.DateRange (stripped_time, stripped_time_end);
        if (Calendar.Util.icalcomponent_is_in_range (comp, range)) {
            return 5; // Next Month
        }
        return -1;
    }

    private void upcoming_header_update_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        var row = (AgendaEventRow) lbrow;
        int row_type = get_event_type (row);

        if (lbbefore != null) {
            var before = (AgendaEventRow) lbbefore;
            int before_type = get_event_type (before);

            if (row_type == before_type) {
                row.set_header (null);
                return;
            }
        }

        var header_label = new Granite.HeaderLabel ("");
        header_label.margin_start = header_label.margin_end = 6;

        switch (row_type) {
            case 1:
                header_label.label = _("Tomorrow");
                break;
            case 2:
                header_label.label = _("This Week");
                break;
            case 3:
                header_label.label = _("Next Week");
                break;
            case 4:
                header_label.label = _("This Month");
                break;
            case 5:
                header_label.label =_("Next Month");
                break;
            default:
                break;
        }

        row.set_header (header_label);
    }

    /**
     * Events have been added to the given source.
     */
    private void on_events_added (E.Source source, Gee.Collection<ECal.Component> events) {
        foreach (var event in events) {
            var row = new AgendaEventRow (source, event, false);
            row.removed.connect ((event) => (event_removed (event)));
            selected_date_events_list.append (row);

            var row2 = new AgendaEventRow (source, event, true);
            row2.removed.connect ((event) => (event_removed (event)));
            upcoming_events_list.append (row2);
        }
    }

    private bool find_row_for_component (Gtk.ListBox listbox, ECal.Component component, out AgendaEventRow? row) {
        for (int i = 0; listbox.get_row_at_index (i) != null; i++) {
            var current_row = (AgendaEventRow) listbox.get_row_at_index (i);
            if (Calendar.Util.ecalcomponent_compare_func (current_row.calevent, component) == 0) {
                row = current_row;
                return true;
            }
        }

        row = null;
        return false;
    }

    /**
     * Events for the given source have been updated.
     */
    private void on_events_updated (E.Source source, Gee.Collection<ECal.Component> events) {
        foreach (var event in events) {
            AgendaEventRow row = null;
            if (find_row_for_component (selected_date_events_list, event, out row)) {
                row.update (event);
            }

            if (find_row_for_component (upcoming_events_list, event, out row)) {
                row.update (event);
            }
        }
    }

    /**
     * Events for the given source have been removed.
     */
    private void on_events_removed (E.Source source, Gee.Collection<ECal.Component> events) {
        foreach (var event in events) {
            AgendaEventRow row = null;
            if (find_row_for_component (selected_date_events_list, event, out row)) {
                row.revealer.reveal_child = false;
                GLib.Timeout.add (row.revealer.transition_duration, () => {
                    row.unparent ();
                    row.destroy ();
                    return GLib.Source.REMOVE;
                });
            }

            if (find_row_for_component (upcoming_events_list, event, out row)) {
                row.revealer.reveal_child = false;
                GLib.Timeout.add (row.revealer.transition_duration, () => {
                    row.unparent ();
                    row.destroy ();
                    return GLib.Source.REMOVE;
                });
            }
        }
    }

    /**
     * Calendar model parameters have been updated.
     */
    private void on_model_parameters_changed () {
        selected_date_events_list.remove_all ();
        upcoming_events_list.remove_all ();
    }

    private void on_today_changed () {
        upcoming_events_list.invalidate_filter ();
        upcoming_events_list.invalidate_headers ();
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
        var format = Granite.DateTime.get_default_date_format (false, true, true);
        day_label.label = date.format (format);
        selected_date_events_list.invalidate_filter ();
    }
}
