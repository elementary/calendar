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
        Gtk.Entry title_entry;
        Granite.Widgets.HintedEntry location_entry;
        Gtk.TextView comment;
        Granite.Widgets.DatePicker from_date_picker;
        Granite.Widgets.DatePicker to_date_picker;
        Gtk.Switch allday;

        Granite.Widgets.TimePicker from_time_picker;
        Granite.Widgets.TimePicker to_time_picker;

		Gtk.Container container { get; private set; }

        public E.Source source { get; private set; }

        public E.CalComponent ecal { get; private set; }

        public E.CalObjModType mod_type { get; private set; default = E.CalObjModType.ALL; }

		public EventDialog (Gtk.Window window, Model.SourceManager? sourcemgr, E.CalComponent ecal, E.Source? source = null) {
		
            this.source = source ?? sourcemgr.DEFAULT_SOURCE;
            this.ecal = ecal;

			// Dialog properties
			modal = true;
			window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
			transient_for = window;
			
			// Build dialog
			build_dialog ();

            // Load the event's properties in to the dialog
            load ();

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
            if (allday.get_active() == true ) {
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

            // TODO: save guests, comments, location

            // Save the location
            string location = location_entry.text;

            comp.set_location (location);
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

            // Load the allday
            if (dt_end.year != 0) {
                DateTime to_date = Util.ical_to_date_time (dt_end);
                DateTime from_date = Util.ical_to_date_time (dt_start);
                if ((to_date.get_hour() == to_date.get_minute()) && (from_date.get_hour() == to_date.get_hour()) && (from_date.get_hour() == from_date.get_minute()) && (to_date.get_hour() == 0)) {
                    allday.set_active(true);
                    from_time_picker.sensitive = false;
		            to_time_picker.sensitive = false;
                }
            }
           

            // Load the location
            string location = comp.get_location ();
            if (location != null)
                location_entry.text = location;

            // TODO: load guests, comments, all day toggle

        }

		void build_dialog () {
		    
		    container = (Gtk.Container) get_content_area ();
		    container.margin_left = 10;
		    container.margin_right = 10;
		    
		    var from_box = make_hbox ();
		    
		    var from = make_label ("From:");
			from_date_picker = make_date_picker ();
			from_time_picker = make_time_picker ();
			
			from_box.add (from_date_picker);
			from_box.add (from_time_picker);
		    
		    var switch_label = new Gtk.Label ("All day:");
		    switch_label.margin_right = 20;
		    
		    allday = new Gtk.Switch ();
		    
		    from_box.add (switch_label);
		    from_box.add (allday);
		    
		    var to = new Gtk.Expander ("<span weight='bold'>To:</span>");
		    to.use_markup = true;
		    to.spacing = 10;
		    to.margin_bottom = 10;
		    
		    var to_box = make_hbox ();
		    
		    to_date_picker = make_date_picker ();
		    to_time_picker = make_time_picker ();
		    
		    to_box.pack_start (to_date_picker, false, false, 0);
		    to_box.pack_start (to_time_picker, false, false, 0);
		    
		    to.add (to_box);
		    
		    allday.button_release_event.connect (() => { 
		        from_time_picker.sensitive = !from_time_picker.sensitive;
		        to_time_picker.sensitive = !to_time_picker.sensitive;
		        
		        return false;
		    });
		    
		    var title_location_box = make_hbox ();
		    
		    var title_box = new Gtk.VBox (false, 0);
		    
		    var title_label = make_label ("Title");
		    title_entry = new Granite.Widgets.HintedEntry ("Name of Event");

		    title_box.add (title_label);
		    title_box.add (title_entry);
		    
		    var location_box = new Gtk.VBox (false, 0);
		    
		    var location_label = make_label ("Location");
	        location_entry = new Granite.Widgets.HintedEntry ("John Smith OR Example St.");
	        
		    location_box.add (location_label);
		    location_box.add (location_entry);
		    
		    title_location_box.add (title_box);
		    title_location_box.add (location_box);
		    
		    var guest_box = make_vbox ();
		    
		    var guest_label = make_label ("Guests");
			var guest = new Granite.Widgets.HintedEntry ("Name or Email Address");
			
			guest_box.add (guest_label);
			guest_box.add (guest);
			
			var comment_box = new Gtk.VBox (false, 0);
			comment_box.margin_bottom = 20;
			
			var comment_label = make_label ("Comments");
			comment_box.add (comment_label);
			
			comment = new Gtk.TextView ();
			comment.height_request = 100;
			comment_box.add (comment);
		    
		    container.add (from);
		    container.add (from_box);
		    container.add (to);
		    container.add (title_location_box);
		    container.add (guest_box);
		    container.add (comment_box);
		   
            if (this is AddEventDialog) {
		        add_button ("Create Event", Gtk.ResponseType.APPLY);
            }
            else {
		        add_button (Gtk.Stock.OK, Gtk.ResponseType.APPLY);
            }
		    
		    set_default_response (Gtk.ResponseType.APPLY);
		    show_all();
		}

		Gtk.HBox make_hbox () {
		    
		    var box = new Gtk.HBox (false, 10);
		    box.margin_bottom = 10;
		
		    return box;
		}
		
		Gtk.VBox make_vbox () {
		
		    var box = new Gtk.VBox (false, 0);
		    box.margin_bottom = 10;
		    
		    return box;
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
			
			return date_picker;
		}
		
		Granite.Widgets.TimePicker make_time_picker () {
		    
		    var time_picker = new Granite.Widgets.TimePicker.with_format (Maya.Settings.TimeFormat ());
		    time_picker.width_request = 80;
		    
		    return time_picker;
		}
	}
	
	public class AddEventDialog : EventDialog {
	    
	    public AddEventDialog (Gtk.Window window, Model.SourceManager sourcemgr, E.CalComponent event) {
	        
	        base(window, sourcemgr, event);
	    
	        // Dialog properties
	        title = "Add Event";
	    }
	}
	
	public class EditEventDialog : EventDialog {
	 
	    public EditEventDialog (Gtk.Window window, Model.SourceManager sourcemgr, E.CalComponent event) {
	        
	        base(window, sourcemgr, event);
	        
	        // Dialog Properties
	        title = "Edit Event";
	    }
	}
	
	public class EditEventDialog2 : EventDialog {
	 
	    public EditEventDialog2 (Gtk.Window window, E.Source source, E.CalComponent event) {
	        
	        base(window, null, event, source);
	        
	        // Dialog Properties
	        title = "Edit Event";
	    }
	}
}

