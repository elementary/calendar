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
     * - https://gitlab.gnome.org/GNOME/gnome-calendar/-/blob/master/src/views/gcal-week-header.ui
     */
    public class WeekHeader : Gtk.Box {

        public Gtk.SizeGroup sidebar_sizegroup { get; construct; }

        private Gtk.ScrolledWindow scrolled_window;
        private Gtk.Box top_edge_box;

        private DateTime active_date;

        public WeekHeader (Gtk.SizeGroup sidebar_sizegroup) {
            Object (
                sidebar_sizegroup: sidebar_sizegroup
            );
        }

        construct {
            active_date = new DateTime.now_local ();

            var style_context = get_style_context ();
            style_context.add_class ("week-header");
            style_context.add_provider (WeekView.style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            top_edge_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            sidebar_sizegroup.add_widget (top_edge_box);
            add (top_edge_box);

            var grid = new Gtk.Grid ();
            grid.column_homogeneous = true;
            grid.hexpand = true;
            grid.column_spacing = 6;
            grid.row_spacing = 2;
            grid.margin_start = 6;

            for (int i = 0; i < 7; i++) {
                var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                grid.attach (box, i, 0);
            }

            var viewport = new Gtk.Viewport (null, null);
            viewport.shadow_type = Gtk.ShadowType.NONE;
            viewport.add (grid);

            scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.hscrollbar_policy = scrolled_window.vscrollbar_policy = Gtk.PolicyType.NEVER;
            scrolled_window.propagate_natural_height = true;
            scrolled_window.margin_bottom = 2;
            scrolled_window.add (viewport);

            var event_box = new Gtk.EventBox ();
            event_box.add (scrolled_window);

            add (event_box);
        }

        private int get_weekday_names_height () {
            Pango.FontDescription font_desc;
            Gtk.Border padding;
            int font_height;
            int final_height;

            var style_context = get_style_context ();
            var state = style_context.get_state ();

            var pango_layout = create_pango_layout ("A");

            style_context.save ();
            style_context.add_class ("week-dates");

            padding = style_context.get_padding (state);

            style_context.@get (state, "font", out font_desc, null);
            pango_layout.set_font_description (font_desc);
            pango_layout.get_pixel_size (out font_height, null);

            style_context.restore ();

            final_height = padding.top + font_height + padding.bottom;

            style_context.save ();
            style_context.add_class ("week-names");

            padding = style_context.get_padding (state);

            style_context.@get (state, "font", out font_desc, null);
            pango_layout.set_font_description (font_desc);
            pango_layout.get_pixel_size (out font_height, null);

            final_height += padding.top + font_height + padding.bottom;

            // TODO: multiply by 2 should not be necessary here :(
            return final_height * 2;
        }


        public override void size_allocate (Gtk.Allocation allocation) {
            var min_header_height = get_weekday_names_height ();
            scrolled_window.margin_top = min_header_height;

            base.size_allocate (allocation);
        }

        public override bool draw (Cairo.Context context) {
            Pango.FontDescription bold_font;
            DateTime week_start, week_end;
            Gdk.RGBA color;

            double cell_width;
            int i, day_abv_font_height, current_cell, today_column;
            int start_x, start_y;

            context.save ();

            /* Fonts and colour selection */
            var style_context = get_style_context ();
            var state = style_context.get_state ();
            var ltr = get_direction () != Gtk.TextDirection.RTL;

            start_x = ltr ? top_edge_box.get_allocated_width () : 0;
            start_y = 0;

            var padding = style_context.get_padding (state);

            Gtk.Allocation alloc;
            get_allocation (out alloc);

            if (!ltr) {
                alloc.width -= top_edge_box.get_allocated_width ();
            }

            color = style_context.get_color (state);
            context.set_source_rgba (color.red, color.green, color.blue, color.alpha);

            var pango_layout = Pango.cairo_create_layout (context);
            style_context.@get (state, "font", out bold_font, null);
            bold_font.set_weight (Pango.Weight.MEDIUM);
            pango_layout.set_font_description (bold_font);

            week_start = Maya.Util.get_start_of_week (active_date);
            week_end = week_start.add_days (6);

            current_cell = active_date.get_day_of_week () - 1;
            current_cell = (7 + current_cell - Util.get_first_weekday ()) % 7;
            today_column = 2; // TODO: get_today_column ();

            cell_width = (alloc.width - start_x) / 7.0;

            /* Drag and Drop highlight */
            // TODO: if (self->dnd_cell != -1)

            /* Draw the selection background */
            // TODO: if (self->selection_start != -1 && self->selection_end != -1)

            pango_layout.get_pixel_size (null, out day_abv_font_height);

            for (i = 0; i < 7; i++) {
                var day = week_start.add_days (i);
                var n_day = day.get_day_of_month ();
                var days_in_month = Maya.Util.get_days_in_month (week_start);

                string weekday_abv, weekday;
                int font_width, day_num_font_height, day_num_font_baseline;
                double x;

                if (n_day > days_in_month) {
                    n_day = n_day - days_in_month;
                }

                /* Draws the date of days in the week */
                var weekday_date = "%d".printf (n_day);

                style_context.save ();
                style_context.add_class ("week-dates");

                style_context.@get (state, "font", out bold_font, null);

                if (i == today_column) {
                    style_context.add_class ("today");
                }

                pango_layout.set_font_description (bold_font);
                pango_layout.set_text (weekday_date, -1);

                pango_layout.get_pixel_size (out font_width, out day_num_font_height);
                day_num_font_baseline = pango_layout.get_baseline () / Pango.SCALE;

                if (ltr) {
                    x = padding.left + cell_width * i + WeekUtil.COLUMN_PADDING + start_x;
                } else {
                    x = alloc.width - (cell_width * i + font_width + WeekUtil.COLUMN_PADDING + start_x);
                }

                style_context.render_layout (context, x, day_abv_font_height + padding.bottom + start_y, pango_layout);
                style_context.restore ();

                /* Draws the days name */
                weekday = day.format ("%a");
                weekday_abv = weekday.up ();

                style_context.save ();
                style_context.add_class ("week-names");
                style_context.@get (state, "font", out bold_font, null);

                if (i == today_column) {
                    style_context.add_class ("today");
                }

                pango_layout.set_font_description (bold_font);
                pango_layout.set_text (weekday_abv, -1);

                pango_layout.get_pixel_size (out font_width, null);

                if (ltr) {
                    x = padding.left + cell_width * i + WeekUtil.COLUMN_PADDING + start_x;
                } else {
                    x = alloc.width - (cell_width * i + font_width + WeekUtil.COLUMN_PADDING + start_x);
                }

                style_context.render_layout (context, x, start_y, pango_layout);
                style_context.restore ();

                /* Draws the lines after each day of the week */
                style_context.save ();
                style_context.add_class ("lines");

                color = style_context.get_color (state);
                context.set_source_rgba (color.red, color.green, color.blue, color.alpha);
                context.set_line_width (0.25);
                context.move_to (WeekUtil.aligned (ltr ? (cell_width * i + start_x) : (alloc.width - (cell_width * i + start_x))), day_abv_font_height + padding.bottom + start_y);
                context.rel_line_to (0.0, get_allocated_height () - day_abv_font_height - start_y + padding.bottom);
                context.stroke ();

                style_context.restore ();
            }

            context.restore ();
            base.draw (context);

            return false;
        }

        // /**
        //  * Puts the given event on the header.
        //  */
        // public void add_event (E.Source source, ECal.Component event) {
        //     critical ("header.add_event...");

        //     /*foreach (var grid_day in data.values) {
        //         if (Util.calcomp_is_on_day (event, grid_day.date)) {
        //             var button = new EventButton (event);
        //             grid_day.add_event_button (button);
        //         }
        //     } */
        // }

        // /**
        //  * Removes the given event from the header.
        //  */
        // public void remove_event (E.Source source, ECal.Component event) {
        //     critical ("header.remove_event...");
        //     /*foreach (var grid_day in data.values) {
        //         grid_day.remove_event (event);
        //     }*/
        // }

        // /**
        //  * Removes all events from the header.
        //  */
        // public void remove_all_events () {
        //     critical ("header.remove_all_events...");
        //     /*foreach (var grid_day in data.values) {
        //         grid_day.clear_events ();
        //     }*/
        // }
    }
}
