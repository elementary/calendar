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

namespace Maya.View {

public class Header : Gtk.EventBox {

    private Gtk.Table table;
    private Gtk.Label[] labels;

    public Header () {
        
        table = new Gtk.Table (1, 7, true);

        var style_provider = Maya.View.Utilities.get_css_provider ();
    
        // EventBox properties
        set_visible_window (true); // needed for style
        get_style_context ().add_provider (style_provider, 600);
        get_style_context ().add_class ("header");
        
        labels = new Gtk.Label[table.n_columns];
        for (int c = 0; c < table.n_columns; c++) {
            labels[c] = new Gtk.Label ("");
            labels[c].draw.connect (on_draw);
            table.attach_defaults (labels[c], c, c + 1, 0, 1);
        }
        
        add (table);
    }
    
    public void update_columns (int week_starts_on) {
        
        var date = new DateTime.now_local ();
        date = date.add_days (week_starts_on - date.get_day_of_week ());
        foreach (var label in labels) {
            label.label = date.format ("%A");
            date = date.add_days (1);
        }
    }
    
    private bool on_draw (Gtk.Widget widget, Cairo.Context cr) {
    
        Gtk.Allocation size;
        widget.get_allocation (out size);
        
        // Draw left border
        cr.move_to (0.5, size.height); // start in bottom left. 0.5 accounts for cairo's default stroke offset of 1/2 pixels
        cr.line_to (0.5, 0.5); // move to upper left corner
        
        cr.set_source_rgba (0.0, 0.0, 0.0, 0.25);
        cr.set_line_width (1.0);
        cr.set_antialias (Cairo.Antialias.NONE);
        cr.stroke ();
        
        return false;
    }
}

public class WeekLabels : Gtk.EventBox {

    private Gtk.Table table;
    private Gtk.Label[] labels;

    public WeekLabels () {

        table = new Gtk.Table (1, 6, false);
        table.row_spacing = 1;

        var style_provider = Maya.View.Utilities.get_css_provider ();

        // EventBox properties
        set_visible_window (true); // needed for style
        get_style_context().add_provider (style_provider, 600);
        get_style_context().add_class ("weeks");

        labels = new Gtk.Label[table.n_columns];
        for (int c = 0; c < table.n_columns; c++) {
            labels[c] = new Gtk.Label ("");
            labels[c].valign = Gtk.Align.START;
            table.attach_defaults (labels[c], 0, 1, c, c + 1);
        }

        add (Utilities.set_margins (table, 20, 0, 0, 0));
    }

    public void update (DateTime date, bool show_weeks) {

        if (show_weeks) {
            if (!visible)
                show ();

            var next = date;
            foreach (var label in labels) {
                label.label = next.get_week_of_year ().to_string();
                next = next.add_weeks (1);
            }
        } else {
            hide ();
        }
    }
}

public class Grid : Gtk.Table {

    private GridDay[] days;

    public signal void selection_changed (DateTime new_date);

    public Grid (DateTime date) {

        // Gtk.Table properties
        n_rows = 6;
        n_columns = 7;
        column_spacing = 0;
        row_spacing = 0;
        homogeneous = true;

        // Initialize days
        days = new GridDay[n_rows * n_columns];
        for (int row = 0; row < n_rows; row++) {
            for (int col = 0; col < n_columns; col++) {
                var day = new GridDay (date);
                day.focus_in_event.connect ((event) => {
                    on_day_focus_in(day);
                    return false;
                });
                days[row * n_columns + col] = day;
                attach_defaults (day, col, col + 1, row, row + 1);
            }
        }
    }

    void on_day_focus_in (GridDay day) {

        selection_changed (day.date);
    }

    private static int days_to_prepend (int year, int month, int week_starts_on) {

        int fdom = (new DateTime.local (year, month, 1, 0, 0, 0)).get_day_of_week ();
        int days = week_starts_on - fdom;
        return days > 0 ? 7 - days : -days;
    }

    public void focus_date (DateTime date, int week_starts_on) {

        int dtp = days_to_prepend (date.get_year(), date.get_month(), week_starts_on);

        var date_to_index = dtp + date.get_day_of_month () - 1;
        days[date_to_index].grab_focus ();
    }

