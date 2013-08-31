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

namespace Maya.View {

public enum EventType {
    ADD,
    EDIT
}

#if USE_GRANITE_DECORATED_WINDOW
public class EventDialog : Granite.Widgets.LightWindow {
#else
public class EventDialog : Gtk.Window {
#endif

        /**
         * The different widgets in the dialog.
         */
        private Gtk.Entry title_entry;
        private Granite.Widgets.HintedEntry location_entry;
        private Gtk.TextView comment_textview;
        private Maya.View.Widgets.GuestEntry guest_entry;
        private Granite.Widgets.DatePicker from_date_picker;
        private Granite.Widgets.DatePicker to_date_picker;
        private Gtk.Switch allday_switch;
        private Granite.Widgets.TimePicker from_time_picker;
        private Granite.Widgets.TimePicker to_time_picker;
        private Gtk.Button create_button;

        /**
         * A boolean indicating whether we can edit the current event.
         */
        private bool can_edit = true;

        public signal void response (bool response);

        private Gtk.Grid content_grid { get; private set; }

        private Gee.ArrayList<E.Source> sources;

        private Gtk.ComboBox calendar_box;

        public E.Source? source { get; private set; }
        public E.Source? original_source { get; private set; }

        public E.CalComponent ecal { get; private set; }

        public E.CalObjModType mod_type { get; private set; default = E.CalObjModType.ALL; }

        public EventType event_type { get; private set; }

        public EventDialog (Gtk.Window window, E.CalComponent ecal, E.Source? source = null, bool? add_event = false) {

            this.original_source = source;
            try {
                var registry = new E.SourceRegistry.sync (null);
                sources = new Gee.ArrayList<E.Source> ();
                foreach (var src in registry.list_sources(E.SOURCE_EXTENSION_CALENDAR)) {
                    if (src.writable == true) {
                        sources.add (src);
                    }
                }

                // Select the first calendar we can find, if none is default
                if (this.source == null) {
                    this.source = registry.default_calendar;
                }
            } catch (GLib.Error error) {
                critical (error.message);
            }

            this.ecal = ecal;

            if (add_event) {
                title = _("Add Event");
                event_type = EventType.ADD;
            } else {
                title = _("Edit Event");
                event_type = EventType.EDIT;
            }

            // Dialog properties
            //modal = true;
            window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
            //set_flags(Gtk.DialogFlags.DESTROY_WITH_PARENT);
            type_hint = Gdk.WindowTypeHint.DIALOG;
            transient_for = window;

            // Build dialog
            build_dialog (add_event);

            // Load the event's properties in to the dialog
            load ();

            update_create_sensitivity ();
        }

        //--- Public Methods ---//


        /**
         * Save the values in the dialog into the component.
         */
        public void save () {
            unowned iCal.icalcomponent comp = ecal.get_icalcomponent ();

            // Save the title
            comp.set_summary (title_entry.text);

            DateTime from_time = new DateTime.now_local();
            DateTime to_time = new DateTime.now_local();

            // Save the time
            if (allday_switch.get_active() == true ) {
                from_time = new DateTime.local(0, 0, 0, 0, 0, 0);
                to_time = new DateTime.local(0, 0, 0, 0, 0, 0);
            }
            else {
                from_time = from_time_picker.time;
                to_time = to_time_picker.time;
            }


            // Save the dates
            DateTime from_date = from_date_picker.date;
            DateTime to_date = to_date_picker.date;

            if (allday_switch.get_active())
                to_date = to_date.add_days (1);

            iCal.icaltimetype dt_start = Util.date_time_to_ical (from_date, from_time);
            iCal.icaltimetype dt_end = Util.date_time_to_ical (to_date, to_time);

            dt_start.is_date = 0;
            dt_end.is_date = 0;

            comp.set_dtstart (dt_start);

            comp.set_dtend (dt_end);

            // Save the location
            string location = location_entry.text;

            comp.set_location (location);

            // Save the guests
            // First, clear the guests
            int count = comp.count_properties (iCal.icalproperty_kind.ATTENDEE_PROPERTY);

            for (int i = 0; i < count; i++) {
                unowned iCal.icalproperty remove_prop = comp.get_first_property (iCal.icalproperty_kind.ATTENDEE_PROPERTY);

                comp.remove_property (remove_prop);
            }

            // Add the new guests
            Gee.ArrayList<string> addresses = guest_entry.get_addresses ();
            iCal.icalproperty property;
            foreach (string address in addresses) {
                property = new iCal.icalproperty (iCal.icalproperty_kind.ATTENDEE_PROPERTY);
                property.set_attendee (address);
                comp.add_property (property);
            }

            // First, clear the comments
            count = comp.count_properties (iCal.icalproperty_kind.COMMENT_PROPERTY);

            for (int i = 0; i < count; i++) {
                unowned iCal.icalproperty remove_prop = comp.get_first_property (iCal.icalproperty_kind.COMMENT_PROPERTY);

                comp.remove_property (remove_prop);
            }

            // Add the comment
            property = new iCal.icalproperty (iCal.icalproperty_kind.COMMENT_PROPERTY);
            property.set_comment (comment_textview.get_buffer ().text);
            comp.add_property (property);

            // Save the selected source
            string id = calendar_box.get_active_id ();

            foreach (E.Source possible_source in sources) {
                if (possible_source.dup_uid () == id) {
                    this.source = possible_source;
                    break;
                }
            }
            response (true);
        }

