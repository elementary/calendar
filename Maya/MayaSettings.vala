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

namespace Maya {

	public enum Weekday {
		MONDAY = 0,
		TUESDAY = 1,
		WEDNESDAY = 2,
		THURSDAY = 3,
		FRIDAY = 4,
		SATURDAY = 5,
		SUNDARY = 6
	}

	public class MayaSettings : Granite.Services.Settings {
	
		public Weekday week_starts_on { get; set; }
		
		public MayaSettings () {
			base ("org.elementary.Maya.Settings");
		}
	
	}
	
}

