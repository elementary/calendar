//  
//  Copyright (C) 2011 Jaap Broekhuizen
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

namespace Maya.Services {

	/**
	 *	DateTimeHandler:
	 *	This class calculates everything that has to do with
	 *	dates and times. It can, for example, calculate
	 *	the first day of the month.
	 */
	public class DateHandler : GLib.Object {
		
		// Signals
		public signal void changed ();

		private DateTime _date;
		public DateTime date { 
			get { return _date; }
			private set {
				_date = value;
				changed ();
			}
		}
		
		public int current_month {
			get { return date.get_month (); }
		}
		
		public int current_year {
			get { return date.get_year (); }
		}
		
		public int first_day_of_month {
			get { return (new DateTime.local (current_year, current_month, 1, 0, 0, 0)).get_day_of_week (); }
		}
		
		public DateHandler () {
		
			date = new DateTime.now_local ();
		}
		
		public void add_full_offset (int month, int year) {
			date = date.add_full (year, month, 0, 0, 0, 0);
		}
		
		public void add_month_offset (int offset) {
			date = date.add_months (offset);
		}
		
		public void add_year_offset (int offset) {
			date = date.add_years (offset);
		}
		
		public string format (string f) {
			return date.format (f);
		}
		
	}

}