        //--- Helpers ---//

        /**
         * Populate the dialog's widgets with the component's values.
         */
        void load () {

            unowned iCal.icalcomponent comp = ecal.get_icalcomponent ();

            // Load the title
            string summary = comp.get_summary ();
            if (summary != null)
                title_entry.text = summary;

            // Load the dates
            iCal.icaltimetype dt_start = comp.get_dtstart ();
            iCal.icaltimetype dt_end = comp.get_dtend ();

            // Convert the dates
            DateTime to_date = Util.ical_to_date_time (dt_end);
            DateTime from_date = Util.ical_to_date_time (dt_start);

            // Is this all day
            bool allday = Util.is_the_all_day(from_date, to_date);

            if (dt_start.year != 0) {
                from_date_picker.date = from_date;
                from_time_picker.time = from_date;
            }

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

            // Load the location
            string location = comp.get_location ();
            if (location != null)
                location_entry.text = location;

            // Load the guests
            int count = comp.count_properties (iCal.icalproperty_kind.ATTENDEE_PROPERTY);

            unowned iCal.icalproperty property = comp.get_first_property (iCal.icalproperty_kind.ATTENDEE_PROPERTY);
            for (int i = 0; i < count; i++) {

                if (property.get_attendee () != null)
                    guest_entry.add_address (property.get_attendee ());

                property = comp.get_next_property (iCal.icalproperty_kind.ATTENDEE_PROPERTY);
            }

            property = comp.get_first_property (iCal.icalproperty_kind.COMMENT_PROPERTY);

            if (property != null) {
                Gtk.TextBuffer buffer = new Gtk.TextBuffer (null);
                buffer.text = property.get_comment ();
                comment_textview.set_buffer (buffer);
            }

            // Load the source
            calendar_box.set_active_id (this.source.dup_uid());
        }

        void build_dialog (bool add_event) {

            content_grid = new Gtk.Grid ();
            content_grid.margin_left = 12;
            content_grid.margin_right = 12;
            content_grid.margin_top = 12;
            content_grid.margin_bottom = 12;
            content_grid.set_row_spacing (6);
            content_grid.set_column_spacing (12);

            Gtk.Grid subgrid = new Gtk.Grid ();
            subgrid.set_sensitive (can_edit);
            subgrid.margin_left = 0;
            subgrid.margin_right = 0;
            subgrid.margin_top = 0;
            subgrid.margin_bottom = 0;
            subgrid.set_row_spacing (6);
            subgrid.set_column_spacing (12);

            var from_label = make_label (_("From:"));
            from_date_picker = make_date_picker ();
            from_date_picker.notify["date"].connect ( () => {on_date_modified(0);} );
            from_time_picker = make_time_picker ();
            from_time_picker.time_changed.connect ( () => {on_time_modified(0);} );

            var allday_label = new Gtk.Label (_("All day:"));
            allday_label.set_alignment (1.0f, 0.5f);

            allday_switch = new Gtk.Switch ();

            var to_label = make_label (_("To:"));

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

            var title_label = make_label (_("Title"));
            title_entry = new Granite.Widgets.HintedEntry (_("Name of Event"));
            title_entry.changed.connect(on_title_entry_modified);

            var calendar_label = make_label (_("Calendar"));

            var liststore = new Gtk.ListStore (2, typeof (string), typeof(string));

            var calcount = 0;
            // Add all the editable sources
            foreach (E.Source source in sources) {
                calcount++;
                liststore.insert_with_values (null, 0, 0, source.dup_display_name(), 1, source.dup_uid());
            }

            calendar_box = new Gtk.ComboBox.with_model (liststore);
            calendar_box.set_id_column (1);

            Gtk.CellRenderer cell = new Gtk.CellRendererText();
            calendar_box.pack_start( cell, false );
            calendar_box.set_attributes( cell, "text", 0 );

            var location_label = make_label (_("Location"));
            location_entry = new Granite.Widgets.HintedEntry (_("John Smith OR Example St."));

            var guest_label = make_label (_("Participants"));
            guest_entry = new Maya.View.Widgets.GuestEntry (_("Name or Email Address"));
            guest_entry.check_resize ();

            var comment_label = make_label (_("Comments"));
            comment_textview = new Gtk.TextView ();
            comment_textview.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);

            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.add (comment_textview);
            scrolled.height_request = 100;
            scrolled.set_vexpand(true);
            scrolled.set_hexpand(true);

