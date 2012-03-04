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

public class Header : Gtk.EventBox {

    private Gtk.Table table;
    private Gtk.Label[] labels;

    public Header () {
        
        table = new Gtk.Table (1, 7, true);

        var style_provider = Util.Css.get_css_provider ();
    
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
        
        var date = Util.strip_time(new DateTime.now_local ());
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

        var style_provider = Util.Css.get_css_provider ();

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

        add (Util.set_margins (table, 20, 0, 0, 0));
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

    Gee.Map<DateTime, GridDay> data;

    public Util.DateRange grid_range { get; private set; }
    public DateTime? selected_date { get; private set; }

    public signal void selection_changed (DateTime new_date);
    public signal void removed (E.CalComponent comp);
    public signal void modified (E.CalComponent comp);

    public Grid (Util.DateRange range, DateTime month_start, int weeks) {

        grid_range = range;
        selected_date = new DateTime.now_local();

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
            day.removed.connect ( (e) => { removed (e); });
            day.modified.connect ( (e) => { modified (e); });
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
        warning(@"selection: @ $(day.date)");
        selection_changed (selected_date);
    }

    public void focus_date (DateTime date) {

        debug(@"Setting focus to @ $(date)");

        data [date].grab_focus ();
    }

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
    
    public void add_event_for_time(DateTime date, E.CalComponent event) {
        GridDay grid_day = data[date];
        assert(grid_day != null);
        grid_day.add_event(event);
    }
    
    public void remove_event (E.CalComponent event) {
        foreach(var grid_day in data.values) {
            grid_day.remove_event (event);
        }
    }
    
    public void remove_all_events () {
        foreach(var grid_day in data.values) {
            grid_day.clear_events ();
        }
    }
}

class EventButton : Gtk.Grid {
    public E.CalComponent comp;
    public signal void removed (E.CalComponent comp);
    public signal void modified (E.CalComponent comp);
    
    Gtk.Label label;
    Gtk.Button close_button;
    Gtk.Button edit_button;
    public EventButton (E.CalComponent comp) {
        
        E.CalComponentText ct;
        this.comp = comp;
        comp.get_summary (out ct);
        label = new Granite.Widgets.WrapLabel(ct.value);
        add (label);
        label.hexpand = true;
        close_button = new Gtk.Button ();
        edit_button = new Gtk.Button ();
        close_button.add (new Gtk.Image.from_stock ("gtk-close", Gtk.IconSize.MENU));
        edit_button.add (new Gtk.Image.from_stock ("gtk-edit", Gtk.IconSize.MENU));
        close_button.set_relief (Gtk.ReliefStyle.NONE);
        edit_button.set_relief (Gtk.ReliefStyle.NONE);
        
        add (edit_button);
        add (close_button);
        
        close_button.clicked.connect( () => { removed(comp); });
        edit_button.clicked.connect( () => { modified(comp); });
    }
}

public class GridDay : Gtk.EventBox {

    public DateTime date { get; private set; }

    Gtk.Label label;
    Gtk.VBox vbox;
    List<EventButton> event_buttons;
    
    public signal void removed (E.CalComponent event);
    public signal void modified (E.CalComponent event);

    public GridDay (DateTime date) {

        this.date = date;
        event_buttons = new List<EventButton>();

        var style_provider = Util.Css.get_css_provider ();

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

        add (Util.set_margins (vbox, 3, 3, 3, 3));

        // Signals and handlers
        button_press_event.connect (on_button_press);
        draw.connect (on_draw);
    }
    
    public void add_event(E.CalComponent comp) {
        var button = new EventButton(comp);
        vbox.pack_start (button, false, false, 0);
        vbox.show_all();
        event_buttons.append(button);
        
        button.removed.connect ( (e) => { removed (e); });
        button.modified.connect ( (e) => { modified (e); });
    }
    
    public void remove_event (E.CalComponent comp) {
        foreach(var button in event_buttons) {
            if(comp == button.comp) {
                event_buttons.remove(button);
                button.destroy();
                break;
            }
        }
    }
    
    public void clear_events () {
        foreach(var button in event_buttons) {
            button.destroy();
        }
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
        grid = new Grid (model.data_range, model.month_start, model.num_weeks);
        grid.removed.connect (on_remove);
        grid.modified.connect (on_modified);
        
        // HBox properties
        spacing = 0;
        homogeneous = false;
        
        box = new Gtk.VBox (false,0);
        box.pack_start (header, false, false, 0);
        box.pack_end (grid, true, true, 0);
        
        pack_start(weeks, false, false, 0);
        pack_end(box, true, true, 0);

        sync_with_model ();

        model.parameters_changed.connect (on_model_parameters_changed);
        notify["show_weeks"].connect (on_show_weeks_changed);

        model.events_added.connect (on_events_added);
        model.events_updated.connect (on_events_updated);
        model.events_removed.connect (on_events_removed);
    }
    
    public void on_remove(E.CalComponent comp) {
        model.remove_event(comp.get_data<E.Source>("source"), comp, E.CalObjModType.THIS);
    }
    
    public void on_modified(E.CalComponent comp) {
        var dialog = new Maya.View.EditEventDialog2 ((Gtk.Window)get_toplevel(), comp.get_data<E.Source>("source"), comp);
        dialog.show_all();
        dialog.run();
        dialog.destroy ();
        model.update_event(comp.get_data<E.Source>("source"), comp, E.CalObjModType.THIS);
    }

    //--- Public Methods ---//
    
    public void today () {

        var today = Util.strip_time (new DateTime.now_local ());
        grid.focus_date (today);
    }

    //--- Signal Handlers ---//

    void on_show_weeks_changed () {

        weeks.update (model.data_range.first, show_weeks);
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

        if (model.data_range.equals (grid.grid_range))
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

        header.update_columns (model.week_starts_on);
        weeks.update (model.data_range.first, show_weeks);

        grid.set_range (model.data_range, model.month_start);

        // keep focus date on the same day of the month
        if (grid.selected_date != null) {
            var bumpdate = model.month_start.add_days (grid.selected_date.get_day_of_month() - 1);
            grid.focus_date (bumpdate);
        }
    }

    /* TODO: Render new event on the grid */
    void add_event (E.Source source, E.CalComponent event) {

        E.CalComponentDateTime date_time;
        event.set_data("source", source);
        event.get_dtend (out date_time);
        var dt = new DateTime(new TimeZone.local(), date_time.value.year, date_time.value.month, date_time.value.day, 0, 0, 0);
        grid.add_event_for_time (dt, event);
    }

    /* TODO: Update the event on the grid */
    void update_event (E.Source source, E.CalComponent event) {
        remove_event (source, event);
        add_event (source, event);
    }

    /* TODO: Remove event from the grid */
    void remove_event (E.Source source, E.CalComponent event) {
        grid.remove_event (event);
    }

    /* TODO: Remove all events from the grid */
    void remove_all_events () {
        grid.remove_all_events ();
    }
}

}

