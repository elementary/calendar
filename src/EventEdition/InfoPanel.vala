// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2020 elementary, Inc. (http://launchpad.net/maya)
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

public class Maya.View.EventEdition.InfoPanel : Gtk.Grid {
    private Gtk.Entry title_entry;
    private Granite.HyperTextView comment_textview;
    private Granite.Widgets.DatePicker from_date_picker;
    private Granite.Widgets.DatePicker to_date_picker;
    private Gtk.Switch allday_switch;
    private Granite.Widgets.TimePicker from_time_picker;
    private Granite.Widgets.TimePicker to_time_picker;
    private Gtk.Label timezone_label;
    private Widgets.CalendarChooser calchooser;

    private EventDialog parent_dialog;

    public string title {
        get { return title_entry.get_text (); }
        set { title_entry.set_text (value); }
    }

    public DateTime from_date {
        get { return from_date_picker.date; }
        set { from_date_picker.date = value; }
    }

    public DateTime to_date {
        get { return to_date_picker.date; }
        set { to_date_picker.date = value; }
    }

    // TODO Also use all_day
    public DateTime from_time {
        get { return from_time_picker.time; }
        set { from_time_picker.time = value; }
    }

    public DateTime to_time {
        get { return to_time_picker.time; }
        set { to_time_picker.time = value; }
    }

    public bool all_day {
        get { return allday_switch.get_active (); }
        set { allday_switch.set_active (value); }
    }

    public ICal.Timezone timezone { get; private set; }

    public bool nl_parsing_enabled = false;

    public signal void parse_event (string event_str);
    public signal void valid_event (bool is_valid);

    public InfoPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;

        margin_start = 12;
        margin_end = 12;
        column_spacing = 12;
        sensitive = parent_dialog.can_edit;

        var from_label = new Granite.HeaderLabel (_("From:"));

        from_date_picker = make_date_picker ();
        from_date_picker.notify["date"].connect (() => {on_date_modified (0);} );

        from_time_picker = make_time_picker ();
        from_time_picker.time_changed.connect (() => {on_time_modified (0);} );

        allday_switch = new Gtk.Switch () {
            valign = CENTER
        };

        var allday_label = new Gtk.Label (_("All day:")) {
            mnemonic_widget = allday_switch,
            xalign = 1
        };

        allday_switch.notify["active"].connect (() => {
            on_date_modified (1);
            from_time_picker.sensitive = !allday_switch.get_active ();
            to_time_picker.sensitive = !allday_switch.get_active ();
        });

        var to_label = new Granite.HeaderLabel (_("To:"));

        to_date_picker = make_date_picker ();
        to_date_picker.notify["date"].connect (() => {on_date_modified (1);} );

        to_time_picker = make_time_picker ();
        to_time_picker.time_changed.connect (() => {on_time_modified (1);} );

        var timezone_header = new Granite.HeaderLabel (_("Time zone:"));

        timezone_label = new Gtk.Label (null) {
            halign = START
        };

        title_entry = new Gtk.Entry () {
            placeholder_text = _("Name of Event")
        };

        var title_label = new Granite.HeaderLabel (_("Title:")) {
            mnemonic_widget = title_entry
        };

        title_entry.changed.connect (on_title_entry_modified);
        title_entry.activate.connect (() => {
            parse_event (title_entry.get_text ());
            title_entry.secondary_icon_name = null;
            title_entry.secondary_icon_tooltip_text = null;
        });
        title_entry.changed.connect (() => {
            if (title_entry.get_text ().length > 0 && nl_parsing_enabled) {
                title_entry.secondary_icon_name = "go-jump-symbolic";
                title_entry.secondary_icon_tooltip_text = _("Press enter to parse event");
            }
            else {
                title_entry.secondary_icon_name = null;
                title_entry.secondary_icon_tooltip_text = null;
            }
        });

        realize.connect (() => {
            Idle.add (() => {
                title_entry.grab_focus ();
                return false;
            });
        });

        calchooser = new Widgets.CalendarChooser () {
            margin_bottom = 6
        };

        var popover = new Gtk.Popover (null) {
            child = calchooser,
            width_request = 310
        };

        var current_calendar_grid = new CalendarRow (calchooser.current_source) {
            halign = START,
            hexpand = true
        };