            subgrid.attach (from_label, 0, 0, 4, 1);
            subgrid.attach (from_date_picker, 0, 1, 1, 1);
            subgrid.attach (from_time_picker, 1, 1, 1, 1);
            subgrid.attach (allday_label, 2, 1, 1, 1);
            subgrid.attach (allday_switch_grid, 3, 1, 1, 1);
            subgrid.attach (to_label, 0, 2, 2, 1);
            subgrid.attach (to_date_picker, 0, 3, 1, 1);
            subgrid.attach (to_time_picker, 1, 3, 1, 1);
            subgrid.attach (title_label, 0, 4, 1, 1);
            subgrid.attach (location_label, 1, 4, 3, 1);
            subgrid.attach (title_entry, 0, 5, 1, 1);
            subgrid.attach (location_entry, 1, 5, 3, 1);
            if (calcount > 1 && can_edit) {
                subgrid.attach (calendar_label, 0, 6, 4, 1);
                subgrid.attach (calendar_box, 0, 7, 4, 1);
            }
            subgrid.attach (guest_label, 0, 8, 4, 1);
            subgrid.attach (guest_entry, 0, 9, 4, 1);
            subgrid.attach (comment_label, 0, 10, 4, 1);
            subgrid.attach (scrolled, 0, 11, 4, 1);

            var buttonbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            buttonbox.set_layout (Gtk.ButtonBoxStyle.END);

            var cancel_button = new Gtk.Button.from_stock (Gtk.Stock.CANCEL);
            if (add_event) {
                create_button = new Gtk.Button.with_label (_("Create Event"));
            }
            else {
                create_button = new Gtk.Button.with_label (_("Save Changes"));
            }

            create_button.clicked.connect (save);
            cancel_button.clicked.connect (() => {response (false);this.destroy();});

            buttonbox.pack_end (cancel_button);
            buttonbox.pack_end (create_button);

            create_button.margin_right = 5;

            content_grid.attach (subgrid, 0, 0, 1, 1);
            content_grid.attach (buttonbox, 0, 1, 1, 1);

            this.add (content_grid);

            show_all();
        }

        Gtk.Label make_label (string text) {

            var label = new Gtk.Label ("<span weight='bold'>" + text + "</span>");
            label.use_markup = true;
            label.set_alignment (0.0f, 0.5f);

            return label;
        }

        Granite.Widgets.DatePicker make_date_picker () {

            var date_picker = new Granite.Widgets.DatePicker.with_format (Maya.Settings.DateFormat ());
            date_picker.width_request = 200;

            return date_picker;
        }

        Granite.Widgets.TimePicker make_time_picker () {

            var time_picker = new Granite.Widgets.TimePicker.with_format (Maya.Settings.TimeFormat ());
            time_picker.width_request = 120;

            return time_picker;
        }

        void on_title_entry_modified () {
            update_create_sensitivity ();
        }

        void on_date_modified (int index) {
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
            if (!this.can_edit) {
                create_button.sensitive = false;
                create_button.set_tooltip_text (_("This event can't be edited"));
                return;
            }

            create_button.sensitive = is_valid_event ();

            if (!is_valid_event())
                create_button.set_tooltip_text (_("Your event has to be named and has to have a valid date"));
            else
                create_button.set_tooltip_text ("");
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


}

