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

namespace Maya.View {

	public class MayaWindow : Gtk.Window {
		
		private Gtk.VBox vbox;
		public MayaToolbar toolbar { get; private set; }
		public Gtk.HPaned hpaned { get; private set; }
		public Calendar.View calendar { get; private set; }
		public Sidebar sidebar { get; private set; }
		
		public MayaWindow () {
			
			vbox = new Gtk.VBox (false, 0);
			toolbar = new MayaToolbar ();
			hpaned = new Gtk.HPaned ();
			calendar = new Calendar.View ();
			sidebar = new Sidebar ();
			
			// Window Properties
			title = "Maya";
			icon_name = "office-calendar";
			set_size_request (700, 400);
			
			// Initialize layout
			vbox.pack_start (toolbar, false, false, 0);
			vbox.pack_end (hpaned);

			hpaned.add (calendar);
			hpaned.add (sidebar);
			
			add (vbox);
		}
		
	}
	
}

