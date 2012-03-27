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

	public class EventDialog : Gtk.Dialog {
		
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
        private Gtk.Widget create_button;

        private Granite.Widgets.TimePicker from_time_picker;
        private Granite.Widgets.TimePicker to_time_picker;

		private Gtk.Grid content_grid { get; private set; }

        public E.Source source { get; private set; }

        public E.CalComponent ecal { get; private set; }

        public E.CalObjModType mod_type { get; private set; default = E.CalObjModType.ALL; }

		public EventDialog (Gtk.Window window, Model.SourceManager? sourcemgr, E.CalComponent ecal, E.Source? source = null, bool? add_event = false) {
		
            this.source = source ?? sourcemgr.DEFAULT_SOURCE;
            this.ecal = ecal;

            if (add_event) {
	            title = _("Add Event");
            } else {
                title = _("Edit Event");
            }

			// Dialog properties
			//modal = true;
			window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
            //set_flags(Gtk.DialogFlags.DESTROY_WITH_PARENT);
			transient_for = window;
			
			// Build dialog
			build_dialog (add_event);

            // Load the event's properties in to the dialog
            load ();

            set_default_response(Gtk.ResponseType.APPLY);

            connect_signals ();
		}

        private void connect_signals () {
            this.response.connect (on_response);
        }

        private void on_response (Gtk.Dialog source, int response_id) {
            switch (response_id) {
            case Gtk.ResponseType.APPLY:
                save ();
                break;
            case Gtk.ResponseType.CLOSE:
                destroy ();
                break;
            }
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

            iCal.icaltimetype dt_start = Util.date_time_to_ical (from_date, from_time);
            iCal.icaltimetype dt_end = Util.date_time_to_ical (to_date, to_time);

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

            // Load the from date
            iCal.icaltimetype dt_start = comp.get_dtstart ();

            if (dt_start.year != 0) {
                DateTime from_date = Util.ical_to_date_time (dt_start);

                from_date_picker.date = from_date;
// TODO: wait for bugfix in granite to be able to do this
//                from_time_picker.time = from_date;
            }

            // Load the to date
            iCal.icaltimetype dt_end = comp.get_dtend ();

            if (dt_end.year != 0) {
                DateTime to_date = Util.ical_to_date_time (dt_end);

                to_date_picker.date = to_date;
//                to_time_picker.time = to_date;
            }

            // Load the allday_switch
            if (dt_end.year != 0) {
                DateTime to_date = Util.ical_to_date_time (dt_end);
                DateTime from_date = Util.ical_to_date_time (dt_start);
                if (Util.is_the_all_day(from_date, to_date) == true) {
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
        }

		void build_dialog (bool add_event) {
		    
		    var container = (Gtk.Container) get_content_area ();
            content_grid = new Gtk.Grid ();
            content_grid.set_vexpand(true);
            content_grid.set_hexpand(true);
		    content_grid.margin_left = 10;
		    content_grid.margin_right = 10;
		    content_grid.margin_top = 10;
		    
		    var from_label = make_label (_("From:"));
			from_date_picker = make_date_picker ();
			from_time_picker = make_time_picker ();
		    
		    var allday_label = new Gtk.Label (_("All day:"));
		    allday_label.margin_left = 10;
		    
		    allday_switch = new Gtk.Switch ();
		    
		    var to_expander = new Gtk.Expander ("<span weight='bold'>"+_("To:")+"</span>");
		    to_expander.use_markup = true;
		    to_expander.spacing = 10;
		    to_expander.margin_bottom = 10;
		    
		    var to_grid = new Gtk.Grid ();
		    
		    to_date_picker = make_date_picker ();
		    to_time_picker = make_time_picker ();
		    
		    to_grid.attach (to_date_picker, 0, 0, 1, 1);
		    to_grid.attach (to_time_picker, 1, 0, 1, 1);
		    
		    to_expander.add (to_grid);
		    
		    allday_switch.button_release_event.connect (() => { 
		        from_time_picker.sensitive = !from_time_picker.sensitive;
		        to_time_picker.sensitive = !to_time_picker.sensitive;
		        
		        return false;
		    });
		    
		    var title_label = make_label (_("Title"));
		    title_entry = new Granite.Widgets.HintedEntry (_("Name of Event"));
            title_entry.changed.connect(on_title_entry_modified);
		    
		    var location_label = make_label (_("Location"));
	        location_entry = new Granite.Widgets.HintedEntry (_("John Smith OR Example St."));
		    
		    var guest_label = make_label (_("Guests"));
			guest_entry = new Maya.View.Widgets.GuestEntry (_("Name or Email Address"));
            guest_entry.check_resize ();
			
			var comment_label = make_label (_("Comments"));
			comment_textview = new Gtk.TextView ();
			comment_textview.height_request = 100;
            comment_textview.vexpand = true;
		    
		    content_grid.attach (from_label, 0, 0, 4, 1);
		    content_grid.attach (from_date_picker, 0, 1, 1, 1);
		    content_grid.attach (from_time_picker, 1, 1, 1, 1);
		    content_grid.attach (allday_label, 2, 1, 1, 1);
		    content_grid.attach (allday_switch, 3, 1, 1, 1);
		    content_grid.attach (to_expander, 0, 2, 2, 1);
		    content_grid.attach (title_label, 0, 3, 1, 1);
		    content_grid.attach (location_label, 1, 3, 3, 1);
		    content_grid.attach (title_entry, 0, 4, 1, 1);
		    content_grid.attach (location_entry, 1, 4, 3, 1);
		    content_grid.attach (guest_label, 0, 5, 4, 1);
		    content_grid.attach (guest_entry, 0, 6, 4, 1);
		    content_grid.attach (comment_label, 0, 7, 4, 1);
		    content_grid.attach (comment_textview, 0, 8, 4, 1);
            container.add (content_grid);
		   
            if (add_event) {
		        create_button = add_button (_("Create Event"), Gtk.ResponseType.APPLY);
                create_button.sensitive = false;
            }
            else {
		        create_button = add_button (Gtk.Stock.OK, Gtk.ResponseType.APPLY);
            }
		    show_all();
		}
		
		Gtk.Label make_label (string text) {
		
		    var label = new Gtk.Label ("<span weight='bold'>" + text + "</span>");
		    label.use_markup = true;
			label.set_alignment (0.0f, 0.5f);
			label.margin_bottom = 10;
		    
		    return label;
		}
		
		Granite.Widgets.DatePicker make_date_picker () {
		    
		    var date_picker = new Granite.Widgets.DatePicker.with_format (Maya.Settings.DateFormat ());
			date_picker.width_request = 200;
            date_picker.notify["date"].connect (on_date_modified);
			
			return date_picker;
		}
		
		Granite.Widgets.TimePicker make_time_picker () {
		    
		    var time_picker = new Granite.Widgets.TimePicker.with_format (Maya.Settings.TimeFormat ());
		    time_picker.width_request = 120;
            time_picker.notify["time"].connect (on_date_modified);
		    
		    return time_picker;
		}

        void on_title_entry_modified () {
            update_create_sensitivity ();
        }

        void on_date_modified () {
            update_create_sensitivity ();
        }

        void update_create_sensitivity () {
            create_button.sensitive = is_valid_event ();
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