        var button_box = new Gtk.Box (HORIZONTAL, 6);
        button_box.add (current_calendar_grid);
        button_box.add (new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU));

        var calendar_button = new Gtk.MenuButton () {
            child = button_box,
            popover = popover
        };

        var calendar_label = new Granite.HeaderLabel (_("Calendar:")) {
            mnemonic_widget = calendar_button
        };

        // Select the first calendar we can find, if none is default
        if (parent_dialog.source == null) {
            parent_dialog.source = calchooser.current_source;
        }

        comment_textview = new Granite.HyperTextView ();
        comment_textview.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
        comment_textview.accepts_tab = false;
        comment_textview.set_border_window_size (Gtk.TextWindowType.LEFT, 2);
        comment_textview.set_border_window_size (Gtk.TextWindowType.RIGHT, 2);
        comment_textview.set_border_window_size (Gtk.TextWindowType.TOP, 2);
        comment_textview.set_border_window_size (Gtk.TextWindowType.BOTTOM, 2);

        var comment_label = new Granite.HeaderLabel (_("Comments:")) {
            mnemonic_widget = comment_textview
        };

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            child = comment_textview,
            height_request = 100,
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = NEVER
        };

        var frame = new Gtk.Frame (null) {
            child = scrolled
        };

        // Row: title & calendar
        attach (title_label, 0, 0, 1, 1);
        attach (title_entry, 0, 1, 1, 1);
        if (calchooser.sources.length () > 1 && parent_dialog.can_edit) {
            attach (calendar_label, 1, 0, 4, 1);
            attach (calendar_button, 1, 1, 4, 1);
        }
        // Row: start date/time
        attach (from_label, 0, 2, 4, 1);
        attach (from_date_picker, 0, 3, 1, 1);
        attach (from_time_picker, 1, 3, 1, 1);
        attach (allday_label, 2, 3, 1, 1);
        attach (allday_switch, 3, 3, 1, 1);
        // Row: end date/time
        attach (to_label, 0, 4, 2, 1);
        attach (to_date_picker, 0, 5, 1, 1);
        attach (to_time_picker, 1, 5, 1, 1);
        // Row: timezone
        attach (timezone_header, 0, 6, 1, 1);
        attach (timezone_label, 0, 7, 1, 1);
        // Row: comment
        attach (comment_label, 0, 8, 4, 1);
        attach (frame, 0, 9, 5, 1);

        load ();

        calchooser.bind_property ("current-source", current_calendar_grid, "source", SYNC_CREATE);

        calchooser.notify["current-source"].connect ((s, p) => {
            calendar_button.tooltip_text = "%s—%s".printf (current_calendar_grid.label, current_calendar_grid.location);
            popover.popdown ();
        });

        popover.unmap.connect (() => {
            calchooser.clear_search_entry ();
        });
    }

    /**
     * Save the values in the dialog into the component.
     */
    public void save () {
        unowned ICal.Component comp = parent_dialog.ecal.get_icalcomponent ();

        // Save the title
        comp.set_summary (title_entry.text);

        // Save the time
        if (allday_switch.get_active () == true) {
            var dt_start = Calendar.Util.datetimes_to_icaltime (from_date_picker.date, null);
            var dt_end = Calendar.Util.datetimes_to_icaltime (to_date_picker.date.add_days (1), null);

            comp.set_dtstart (dt_start);
            comp.set_dtend (dt_end);
        } else {
            var dt_start = Calendar.Util.datetimes_to_icaltime (from_date_picker.date, from_time_picker.time, timezone);
            var dt_end = Calendar.Util.datetimes_to_icaltime (to_date_picker.date, to_time_picker.time, timezone);

            comp.set_dtstart (dt_start);
            comp.set_dtend (dt_end);
        }

        // First, clear the comments
        int count = comp.count_properties (ICal.PropertyKind.DESCRIPTION_PROPERTY);
        for (int i = 0; i < count; i++) {
            ICal.Property remove_prop;
            remove_prop = comp.get_first_property (ICal.PropertyKind.COMMENT_PROPERTY);
            comp.remove_property (remove_prop);
        }

        // Add the comment
        var property = new ICal.Property (ICal.PropertyKind.DESCRIPTION_PROPERTY);
        property.set_comment (comment_textview.get_buffer ().text);
        comp.add_property (property);

        // Save the selected source
        parent_dialog.source = calchooser.current_source;
    }

    //--- Helpers ---//

    /**
     * Populate the dialog's widgets with the component's values.
     */
    void load () {
        if (parent_dialog.ecal != null) {
            unowned ICal.Component comp = parent_dialog.ecal.get_icalcomponent ();

            // Load the title
            string summary = comp.get_summary ();
            if (summary != null) {
                title_entry.text = summary;
            }

            DateTime from_date, to_date;
            Calendar.Util.icalcomponent_get_datetimes_for_display (comp, out from_date, out to_date);

            // Load the timezone
            timezone = comp.get_dtstart ().get_timezone ();

            // If end time zone is different from start, convert to same as start.
            // This is permanent once the event is saved, but the actual time is
            // unaffected (only its display).
            if (to_date.get_utc_offset () != from_date.get_utc_offset ()) {
                to_date = to_date.to_timezone (from_date.get_timezone ());
            }

            from_date_picker.date = from_date;
            from_time_picker.time = from_date;
            parent_dialog.date_time = from_date;

            // Is this all day
            bool allday = Calendar.Util.datetime_is_all_day (from_date, to_date);

            to_date_picker.date = to_date;
            to_time_picker.time = to_date;

            // Load the allday_switch
            if (allday) {
                allday_switch.set_active (true);
                from_time_picker.sensitive = false;
                to_time_picker.sensitive = false;
            }

            ICal.Property property;
            property = comp.get_first_property (ICal.PropertyKind.DESCRIPTION_PROPERTY);
            if (property != null) {
                Gtk.TextBuffer buffer = new Gtk.TextBuffer (null);
                buffer.text = property.get_comment ();
                comment_textview.set_buffer (buffer);
            }

            // Load the source
            calchooser.current_source = parent_dialog.original_source;
        } else {
            parent_dialog.ecal = new ECal.Component ();
            parent_dialog.ecal.set_new_vtype (ECal.ComponentVType.EVENT);

            var time = new DateTime.now_local ();
            var minutes = time.get_minute ();
            var now_before_2300 = (time.get_hour () < 23);

            /* Set convenient start time but do not change day */
            from_date_picker.date = parent_dialog.date_time;
            if (now_before_2300) {  /* Default start time to next whole hour*/
                time = time.add_minutes (60 - minutes);
            } else {  /* Default start time 23.00  (11 PM)*/
                time = time.add_minutes (-minutes);
            }

            from_time_picker.time = time;

            /* Default event duration of one hour, changing day if required */
            to_time_picker.time = time.add_hours (1);
            if (now_before_2300) {
                to_date_picker.date = parent_dialog.date_time;
            } else { /* Default end time is 00.00 (12.00 AM) next morning*/
                to_date_picker.date = parent_dialog.date_time.add_days (1);
            }

            // Use local time zone
            timezone = Calendar.TimeManager.get_default ().system_timezone;

            // Load the source
            calchooser.current_source = parent_dialog.source;
        }

        // Populate timezone label with the timezone that was decided
        timezone_label.label = timezone.get_display_name ();
    }

    Granite.Widgets.DatePicker make_date_picker () {
        var format = Granite.DateTime.get_default_date_format (false, true, true);
        var date_picker = new Granite.Widgets.DatePicker.with_format (format);
        date_picker.width_request = 200;
        return date_picker;
    }

    Granite.Widgets.TimePicker make_time_picker () {
        var time_picker = new Granite.Widgets.TimePicker ();
        time_picker.width_request = 120;
        return time_picker;
    }

    void on_title_entry_modified () {
        update_create_sensitivity ();
    }

    void on_date_modified (int index) {
        parent_dialog.date_time = from_date_picker.date;
        var start_date = from_date_picker.date;
        var end_date = to_date_picker.date;

        switch (index) {
        case 0:
            if (start_date.get_year () == end_date.get_year ()) {
                if (start_date.get_day_of_year () >= end_date.get_day_of_year ()) {
                    to_date_picker.date = from_date_picker.date;
                }
            }
            break;
        case 1:
            if (start_date.get_year () == end_date.get_year ()) {
                if (end_date.get_day_of_year () < start_date.get_day_of_year ())
                    from_date_picker.date = to_date_picker.date;
            }
            break;
        }

        update_create_sensitivity ();
    }

    void on_time_modified (int index) {
        var start_date = from_date_picker.date;
        var end_date = to_date_picker.date;
        var start_time = from_time_picker.time;
        var end_time = to_time_picker.time;

        switch (index) {
        case 0:
            if (start_date.get_year () == end_date.get_year ()) {

                if (start_date.get_day_of_year () == end_date.get_day_of_year ()) {

                    if (start_time.get_hour () > end_time.get_hour ()) {
                        to_time_picker.time = from_time_picker.time.add_hours (1);
                    }

                    if ((start_time.get_hour () == end_time.get_hour ()) && (start_time.get_minute () >= end_time.get_minute ())) {
                        to_time_picker.time = from_time_picker.time.add_hours (1);
                    }

                    if (start_time.get_hour () >= 23) {
                        to_date_picker.date = from_date_picker.date.add_days (1);
                    }
                }
            }
            break;
        case 1:
            break;
        }

        update_create_sensitivity ();
    }

    void update_create_sensitivity () {
        valid_event (is_valid_event ());
    }

    bool is_valid_event () {
        return title_entry.text != "" && is_valid_dates ();
    }

    bool is_valid_dates () {
        var start_date = from_date_picker.date;
        var end_date = to_date_picker.date;
        var start_time = from_time_picker.time;
        var end_time = to_time_picker.time;

        if (start_date.get_year () == end_date.get_year ()) {

            // Same year, compare dates.

            if (start_date.get_day_of_year () == end_date.get_day_of_year ()) {
                // Same date, compare times.

                // If it's all day, just return ok
                if (allday_switch.get_active ())
                    return true;

                if (start_time.get_hour () == end_time.get_hour ()) {
                    // Same hour, compare minutes
                    return start_time.get_minute () <= end_time.get_minute ();
                }

                // Different hour, start should be smaller
                return start_time.get_hour () < end_time.get_hour ();

            }

            // Same year but different day, start should be smaller.
            return start_date.get_day_of_year () < end_date.get_day_of_year ();

        }

        // Different years, start should be smaller.
        return start_date.get_year () < end_date.get_year ();
    }
}
