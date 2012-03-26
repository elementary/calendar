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
public class Grid : Gtk.Grid {

    Gee.Map<DateTime, GridDay> data;

    public Util.DateRange grid_range { get; private set; }
    public DateTime? selected_date { get; private set; }

    /*
     * Event emitted when the day is double clicked or the ENTER key is pressed.
     */
    public signal void on_event_add (DateTime date);

    public signal void selection_changed (DateTime new_date);

    public Grid (Util.DateRange range, DateTime month_start, int weeks) {

        selected_date = new DateTime.now_local ();

        // Gtk.Grid properties
        insert_column (7);
        insert_row (weeks);
        set_column_homogeneous (true);
        set_row_homogeneous (true);
        column_spacing = 0;
        row_spacing = 0;

        data = new Gee.HashMap<DateTime, GridDay> (
            (HashFunc) DateTime.hash,
            (EqualFunc) Util.datetime_equal_func,
            null);

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

        Gee.List<DateTime> old_dates;
        if (grid_range == null)
            old_dates = new Gee.ArrayList<DateTime> ();
        else
            old_dates = grid_range.to_list();

        var new_dates = new_range.to_list();

        var data_new = new Gee.HashMap<DateTime, GridDay> (
            (HashFunc) DateTime.hash,
            (EqualFunc) Util.datetime_equal_func,
            null);

        // Assert that a valid number of weeks should be displayed
        assert (new_dates.size % 7 == 0);

        // Create new widgets for the new range

        int i=0;
        int col = 0, row = 0;

        for (i=0; i<new_dates.size; i++) {

            var new_date = new_dates [i];


            GridDay day;
            if (i < old_dates.size) {
                // A widget already exists for this date, just change it

                var old_date = old_dates [i];
                day = update_day (data[old_date], new_date, today, month_start);

            } else {
                // No widget exists, create one

                day = new GridDay (new_date);
                // Still update_day to get the color of etc. right
                day = update_day (day, new_date, today, month_start);

                attach (day, col, row, 1, 1);
                day.focus_in_event.connect ((event) => {
                    on_day_focus_in(day);
                    return false;
                });
                day.on_event_add.connect ((date) => on_event_add (date));
                day.show_all ();
            }

            col = (col+1) % 7;
            row = (col==0) ? row+1 : row;
            data_new.set (new_date, day);
        }

        // Destroy the widgets that are no longer used
        while (i < old_dates.size) {
            // There are widgets remaining that are no longer used, destroy them
            var old_date = old_dates [i];
            var old_day = data [old_date];

            old_day.destroy ();
            i++;
        }

        data.clear ();
        data.set_all (data_new);

        grid_range = new_range;
    }

    /**
     * Updates the given GridDay so that it shows the given date. Changes to its style etc.
     */
    GridDay update_day (GridDay day, DateTime new_date, DateTime today, DateTime month_start) {
        if (new_date.get_day_of_year () == today.get_day_of_year () && new_date.get_year () == today.get_year ()) {
            day.name = "today";
            if (new_date.get_month () == month_start.get_month ())
            {
                day.can_focus = true;
                day.sensitive = true;
            }

        } else if (new_date.get_month () != month_start.get_month ()) {
            day.name = null;
            day.can_focus = false;
            day.sensitive = false;

        } else {
            day.name = null;
            day.can_focus = true;
            day.sensitive = true;
        }

        day.update_date (new_date);

        return day;
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
