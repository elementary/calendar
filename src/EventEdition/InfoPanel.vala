//
//  Copyright (C) 2011-2012 Jaap Broekhuizen
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

public class Maya.View.EventEdition.InfoPanel : Gtk.Grid {
    private Gtk.Entry title_entry;
    private Gtk.TextView comment_textview;
    private Granite.Widgets.DatePicker from_date_picker;
    private Granite.Widgets.DatePicker to_date_picker;
    private Gtk.Switch allday_switch;
    private Granite.Widgets.TimePicker from_time_picker;
    private Granite.Widgets.TimePicker to_time_picker;
    private Gee.ArrayList<E.Source> sources;
    private Gtk.ComboBox calendar_box;

    private EventDialog parent_dialog;

    public signal void valid_event (bool is_valid);

    public InfoPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;

        margin_left = 12;
        margin_right = 12;
        row_spacing = 6;
        column_spacing = 12;
        sensitive = parent_dialog.can_edit;

        try {
            var registry = new E.SourceRegistry.sync (null);
            sources = new Gee.ArrayList<E.Source> ();
            foreach (var src in registry.list_sources(E.SOURCE_EXTENSION_CALENDAR)) {
                if (src.writable == true) {
                    sources.add (src);
                }
            }

            // Select the first calendar we can find, if none is default
            if (parent_dialog.source == null) {
                parent_dialog.source = registry.default_calendar;
            }
        } catch (Error error) {
            critical (error.message);
        }

        var from_label = Maya.View.EventDialog.make_label (_("From:"));
        from_date_picker = make_date_picker ();
        from_date_picker.notify["date"].connect ( () => {on_date_modified(0);} );
        from_time_picker = make_time_picker ();
        from_time_picker.time_changed.connect ( () => {on_time_modified(0);} );

        var allday_label = new Gtk.Label (_("All day:"));
        allday_label.set_alignment (1.0f, 0.5f);

        allday_switch = new Gtk.Switch ();

        var to_label = Maya.View.EventDialog.make_label (_("To:"));

        var allday_switch_grid = new Gtk.Grid ();

        to_date_picker = make_date_picker ();
        to_date_picker.notify["date"].connect ( () => {on_date_modified(1);} );
        to_time_picker = make_time_picker ();
        to_time_picker.time_changed.connect ( () => {on_time_modified(1);} );

        allday_switch_grid.attach (allday_switch, 0, 0, 1, 1);

        allday_switch_grid.set_valign (Gtk.Align.CENTER);

        allday_switch.notify["active"].connect (() => {
            on_date_modified (1);
            from_time_picker.sensitive = !allday_switch.get_active ();
            to_time_picker.sensitive = !allday_switch.get_active ();
        });

        var title_label = Maya.View.EventDialog.make_label (_("Title:"));
        title_entry = new Gtk.Entry ();
        title_entry.placeholder_text = _("Name of Event");
        title_entry.changed.connect (on_title_entry_modified);

        var calendar_label = Maya.View.EventDialog.make_label (_("Calendar:"));

        var liststore = new Gtk.ListStore (2, typeof (string), typeof(string));

        uint calcount = 0;
        // Add all the editable sources
        foreach (E.Source src in sources) {
            calcount++;
            liststore.insert_with_values (null, 0, 0, src.dup_display_name(), 1, src.dup_uid());
        }

        calendar_box = new Gtk.ComboBox.with_model (liststore);
        calendar_box.set_id_column (1);

        Gtk.CellRenderer cell = new Gtk.CellRendererText();
        calendar_box.pack_start( cell, false );
        calendar_box.set_attributes( cell, "text", 0 );

        var comment_label = Maya.View.EventDialog.make_label (_("Comments:"));
        comment_textview = new Gtk.TextView ();
        comment_textview.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
        comment_textview.accepts_tab = false;
        comment_textview.get_style_context ().add_class (Gtk.STYLE_CLASS_ENTRY);
        comment_textview.set_border_window_size (Gtk.TextWindowType.LEFT, 2);
        comment_textview.set_border_window_size (Gtk.TextWindowType.RIGHT, 2);
        comment_textview.set_border_window_size (Gtk.TextWindowType.TOP, 2);
        comment_textview.set_border_window_size (Gtk.TextWindowType.BOTTOM, 2);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled.add (comment_textview);
        scrolled.height_request = 100;
        scrolled.expand = true;

        attach (from_label, 0, 2, 4, 1);
        attach (from_date_picker, 0, 3, 1, 1);
        attach (from_time_picker, 1, 3, 1, 1);
        attach (allday_label, 2, 3, 1, 1);
        attach (allday_switch_grid, 3, 3, 1, 1);
        attach (to_label, 0, 4, 2, 1);
        attach (to_date_picker, 0, 5, 1, 1);
        attach (to_time_picker, 1, 5, 1, 1);
        attach (title_label, 0, 0, 1, 1);
        attach (title_entry, 0, 1, 1, 1);
        if (calcount > 1 && parent_dialog.can_edit) {
            attach (calendar_label, 1, 0, 4, 1);
            attach (calendar_box, 1, 1, 4, 1);
        }
        attach (comment_label, 0, 10, 4, 1);
        attach (scrolled, 0, 11, 5, 1);

