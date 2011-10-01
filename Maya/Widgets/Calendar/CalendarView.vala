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

using Maya.Services;

namespace Maya.Widgets {

	public class CalendarView : Gtk.HBox {
	
		private MayaWindow window;
		private VBox box;
	
	    public Weeks weeks { get; private set; }
		public Header header { get; private set; }
		public Widgets.Calendar calendar { get; private set; }
		
		public DateHandler handler { get; private set; }
	
		public CalendarView (MayaWindow window) {
			
			this.window = window;
			
			handler = new DateHandler ();
			
			weeks = new Weeks (window, handler);
			header = new Header (window);
			calendar = new Widgets.Calendar (window, handler);
			
			handler = new DateHandler();
		
			// HBox properties
			spacing = 0;
			homogeneous = false;
			
		    box = new VBox(false,0);
			
			box.pack_start (header, false, false, 0);
			box.pack_end (calendar, true, true, 0);
			
			pack_start(weeks, false, false, 0);
			pack_end(box, true, true, 0);
		}
		
	}

}