    public void change_month (int month, int year, int week_starts_on) {

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

public class GridDay : Gtk.EventBox {

    public DateTime date { get; private set; }

    Gtk.Label label;
    Gtk.VBox vbox;

    public GridDay (DateTime date) {

        this.date = date;

        var style_provider = Maya.View.Utilities.get_css_provider ();

        vbox = new Gtk.VBox (false, 0);
        label = new Gtk.Label ("");

        // EventBox Properties
        can_focus = true;
        set_visible_window (true);
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        get_style_context ().add_provider (style_provider, 600);
        get_style_context ().add_class ("cell");

        label.halign = Gtk.Align.END;
        label.get_style_context ().add_provider (style_provider, 600);
        label.name = "date";
        vbox.pack_start (label, false, false, 0);

        add (Utilities.set_margins (vbox, 3, 3, 3, 3));

        // Signals and handlers
        button_press_event.connect (on_button_press);
        draw.connect (on_draw);
    }

    public void update_date (DateTime date) {

        this.date = date;
        label.label = date.get_day_of_month ().to_string ();
    }

    private bool on_button_press (Gdk.EventButton event) {

        grab_focus ();
        return true;
    }

    private bool on_draw (Gtk.Widget widget, Cairo.Context cr) {

        Gtk.Allocation size;
        widget.get_allocation (out size);

        // Draw left and top black strokes
        cr.move_to (0.5, size.height); // start in bottom left. 0.5 accounts for cairo's default stroke offset of 1/2 pixels
        cr.line_to (0.5, 0.5); // move to upper left corner
        cr.line_to (size.width + 0.5, 0.5); // move to upper right corner

        cr.set_source_rgba (0.0, 0.0, 0.0, 0.95);
        cr.set_line_width (1.0);
        cr.set_antialias (Cairo.Antialias.NONE);
        cr.stroke ();

        // Draw inner highlight stroke
        cr.rectangle (1.5, 1.5, size.width - 1.5, size.height - 1.5);
        cr.set_source_rgba (1.0, 1.0, 1.0, 0.2);
        cr.stroke ();

        return false;
    }
}

public class CalendarView : Gtk.HBox {

    /* Indicates that selected date in grid has changed */
    public signal void selection_changed (DateTime new_date);

    DateTime selected_date;
    Gtk.VBox box;
    Model.CalendarModel model;

    public WeekLabels weeks { get; private set; }
    public Header header { get; private set; }
    public Grid grid { get; private set; }

    public bool show_weeks { get; set; }
    
    public CalendarView (Model.CalendarModel model, bool show_weeks) {

        this.model = model;
        this.show_weeks = show_weeks;

        weeks = new WeekLabels ();
        header = new Header ();
        grid = new Grid (model.target);
        grid.selection_changed.connect (on_grid_selection_changed);
        
        // HBox properties
        spacing = 0;
        homogeneous = false;
        
        box = new Gtk.VBox(false,0);
        box.pack_start (header, false, false, 0);
        box.pack_end (grid, true, true, 0);
        
        pack_start(weeks, false, false, 0);
        pack_end(box, true, true, 0);

        set_date (model.target);

        model.parameters_changed.connect (on_model_parameters_changed);
        notify["show_weeks"].connect (on_show_weeks_changed);
    }

    void set_date (DateTime date) {

        debug (@"Setting focus date to $(model.target)");

        header.update_columns (model.week_starts_on);
        weeks.update (date, show_weeks);
        grid.change_month (date.get_month(), date.get_year(), model.week_starts_on);
        grid.focus_date (date, model.week_starts_on);
    }

    // Signal Handlers (Private)

    void on_grid_selection_changed (DateTime new_date) {

        debug (@"Selection changed to $(new_date)");

        selected_date = new_date;

        selection_changed (new_date);
    }

    void on_show_weeks_changed () {

        weeks.update (model.target, show_weeks);
    }

    // Signal Handlers

    public void on_source_loaded (E.Source source) {

        remove_source_events (source);
        add_source_events (source, model.get_events (source));
    }

    public void on_model_parameters_changed () {
        debug ("on_model_parameters_changed");

        if (model.target == selected_date)
            return;

        remove_all_events ();

        set_date (model.target);
    }

    // TODO: implement these private methods

    /* Render the events for the source in the grid */
    void add_source_events (E.Source source, Gee.Set<E.CalComponent> events) {
    }

    /* Removes all events for source from the grid */
    void remove_source_events (E.Source source) {
    }

    void remove_all_events () {
    }
}

}

