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

namespace Maya.Settings {

	public enum WindowState {
		NORMAL = 0,
		MAXIMIZED = 1,
		FULLSCREEN = 2
	}

	public class SavedState : Granite.Services.Settings {

		public int window_width { get; set; }
		public int window_height { get; set; }

		public WindowState window_state { get; set; }

		public bool show_weeks { get; set; }

		public int hpaned_position { get; set; }

		public SavedState () {
			base ("org.elementary.Maya.SavedState");
		}

	}

}

