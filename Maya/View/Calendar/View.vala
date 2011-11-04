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

namespace Maya.View.Calendar {

	public class View : Gtk.HBox {
	
		private Gtk.VBox box;
	
	    public Weeks weeks { get; private set; }
		public Header header { get; private set; }
		public Grid grid { get; private set; }
		
		public View (Gtk.CssProvider style_provider) {
			
			weeks = new Weeks (style_provider);
			header = new Header (style_provider);
			grid = new Grid (style_provider);
			
			// HBox properties
			spacing = 0;
			homogeneous = false;
			
		    box = new Gtk.VBox(false,0);
			
			box.pack_start (header, false, false, 0);
			box.pack_end (grid, true, true, 0);
			
			pack_start(weeks, false, false, 0);
			pack_end(box, true, true, 0);
		}
		
	}

}

