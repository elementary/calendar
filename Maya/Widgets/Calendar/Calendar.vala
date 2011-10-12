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

	public class Calendar : Gtk.Table {

		private MayaWindow window;

		private DateHandler handler;

		private Day[] days;

		private int days_to_prepend {
			get {
				int days = 1 - handler.first_day_of_month + window.prefs.week_starts_on;
				return days > 0 ? 7 - days : -days;
			}
		}

		public Calendar (MayaWindow window, DateHandler handler) {

			this.window = window;
			this.handler = handler;

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
					var day = new Day (window);
					days[row * n_columns + col] = day;
					attach_defaults (day, col, col + 1, row, row + 1);
				}
			update_month ();

			// Signals and handlers
			handler.changed.connect (update_month);
			window.toolbar.month_switcher.left_clicked.connect (() => handler.add_month_offset (-1));
			window.toolbar.month_switcher.right_clicked.connect (() => handler.add_month_offset (1));
			window.toolbar.year_switcher.left_clicked.connect (() => handler.add_year_offset (-1));
			window.toolbar.year_switcher.right_clicked.connect (() => handler.add_year_offset (1));
			window.prefs.changed["week-starts-on"].connect (update_month);

			// Change today when it changes
			var today = new DateTime.now_local ();
			var tomorrow = today.add_full (0, 0, 1, -today.get_hour (), -today.get_minute (), -today.get_second ());
			var difference = tomorrow.to_unix() -today.to_unix();

			Timeout.add_seconds ((uint) difference, () => {
				if (handler.current_month == tomorrow.get_month () && handler.current_year == tomorrow.get_year ())
					update_month ();

				tomorrow = tomorrow.add_days (1);

				Timeout.add (1000 * 60 * 60 * 24, () => {
					if (handler.current_month == tomorrow.get_month () && handler.current_year == tomorrow.get_year ())
						update_month ();

					tomorrow = tomorrow.add_days (1);

					return true;
				});

				return false;
			});

			realize.connect (() => set_date (today));
		}

		~Calendar () {
			window.prefs.changed["week-starts-on"].disconnect (update_month);
		}

		public void focus_today () {
			set_date (new DateTime.now_local ());
		}

		public void set_date (DateTime date) {

			if (handler.current_month != date.get_month () || handler.current_year != date.get_year ())
				handler.add_full_offset (date.get_month () - handler.current_month, date.get_year () - handler.current_year);

			days[date_to_index (date.get_day_of_month ())].grab_focus ();
		}

		private void update_month () {

			var today = new DateTime.now_local ();
			int month = handler.current_month;
			int year = handler.current_year;

			var date = new DateTime.local (year, month, 1, 0, 0, 0).add_days (-days_to_prepend);

			// Update switcher text
			window.toolbar.month_switcher.text = handler.format ("%B");
			window.toolbar.year_switcher.text = handler.format ("%Y");

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

				day.date = date;
				date = date.add_days (1);
			}
		}



		private int date_to_index (int day_of_month) {
			return days_to_prepend + day_of_month - 1;
		}

	}

}

