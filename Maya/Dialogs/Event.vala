//  
//  Copyright (C) 2011 Maxwell Barvian
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

using Gtk;

using Granite.Widgets;

using Maya.Widgets;

namespace Maya.Dialogs {

	public class Event : Gtk.Dialog {
		
		Gtk.Container container;
		
		Gtk.ButtonBox button_box;
	 
		public Event (MayaWindow window) {
		
			// Dialog properties
			modal = true;
			window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
			transient_for = window;
			response.connect(on_response);
			
			// Build dialog
			this.build_dialog ();
				
		}
		
		private void build_dialog () {
		
		    container = (Gtk.Container) get_content_area ();
		    container.add (new Gtk.Label ("Hello y'all"));
		    
		    add_button (Gtk.Stock.APPLY, Gtk.ResponseType.APPLY);
		    add_button (Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL);
		    
		    set_default_response (Gtk.ResponseType.APPLY);
		    show_all();
		
		}
		
		public void set_fields () {
		    
		    //TODO: set field values
		    
		}
		
		private void on_response (int response_id) {
		    
		    if (response_id == Gtk.ResponseType.CANCEL)
		        close ();
		    
		}
		
	}
	
	public class AddEvent : Event {
	    
	    public AddEvent (MayaWindow window) {
	        
	        base(window);
	    
	        // Dialog properties
	        title = "Add Event";
	    
	    }
	    
	}
	
	public class EditEvent : Event {
	    
	    public EditEvent (MayaWindow window) {
	        
	        base(window);
	        
	        // Dialog Properties
	        title = "Edit Event";
	        
	    }
	    
	}
	
}

