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
 * Represents the entire calendar, including the headers, the week labels and the grid.
 */
public class CalendarView : Gtk.Grid {

    Model.CalendarModel model;

    public WeekLabels weeks { get; private set; }
    public Header header { get; private set; }
    public Grid grid { get; private set; }

    /*
     * Event emitted when the day is double clicked or the ENTER key is pressed.
     */
    public signal void on_event_add (DateTime date);

    public bool show_weeks { get; set; }

    public CalendarView (Model.CalendarModel model, bool show_weeks) {

        this.model = model;
        this.show_weeks = show_weeks;

        weeks = new WeekLabels ();
        header = new Header ();
        grid = new Grid ();
        grid.on_event_add.connect ((date) => on_event_add (date));

        // Grid properties

        attach (header, 1, 0, 1, 1);
        attach (grid, 1, 1, 1, 1);
        attach (weeks, 0, 1, 1, 1);

        sync_with_model ();

        model.parameters_changed.connect (on_model_parameters_changed);
        notify["show-weeks"].connect (on_show_weeks_changed);

        model.events_added.connect (on_events_added);
        model.events_updated.connect (on_events_updated);
        model.events_removed.connect (on_events_removed);
    }



    //--- Public Methods ---//

    public void today () {
        var today = Util.strip_time (new DateTime.now_local ());
        sync_with_model ();
        grid.focus_date (today);
    }

    //--- Signal Handlers ---//

    void on_show_weeks_changed () {

        weeks.update (model.data_range.first, show_weeks, model.num_weeks);
    }

    void on_events_added (E.Source source, Gee.Collection<E.CalComponent> events) {

        Idle.add ( () => {

            foreach (var event in events)
                add_event (source, event);

            return false;
        });
    }

    void on_events_updated (E.Source source, Gee.Collection<E.CalComponent> events) {

        Idle.add ( () => {

            foreach (var event in events)
                update_event (source, event);

            return false;
        });
    }

    void on_events_removed (E.Source source, Gee.Collection<E.CalComponent> events) {

        Idle.add ( () => {

            foreach (var event in events)
                remove_event (source, event);

            return false;
        });
    }

    /* Indicates the month has changed */
    void on_model_parameters_changed () {

        if (grid.grid_range != null && model.data_range.equals (grid.grid_range))
            return; // nothing to do

        Idle.add ( () => {
            remove_all_events ();
            sync_with_model ();
            return false;
        });
    }

    //--- Helper Methods ---//

    /* Sets the calendar widgets to the date range of the model */
    void sync_with_model () {
        if (grid.grid_range != null && model.data_range.equals (grid.grid_range))
            return; // nothing to do

        header.update_columns (model.week_starts_on);
        weeks.update (model.data_range.first, show_weeks, model.num_weeks);

        grid.set_range (model.data_range, model.month_start);

        // keep focus date on the same day of the month
        if (grid.selected_date != null) {
            var bumpdate = model.month_start.add_days (grid.selected_date.get_day_of_month() - 1);
            grid.focus_date (bumpdate);
        }
    }

    /* Render new event on the grid */
    void add_event (E.Source source, E.CalComponent event) {

        event.set_data("source", source);
        grid.add_event (event);
    }

    /* Update the event on the grid */
    void update_event (E.Source source, E.CalComponent event) {
        remove_event (source, event);
        add_event (source, event);
    }

    /* Remove event from the grid */
    void remove_event (E.Source source, E.CalComponent event) {
        grid.remove_event (event);
    }

    /* Remove all events from the grid */
    void remove_all_events () {
        grid.remove_all_events ();
    }
}

}

