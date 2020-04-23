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

namespace Maya.View {

    /**
     * TODO: Documentation
     * - https://gitlab.gnome.org/GNOME/gnome-calendar/-/blob/master/src/views/gcal-week-grid.c
     */
    public class WeekGrid : Gtk.Container {

        private Gdk.Window event_window;

        private DateTime active_date;
        private Maya.Util.DateRange date_range;

        /*
         * These fields are "cells" rather than minutes. Each cell
         * correspond to 30 minutes.
         */
        private int selection_start;
        private int selection_end;
        private int dnd_cell;

        private int today_column {
            get {
                DateTime today, week_start;
                int days_diff;

                // TODO

                return 3;
            }
        }

        construct {
            set_has_window (false);

            selection_start = -1;
            selection_end = -1;
            dnd_cell = -1;

            /* Setup the week view as a drag n' drop destination */
            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, null, Gdk.DragAction.MOVE);

            var style_context = get_style_context ();
            style_context.add_provider (WeekView.style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        public override void realize () {
            var parent_window = get_parent_window ();

            set_realized (true);
            set_window (parent_window);

            Gtk.Allocation allocation;
            get_allocation (out allocation);

            var attributes = Gdk.WindowAttr();
            attributes.window_type = Gdk.WindowType.CHILD;
            attributes.wclass = Gdk.WindowWindowClass.INPUT_ONLY;
            attributes.x = allocation.x;
            attributes.y = allocation.y;
            attributes.width = allocation.width;
            attributes.height = allocation.height;
            attributes.event_mask = get_events ();
            attributes.event_mask |= (Gdk.EventMask.BUTTON_PRESS_MASK |
                            Gdk.EventMask.BUTTON_RELEASE_MASK |
                            Gdk.EventMask.BUTTON1_MOTION_MASK |
                            Gdk.EventMask.POINTER_MOTION_HINT_MASK |
                            Gdk.EventMask.POINTER_MOTION_MASK |
                            Gdk.EventMask.ENTER_NOTIFY_MASK |
                            Gdk.EventMask.LEAVE_NOTIFY_MASK |
                            Gdk.EventMask.SCROLL_MASK |
                            Gdk.EventMask.SMOOTH_SCROLL_MASK);
            var attributes_mask = (Gdk.WindowAttributesType.X | Gdk.WindowAttributesType.Y);
            event_window = new Gdk.Window (parent_window, attributes, attributes_mask);
            register_window (event_window);
        }

        public override void unrealize () {
            if (event_window != null) {
                unregister_window (event_window);
                event_window.destroy ();
                event_window = null;
            }
            base.unrealize ();
        }

        public override void map () {
            if (event_window != null) {
                event_window.show ();
            }
            base.map ();
        }

        public override void unmap () {
            if (event_window != null) {
                event_window.hide ();
            }
            base.unmap ();
        }

        public override void size_allocate (Gtk.Allocation allocation) {
            DateTime week_start = null;
            //RangeTree overlaps;
            bool ltr;
            double minutes_height;
            double column_width;
            int i, x, y;

            /* Allocate the widget */
            set_allocation (allocation);

            ltr = get_direction () != Gtk.TextDirection.RTL;

            if (get_realized ()) {
                event_window.move_resize (allocation.x, allocation.y, allocation.width, allocation.height);
            }

            /* Preliminary calculations */
            minutes_height = allocation.height / WeekUtil.MINUTES_PER_DAY;
            column_width = allocation.width / 7.0;

            /* Temporary range tree to hold positioned events' indexes */
            //overlaps = gcal_range_tree_new ();

            //week_start =

            /*
             * Iterate through weekdays; we don't have to worry about events that
             * jump between days because they're already handled by GcalWeekHeader.
             */
             for (i = 0; i < 7; i++) {
                 // ...
             }
        }

        public override void get_preferred_height (out int minimum_height, out int natural_height) {
            int hours_12_height, hours_24_height, cell_height, height;

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
            pango_layout.get_pixel_size (null, out hours_12_height);

            pango_layout.set_text (_("00:00"), -1);
            pango_layout.get_pixel_size (null, out hours_24_height);

            cell_height = int.max (hours_12_height, hours_24_height) + padding.top + padding.bottom;
            height = cell_height * 48;

            style_context.restore ();

            /* Report the height */
            minimum_height = height;
            natural_height = height;
        }


        public override bool draw (Cairo.Context context) {
            var style_context = get_style_context ();
            var state = get_state_flags ();
            var ltr = get_direction () != Gtk.TextDirection.RTL;

            style_context.save ();
            style_context.add_class ("lines");

            var color = style_context.get_color (state);
            var padding = style_context.get_padding (state);

            context.set_source_rgba (color.red, color.green, color.blue, color.alpha);

            double x;
            int i, width, height, today_column;

            width = get_allocated_width ();
            height = get_allocated_height ();

            double column_width = width / 7.0;
            double minutes_height = height / WeekUtil.MINUTES_PER_DAY;

            context.set_line_width (0.65);

            /* First, draw the selection */
            if (selection_start != -1 && selection_end != -1) {
                int selection_height, column, start, end;

                start = selection_start;
                end = selection_end;

                /* Swap cells if needed */
                if (start > end) {
                    start = start + end;
                    end = start -end;
                    start = start - end;
                }

                column = start * 30 / WeekUtil.MINUTES_PER_DAY;
                selection_height = (end - start + 1) * 30 * (int)minutes_height;

                x = column * column_width;

                style_context.save ();
                style_context.set_state (state | Gtk.StateFlags.SELECTED);

                style_context.render_background (context, WeekUtil.aligned (x), Math.round ((start * 30 % WeekUtil.MINUTES_PER_DAY) * minutes_height), column_width, selection_height);

                style_context.restore ();
            }

            /* Drag and Drop highlight */
            if (dnd_cell != -1) {
                double cell_height;
                int column, row;

                cell_height = minutes_height * 30;
                column = dnd_cell / (WeekUtil.MINUTES_PER_DAY / 30);
                row = dnd_cell - column * 48;

                style_context.render_background (context, column * column_width, row * cell_height, column_width, cell_height);
            }

            /* Vertical lines */
            for (i = 0; i < 7; i++) {
                if (ltr) {
                    x = column_width * i;
                } else {
                    x = width - column_width * i;
                }

                context.move_to (WeekUtil.aligned (x), 0);
                context.rel_line_to (0, height);
            }

            /* Horizontal lines */
            for (i = 1; i < 24; i++) {
                context.move_to (0, WeekUtil.aligned ((height / 24.0) * i));
                context.rel_line_to (width, 0);
            }

            context.stroke ();

            /* Dashed lines between the vertical lines */
            context.set_dash (WeekUtil.dashed, 2);

            for (i = 0; i < 24; i++) {
                context.move_to (0, WeekUtil.aligned((height / 24.0) * i + (height / 48.0)));
                context.rel_line_to (width, 0);
            }

            context.stroke ();
            style_context.restore ();

            base.draw (context);

            /* Today column */
            // today_column = get_today_column (GCAL_WEEK_GRID (widget));
            // TODO: if (today_column != -1)

            return false;
        }

        public override void add (Gtk.Widget widget) {
            if (widget.get_parent () == null) {
                widget.set_parent (this);
            }
        }

        /**
         * Puts the given event on the grid.
         */
        public void add_event (E.Source source, ECal.Component event) {
            critical ("grid.add_event...");

            /*foreach (var grid_day in data.values) {
                if (Util.calcomp_is_on_day (event, grid_day.date)) {
                    var button = new EventButton (event);
                    grid_day.add_event_button (button);
                }
            } */
        }

        /**
         * Removes the given event from the grid.
         */
        public void remove_event (E.Source source, ECal.Component event) {
            critical ("grid.remove_event...");
            /*foreach (var grid_day in data.values) {
                grid_day.remove_event (event);
            }*/
        }

        /**
         * Removes all events from the grid.
         */
        public void remove_all_events () {
            critical ("grid.remove_all_events...");
            /*foreach (var grid_day in data.values) {
                grid_day.clear_events ();
            }*/
        }

        public override void remove (Gtk.Widget widget) {
            if (widget.get_parent () != null) {
                widget.unparent ();
            }
        }

        /*public override void forall (Gtk.Callback callback) {
            // TODO
        }*/
    }
}
