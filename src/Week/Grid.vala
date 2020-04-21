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
    public class Grid : Gtk.Box {

        const double dashed[] = { 5.0, 6.0 };


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
