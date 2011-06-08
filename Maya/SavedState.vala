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

using Granite.Services;

namespace Maya {

	public class SavedState : Preferences {
	
		[Description(nick = "window-width", blurb = "The saved width of the window.")]
		public int window_width { get; set; default = 850; }
		
		[Description(nick = "window-height", blurb = "The saved height of the window.")]
		public int window_height { get; set; default = 550; }
		
		[Description(nick = "window-state", blurb = "The state of the window.")]
		public int window_state { get; set; default = 0; }
		
		[Description(nick = "hpaned-position", blurb = "The x coordinate of the hpaned dragger.")]
		public int hpaned_position { get; set; default = 650; }
		
		public SavedState () {
			base ();
		}
		
		public SavedState.with_file (string filename) {
			base.with_file (filename);
		}
		
	}
	
}
