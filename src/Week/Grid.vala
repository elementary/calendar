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
     * - https://gitlab.gnome.org/GNOME/gnome-calendar/-/blob/master/src/views/gcal-week-grid.c
     */
    public class Grid : Gtk.Container {

        private Gdk.Window event_window;
        private const double dashed[] = { 5.0, 6.0 };

        private int today_column {
            get {
                DateTime today, week_start;
                int days_diff;

                // TODO

                return 3;
            }
        }


/*
  GtkContainerClass *container_class = GTK_CONTAINER_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  container_class->add = gcal_week_grid_add;
  container_class->remove = gcal_week_grid_remove;
  container_class->forall = gcal_week_grid_forall;

  object_class->finalize = gcal_week_grid_finalize;
  object_class->get_property = gcal_week_grid_get_property;
  object_class->set_property = gcal_week_grid_set_property;

  widget_class->draw = gcal_week_grid_draw;
  widget_class->size_allocate = gcal_week_grid_size_allocate;
  widget_class->realize = gcal_week_grid_realize;
  widget_class->unrealize = gcal_week_grid_unrealize;
  widget_class->map = gcal_week_grid_map;
  widget_class->unmap = gcal_week_grid_unmap;
  widget_class->get_preferred_height = gcal_week_grid_get_preferred_height;
  widget_class->button_press_event = gcal_week_grid_button_press;
  widget_class->motion_notify_event = gcal_week_grid_motion_notify_event;
  widget_class->button_release_event = gcal_week_grid_button_release;
  widget_class->drag_motion = gcal_week_grid_drag_motion;
  widget_class->drag_leave = gcal_week_grid_drag_leave;
  widget_class->drag_drop = gcal_week_grid_drag_drop;

  signals[EVENT_ACTIVATED] = g_signal_new ("event-activated",
                                           GCAL_TYPE_WEEK_GRID,
                                           G_SIGNAL_RUN_FIRST,
                                           0,  NULL, NULL, NULL,
                                           G_TYPE_NONE,
                                           1,
                                           GCAL_TYPE_EVENT_WIDGET);

  gtk_widget_class_set_css_name (widget_class, "weekgrid");
  */

        public override void realize () {
            var parent_window = get_parent_window ();

            set_realized (true);
            set_window (parent_window);

            Gtk.Allocation allocation;
            get_allocation (out allocation);

            var attributes = new Gdk.WindowAttr();
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
            minutes_height = allocation.height / Util.MINUTES_PER_DAY;
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
            double minutes_height = height / Util.MINUTES_PER_DAY;

            context.set_line_width (0.65);

            /* First, draw the selection */
            // TODO: if (self->selection_start != -1 && self->selection_end != -1)

            /* Drag and Drop highlight */
            // TODO: if (self->dnd_cell != -1)

            /* Vertical lines */
            for (i = 0; i < 7; i++) {
                if (ltr) {
                    x = column_width * i;
                } else {
                    x = width - column_width * i;
                }

                context.move_to (Util.aligned (x), 0);
                context.line_to (0, height);
            }

            /* Horizontal lines */
            for (i = 1; i < 24; i++) {
                context.move_to (0, Util.aligned ((height / 24.0) * i));
                context.line_to (width, 0);
            }

            context.stroke ();

            /* Dashed lines between the vertical lines */
            context.set_dash (Grid.dashed, 2);

            for (i = 0; i < 24; i++) {
                context.move_to (0, Util.aligned((height / 24.0) * i + (height / 48.0)));
                context.line_to (width, 0);
            }

            context.stroke ();
            context.restore ();

            base.draw (context);

            /* Today column */
            // today_column = get_today_column (GCAL_WEEK_GRID (widget));
            // TODO: if (today_column != -1)

            return false;
        }
    }
}
