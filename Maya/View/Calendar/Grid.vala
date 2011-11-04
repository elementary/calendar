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

	public class Grid : Gtk.Table {

		private Day[] days;

		public Grid (Gtk.CssProvider style_provider) {

			// Gtk.Table properties
			n_rows = 6;
			n_columns = 7;
			column_spacing = 0;
			row_spacing = 0;
			homogeneous = true;

			// Initialize days
			days = new Day[n_rows * n_columns];
			for (int row = 0; row < n_rows; row++)
				for (int col = 0; col < n_columns; col++) {
					var day = new Day (style_provider);
					days[row * n_columns + col] = day;
					attach_defaults (day, col, col + 1, row, row + 1);
				}
		}

		public void set_date (DateTime date, int days_to_prepend) {

			var date_to_index = days_to_prepend + date.get_day_of_month () - 1;
			days[date_to_index].grab_focus ();
		}

		public void update_month (int month, int year, int days_to_prepend) {

			var today = new DateTime.now_local ();

			var date = new DateTime.local (year, month, 1, 0, 0, 0).add_days (-days_to_prepend);

			foreach (var day in days) {
				if (date.get_day_of_year () == today.get_day_of_year () && date.get_year () == today.get_year ()) {
					day.name = "today";
					day.can_focus = true;
					day.sensitive = true;
				} else if (date.get_month () != month) {
					day.name = null;
					day.can_focus = false;
					day.sensitive = false;
				} else {
					day.name = null;
					day.can_focus = true;
					day.sensitive = true;
				}

				day.update_date (date);
				date = date.add_days (1);
			}
		}

	}

}