        load ();
    }

    /**
     * Save the values in the dialog into the component.
     */
    public void save () {
        unowned iCal.Component comp = parent_dialog.ecal.get_icalcomponent ();

        // Save the title
        comp.set_summary (title_entry.text);

        // Save the time
        if (allday_switch.get_active () == true) {
            iCal.TimeType dt_start = Util.date_time_to_ical (from_date_picker.date, new DateTime.local (2000, 12, 12, 0, 0, 0));
            iCal.TimeType dt_end = Util.date_time_to_ical (to_date_picker.date.add_days (1), new DateTime.local (2000, 12, 12, 0, 0, 0));

            dt_start.is_date = 0;
            dt_end.is_date = 0;

            comp.set_dtstart (dt_start);
            comp.set_dtend (dt_end);
        } else {
            iCal.TimeType dt_start = Util.date_time_to_ical (from_date_picker.date, from_time_picker.time);
            iCal.TimeType dt_end = Util.date_time_to_ical (to_date_picker.date, to_time_picker.time);

            dt_start.is_date = 0;
            dt_end.is_date = 0;

            comp.set_dtstart (dt_start);
            comp.set_dtend (dt_end);
        }

        // First, clear the comments
        int count = comp.count_properties (iCal.PropertyKind.COMMENT);
        for (int i = 0; i < count; i++) {
            unowned iCal.Property remove_prop = comp.get_first_property (iCal.PropertyKind.COMMENT);
            comp.remove_property (remove_prop);
        }

        // Add the comment
        var property = new iCal.Property (iCal.PropertyKind.COMMENT);
        property.set_comment (comment_textview.get_buffer ().text);
        comp.add_property (property);

        // Save the selected source
        string id = calendar_box.get_active_id ();
        foreach (E.Source possible_source in sources) {
            if (possible_source.dup_uid () == id) {
                parent_dialog.source = possible_source;
                break;
            }
        }
    }

    //--- Helpers ---//

    /**
     * Populate the dialog's widgets with the component's values.
     */
    void load () {
        if (parent_dialog.ecal != null) {
            unowned iCal.Component comp = parent_dialog.ecal.get_icalcomponent ();

            // Load the title
            string summary = comp.get_summary ();
            if (summary != null)
                title_entry.text = summary;

            // Load the dates
            iCal.TimeType dt_start = comp.get_dtstart ();
            iCal.TimeType dt_end = comp.get_dtend ();

            // Convert the dates
            DateTime to_date = Util.ical_to_date_time (dt_end);
            DateTime from_date = Util.ical_to_date_time (dt_start);

            if (dt_start.year != 0) {
                from_date_picker.date = from_date;
                from_time_picker.time = from_date;
                parent_dialog.date_time = from_date;
            }

            // Is this all day
            bool allday = Util.is_the_all_day(from_date, to_date);

            if (dt_end.year != 0) {
                // If it's an all day event, subtract 1 from the end date
                if (allday)
                    to_date = to_date.add_days (-1);
                to_date_picker.date = to_date;
                to_time_picker.time = to_date;
            }

            // Load the allday_switch
            if (dt_end.year != 0) {
                if (allday) {
                    allday_switch.set_active(true);
                    from_time_picker.sensitive = false;
                    to_time_picker.sensitive = false;
                }
            }

            unowned iCal.Property property = comp.get_first_property (iCal.PropertyKind.COMMENT);
            if (property != null) {
                Gtk.TextBuffer buffer = new Gtk.TextBuffer (null);
                buffer.text = property.get_comment ();
                comment_textview.set_buffer (buffer);
            }

            // Load the source
            calendar_box.set_active_id (parent_dialog.original_source.dup_uid ());
        } else {
            parent_dialog.ecal = new E.CalComponent ();
            parent_dialog.ecal.set_new_vtype (E.CalComponentVType.EVENT);

            from_date_picker.date = parent_dialog.date_time;
            from_time_picker.time = new DateTime.now_local ();
            to_date_picker.date = parent_dialog.date_time;
            to_time_picker.time = new DateTime.now_local ().add_hours (1);

            // Load the source
            calendar_box.set_active_id (parent_dialog.source.dup_uid ());
        }
    }

    Granite.Widgets.DatePicker make_date_picker () {
        var date_picker = new Granite.Widgets.DatePicker.with_format (Maya.Settings.DateFormat ());
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

                    if (start_time.get_hour () > end_time.get_hour ())
                        to_time_picker.time = from_time_picker.time.add_hours(1);

                    if ((start_time.get_hour () == end_time.get_hour ()) && (start_time.get_minute () >= end_time.get_minute ()))
                        to_time_picker.time = from_time_picker.time.add_hours(1);
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
        // TODO: is it possible to only keep the date or time from a DateTime?

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
                    return start_time.get_minute () < end_time.get_minute ();
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