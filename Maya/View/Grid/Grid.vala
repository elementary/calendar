//
//  Copyright (C) 2011-2012 Maxwell Barvian
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

/**
 * Represents the entire date grid as a table.
 */
public class Grid : Gtk.Table {

    Gee.Map<DateTime, GridDay> data;

    public Util.DateRange grid_range { get; private set; }
    public DateTime? selected_date { get; private set; }

    public signal void selection_changed (DateTime new_date);

    public Grid (Util.DateRange range, DateTime month_start, int weeks) {

        grid_range = range;
        selected_date = new DateTime.now_local ();

        // Gtk.Table properties
        n_rows = weeks;
        n_columns = 7;
        column_spacing = 0;
        row_spacing = 0;
        homogeneous = true;

        data = new Gee.HashMap<DateTime, GridDay> (
            (HashFunc) DateTime.hash,
            (EqualFunc) Util.datetime_equal_func,
            null);

        int row=0, col=0;

        foreach (var date in range) {

            var day = new GridDay (date);
            data.set (date, day);

            attach_defaults (day, col, col + 1, row, row + 1);
            day.focus_in_event.connect ((event) => {
                on_day_focus_in(day);
                return false;
            });

            col = (col+1) % 7;
            row = (col==0) ? row+1 : row;
        }

        set_range (range, month_start);
    }

    void on_day_focus_in (GridDay day) {

        selected_date = day.date;

        selection_changed (selected_date);
    }

    public void focus_date (DateTime date) {

        debug(@"Setting focus to @ $(date)");

        data [date].grab_focus ();
    }

    /**
     * Sets the given range to be displayed in the grid. Note that the number of days
     * must remain the same.
     */
    public void set_range (Util.DateRange new_range, DateTime month_start) {

        var today = new DateTime.now_local ();

        var dates1 = grid_range.to_list();
        var dates2 = new_range.to_list();

        assert (dates1.size == dates2.size);

        var data_new = new Gee.HashMap<DateTime, GridDay> (
            (HashFunc) DateTime.hash,
            (EqualFunc) Util.datetime_equal_func,
            null);

        for (int i=0; i<dates1.size; i++) {

            var date1 = dates1 [i];
            var date2 = dates2 [i];

            assert (data.has_key(date1));

            var day = data [date1];

            if (date2.get_day_of_year () == today.get_day_of_year () && date2.get_year () == today.get_year ()) {
                day.name = "today";
                day.can_focus = true;
                day.sensitive = true;

            } else if (date2.get_month () != month_start.get_month ()) {
                day.name = null;
                day.can_focus = false;
                day.sensitive = false;

            } else {
                day.name = null;
                day.can_focus = true;
                day.sensitive = true;
            }

            day.update_date (date2);
            data_new.set (date2, day);
        }

        data.clear ();
        data.set_all (data_new);

        grid_range = new_range;
    }
    
    /**
     * Puts the given event on the grid at the given date.
     *
     * If the given date is not in the current range, nothing happens.
     */
    public void add_event_for_time(DateTime date, E.CalComponent event) {
        if (!grid_range.contains (date))
            return;
        GridDay grid_day = data[date];
        assert(grid_day != null);
        grid_day.add_event(event);
    }
    
    /**
     * Removes the given event from the grid.
     */
    public void remove_event (E.CalComponent event) {
        foreach(var grid_day in data.values) {
            grid_day.remove_event (event);
        }
    }
    
    /**
     * Removes all events from the grid.
     */
    public void remove_all_events () {
        foreach(var grid_day in data.values) {
            grid_day.clear_events ();
        }
    }
}

}
