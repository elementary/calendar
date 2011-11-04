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

		private GridDay[] days;

		public Grid () {

			// Gtk.Table properties
			n_rows = 6;
			n_columns = 7;
			column_spacing = 0;
			row_spacing = 0;
			homogeneous = true;

			// Initialize days
			days = new GridDay[n_rows * n_columns];
			for (int row = 0; row < n_rows; row++)
				for (int col = 0; col < n_columns; col++) {
					var day = new GridDay ();
					days[row * n_columns + col] = day;
					attach_defaults (day, col, col + 1, row, row + 1);
				}
		}

        private static int days_to_prepend (int year, int month, int week_starts_on) {
            int fdom = (new DateTime.local (year, month, 1, 0, 0, 0)).get_day_of_week ();
            int days = 1 - fdom + week_starts_on;
            return days > 0 ? 7 - days : -days;
        }

		public void focus_date (DateTime date, int week_starts_on) {

            int dtp = days_to_prepend (date.get_year(), date.get_month(), week_starts_on);

			var date_to_index = dtp + date.get_day_of_month () - 1;
			days[date_to_index].grab_focus ();
		}

		public void update_month (int month, int year, int week_starts_on) {

			var today = new DateTime.now_local ();

            int dtp =  days_to_prepend (year, month, week_starts_on);
			var date = new DateTime.local (year, month, 1, 0, 0, 0).add_days (-dtp);

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

