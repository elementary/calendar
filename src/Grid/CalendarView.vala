// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Maxwell Barvian
 *              Corentin Noël <corentin@elementaryos.org>
 */

/**
 * Represents the entire calendar, including the headers, the week labels and the grid.
 */
public class Maya.View.CalendarView : Gtk.Grid {
    /*
     * Event emitted when the day is double clicked or the ENTER key is pressed.
     */
    public signal void on_event_add (DateTime date);
    public signal void selection_changed (DateTime new_date);

    public DateTime? selected_date { get; private set; }

    private WeekLabels weeks { get; private set; }
    private Header header { get; private set; }
    private Grid grid { get; private set; }
    private Gtk.Stack stack { get; private set; }
    private Gtk.Grid big_grid { get; private set; }
    private Gtk.Label spacer { get; private set; }
    private static GLib.Settings show_weeks;

    private static Gtk.CssProvider style_provider;

    static construct {
        style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("/io/elementary/calendar/WeekLabels.css");

        if (Application.wingpanel_settings != null) {
            show_weeks = Application.wingpanel_settings;
        } else {
            show_weeks = Application.saved_state;
        }
    }

    construct {
        selected_date = Maya.Application.get_selected_datetime ();
        big_grid = create_big_grid ();

        stack = new Gtk.Stack ();
        stack.add (big_grid);
        stack.show_all ();
        stack.expand = true;

        sync_with_store ();

        var store = Calendar.Store.get_event_store ();
        store.parameters_changed.connect (on_store_parameters_changed);

        store.components_added.connect (on_components_added);
        store.components_modified.connect (on_components_updated);
        store.components_removed.connect (on_components_removed);

        stack.notify["transition-running"].connect (() => {
            if (stack.transition_running == false) {
                stack.get_children ().foreach ((child) => {
                    if (child != stack.visible_child) {
                        child.destroy ();
                    }
                });
            }
        });

        show_weeks.changed["show-weeks"].connect (on_show_weeks_changed);
        show_weeks.get_value ("show-weeks");

        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.SCROLL_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        add (stack);
    }

    public Gtk.Grid create_big_grid () {
        spacer = new Gtk.Label ("");
        spacer.no_show_all = true;

        unowned Gtk.StyleContext spacer_context = spacer.get_style_context ();
        spacer_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        spacer_context.add_class ("weeks");

        weeks = new WeekLabels ();

        header = new Header ();
        grid = new Grid ();
        grid.focus_date (selected_date);
        grid.on_event_add.connect ((date) => on_event_add (date));
        grid.selection_changed.connect ((date) => {
            selected_date = date;
            selection_changed (date);
        });

        // Grid properties
        var new_big_grid = new Gtk.Grid ();
        new_big_grid.attach (spacer, 0, 0, 1, 1);
        new_big_grid.attach (header, 1, 0, 1, 1);
        new_big_grid.attach (grid, 1, 1, 1, 1);
        new_big_grid.attach (weeks, 0, 1, 1, 1);
        new_big_grid.show_all ();
        new_big_grid.expand = true;

        update_spacer_visible ();

        return new_big_grid;
    }

    public override bool scroll_event (Gdk.EventScroll event) {
        return GesturesUtils.on_scroll_event (event);
    }

    //--- Public Methods ---//

    public void today () {
        var today = Calendar.Util.datetime_strip_time (new DateTime.now_local ());
        var store = Calendar.Store.get_event_store ();
        var start = Calendar.Util.datetime_get_start_of_month (today);
        if (!start.equal (store.month_start))
            store.month_start = start;
        sync_with_store ();
        grid.focus_date (today);
    }

    //--- Signal Handlers ---//

    void on_show_weeks_changed () {
        var store = Calendar.Store.get_event_store ();
        weeks.update (store.data_range.first_dt, store.num_weeks);
        update_spacer_visible ();
    }

    private void update_spacer_visible () {
        if (show_weeks.get_boolean ("show-weeks")) {
            spacer.show ();
        } else {
            spacer.hide ();
        }
    }

    void on_components_added (Gee.Collection<ECal.Component> components, E.Source source, Gee.Collection<ECal.ClientView> views) {
        foreach (var component in components)
            add_component (source, component);
    }

    void on_components_updated (Gee.Collection<ECal.Component> components, E.Source source, Gee.Collection<ECal.ClientView> views) {
        foreach (var component in components)
            update_component (source, component);
    }

    void on_components_removed (Gee.Collection<ECal.Component> components, E.Source source, Gee.Collection<ECal.ClientView> views) {
        foreach (var component in components)
            remove_component (source, component);
    }

    /* Indicates the month has changed */
    void on_store_parameters_changed () {
        var store = Calendar.Store.get_event_store ();
        if (grid.grid_range != null && store.data_range.equals (grid.grid_range))
            return; // nothing to do

        Idle.add ( () => {
            remove_all_components ();
            sync_with_store ();
            return false;
        });
    }

    //--- Helper Methods ---//

    /* Sets the calendar widgets to the date range of the model */
    void sync_with_store () {
        var store = Calendar.Store.get_event_store ();
        if (grid.grid_range != null && (store.data_range.equals (grid.grid_range) || grid.grid_range.first_dt.compare (store.data_range.first_dt) == 0))
            return; // nothing to do

        DateTime previous_first = null;
        if (grid.grid_range != null)
            previous_first = grid.grid_range.first_dt;

        big_grid = create_big_grid ();
        stack.add (big_grid);

        header.update_columns (store.week_starts_on);
        weeks.update (store.data_range.first_dt, store.num_weeks);
        grid.set_range (store.data_range, store.month_start);

        // keep focus date on the same day of the month
        if (selected_date != null) {
            var bumpdate = store.month_start.add_days (selected_date.get_day_of_month () - 1);
            grid.focus_date (bumpdate);
        }

        if (previous_first != null) {
            if (previous_first.compare (grid.grid_range.first_dt) == -1) {
                stack.transition_type = Gtk.StackTransitionType.SLIDE_UP;
            } else {
                stack.transition_type = Gtk.StackTransitionType.SLIDE_DOWN;
            }
        }

        stack.set_visible_child (big_grid);
    }

    /* Render new event on the grid */
    void add_component (E.Source source, ECal.Component component) {
        component.set_data ("source", source);
        grid.add_component (component);
    }

    /* Update the event on the grid */
    void update_component (E.Source source, ECal.Component component) {
        grid.update_component (component);
    }

    /* Remove event from the grid */
    void remove_component (E.Source source, ECal.Component component) {
        grid.remove_component (component);
    }

    /* Remove all events from the grid */
    void remove_all_components () {
        grid.remove_all_components ();
    }
}
