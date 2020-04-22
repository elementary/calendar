/*-
 * Copyright (c) 2020 elementary, Inc. (https://elementary.io)
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
 * Authored by: Marco Betschart<elementary@marco.betschart.name>
 */

namespace Maya.Week {

    /**
     * TODO: Documentation
     * - https://gitlab.gnome.org/GNOME/gnome-calendar/-/blob/master/src/views/gcal-week-view.ui
     */
    public class View : Gtk.Box {

        /*
         * Event emitted when the day is double clicked or the ENTER key is pressed.
         */
        public signal void on_event_add (DateTime date);
        public signal void selection_changed (DateTime new_date);

        public DateTime? selected_date { get; private set; }

        internal static Gtk.CssProvider css_provider;

        private Sidebar sidebar;
        private Gtk.SizeGroup sidebar_sizegroup;
        private Grid grid;

        static construct {
            css_provider = new Gtk.CssProvider ();
            css_provider.load_from_resource ("/io/elementary/calendar/WeekView.css");
        }

        construct {
            selected_date = Settings.SavedState.get_default ().get_selected ();
            orientation = Gtk.Orientation.VERTICAL;

            var style_context = get_style_context ();
            style_context.add_class ("week-view");
            style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            sidebar_sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            sidebar = new Sidebar (sidebar_sizegroup);

            grid = new Grid ();
            grid.expand = true;

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.add (sidebar);
            box.add (grid);

            var viewport = new Gtk.Viewport (null, null);
            viewport.add (box);

            var scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.expand = true;
            scrolled_window.add (viewport);

            var header = new Header (sidebar_sizegroup);

            add (header);
            add (scrolled_window);

            update_hours_sidebar_size ();

            sync_with_model ();

            var model = Model.CalendarModel.get_default ();
            model.parameters_changed.connect (on_model_parameters_changed);

            model.events_added.connect (on_events_added);
            model.events_updated.connect (on_events_updated);
            model.events_removed.connect (on_events_removed);
        }

        private void update_hours_sidebar_size () {
            int hours_12_width, hours_24_width, sidebar_width;
            int hours_12_height, hours_24_height, cell_height;

            var style_context = get_style_context ();
            var state = style_context.get_state ();

            style_context.save ();
            style_context.add_class ("hours");

            Pango.FontDescription font_desc;
            style_context.@get (state, "font", out font_desc, null);
            var padding = style_context.get_padding (state);

            var pango_context = get_pango_context ();
            var pango_layout = new Pango.Layout (pango_context);
            pango_layout.set_font_description (font_desc);

            pango_layout.set_text (_("00 AM"), -1);
            pango_layout.get_pixel_size (out hours_12_width, out hours_12_height);

            pango_layout.set_text (_("00:00"), -1);
            pango_layout.get_pixel_size (out hours_24_width, out hours_24_height);

            sidebar_width = int.max (hours_12_width, hours_24_width) + padding.left + padding.right;
            cell_height = int.max (hours_12_height, hours_24_height) + padding.top + padding.bottom;

            style_context.restore ();

            /* Update the size requests */
            sidebar.set_size_request (sidebar_width, 48 * cell_height);

            /* Sync with the week header sidebar */
            //gcal_week_header_get_sidebar_size_group (GCAL_WEEK_HEADER (self->header));
            //gtk_size_group_add_widget (sidebar_sizegroup, self->hours_bar);
        }

        void on_events_added (E.Source source, Gee.Collection<ECal.Component> events) {
            Idle.add ( () => {
                foreach (var event in events)
                    add_event (source, event);

                return false;
            });
        }

        void on_events_updated (E.Source source, Gee.Collection<ECal.Component> events) {
            Idle.add ( () => {
                foreach (var event in events)
                    update_event (source, event);

                return false;
            });
        }

        void on_events_removed (E.Source source, Gee.Collection<ECal.Component> events) {
            Idle.add ( () => {
                foreach (var event in events)
                    remove_event (source, event);

                return false;
            });
        }

        /* Indicates the month has changed */
        void on_model_parameters_changed () {
            /*var model = Model.CalendarModel.get_default ();
            if (grid.grid_range != null && model.data_range.equals (grid.grid_range))
                return; // nothing to do

            Idle.add ( () => {
                remove_all_events ();
                sync_with_model ();
                return false;
            });*/
        }

        //--- Helper Methods ---//

        /* Sets the calendar widgets to the date range of the model */
        void sync_with_model () {
            /*
            var model = Model.CalendarModel.get_default ();
            if (grid.grid_range != null && (model.data_range.equals (grid.grid_range) || grid.grid_range.first_dt.compare (model.data_range.first_dt) == 0))
                return; // nothing to do

            DateTime previous_first = null;
            if (grid.grid_range != null)
                previous_first = grid.grid_range.first_dt;

            big_grid = create_big_grid ();
            stack.add (big_grid);

            header.update_columns (model.week_starts_on);
            weeks.update (model.data_range.first_dt, model.num_weeks);
            grid.set_range (model.data_range, model.month_start);

            // keep focus date on the same day of the month
            if (selected_date != null) {
                var bumpdate = model.month_start.add_days (selected_date.get_day_of_month () - 1);
                grid.focus_date (bumpdate);
            }

            if (previous_first != null) {
                if (previous_first.compare (grid.grid_range.first_dt) == -1) {
                    stack.transition_type = Gtk.StackTransitionType.SLIDE_UP;
                } else {
                    stack.transition_type = Gtk.StackTransitionType.SLIDE_DOWN;
                }
            }

            stack.set_visible_child (big_grid);  */
        }

        /* Render new event on the grid */
        void add_event (E.Source source, ECal.Component event) {
            critical ("add_event");
            //event.set_data ("source", source);
            grid.add_event (event);
        }

        /* Update the event on the grid */
        void update_event (E.Source source, ECal.Component event) {
           // grid.update_event (event);
        }

        /* Remove event from the grid */
        void remove_event (E.Source source, ECal.Component event) {
            //grid.remove_event (event);
        }

        /* Remove all events from the grid  */
        void remove_all_events () {
            //grid.remove_all_events ();
        }
    }
}
