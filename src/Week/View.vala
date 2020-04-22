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

        internal static Gtk.CssProvider css_provider;
        private Gtk.DrawingArea hours_bar;

        static construct {
            css_provider = new Gtk.CssProvider ();
            css_provider.load_from_resource ("/io/elementary/calendar/WeekView.css");
        }

        construct {
            visible = true;
            orientation = Gtk.Orientation.VERTICAL;

            var style_context = get_style_context ();
            style_context.add_class ("week-view");
            style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            hours_bar = new Gtk.DrawingArea ();
            hours_bar.height_request = 2568;

            var week_grid = new Grid ();
            week_grid.expand = true;

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.add (hours_bar);
            box.add (week_grid);

            var viewport = new Gtk.Viewport (null, null);
            viewport.add (box);

            var scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.expand = true;
            scrolled_window.add (viewport);

            add (scrolled_window);

            hours_bar.draw.connect (draw_hours);

            update_hours_sidebar_size ();
        }

        private bool draw_hours (Cairo.Context context) {
            Gdk.RGBA color;
            int i;
            //var time_format = ??

            var style_context = get_style_context ();
            var state = style_context.get_state ();
            var ltr = get_direction () != Gtk.TextDirection.RTL;

            style_context.save ();
            style_context.add_class ("hours");

            color = style_context.get_color (state);
            var padding = style_context.get_padding (state);

            Pango.FontDescription font_desc;
            style_context.@get (state, "font", out font_desc, null);

            var pango_layout = Pango.cairo_create_layout (context);
            pango_layout.set_font_description (font_desc);

            context.set_source_rgba (color.red, color.green, color.blue, color.alpha);

            /* Gets the size of the widget */
            var width = hours_bar.get_allocated_width ();
            var height = hours_bar.get_allocated_height ();

            /* Draws the hours in the sidebar */
            for (i = 0; i < 24; i++) {
                string hours;

                // TODO: Honor User Time Format (12/24h):
                // if (time_format == GCAL_TIME_FORMAT_24H):
                hours = "%02d:00".printf(i);
                // else:
                /*hours = "%d %s".printf (
                    i % 12 == 0 ? 12 : i % 12,
                    i >= 12 ? _("PM") : _("AM")
                );*/

                pango_layout.set_text (hours, -1);

                int font_width;
                pango_layout.get_pixel_size (out font_width, null);

                style_context.render_layout (
                    context,
                    ltr ? padding.left : width - font_width - padding.right,
                    (height / 24) * i + padding.top,
                    pango_layout
                );
            }

            style_context.restore ();
            style_context.save ();

            style_context.add_class ("lines");
            color = style_context.get_color (state);

            context.set_source_rgba (color.red, color.green, color.blue, color.alpha);
            context.set_line_width (0.65);

            if (!ltr) {
                context.move_to (0.5, 0);
                context.rel_line_to (0, height);
            }

            /* Draws the horizontal complete lines */
            for (i = 1; i < 24; i++) {
                context.move_to (0, (height / 24) * i + 0.4);
                context.rel_line_to (width, 0);
            }

            context.stroke ();
            context.set_dash (Util.dashed, 2);

            /* Draws the horizontal dashed lines */
            for (i = 0; i < 24; i++) {
                context.move_to (0, (height / 24) * i + (height / 48) + 0.4);
                context.rel_line_to (width, 0);
            }

            context.stroke ();
            style_context.restore ();

            return false;
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
            hours_bar.set_size_request (sidebar_width, 48 * cell_height);

            /* Sync with the week header sidebar */
            //sidebar_sizegroup = gcal_week_header_get_sidebar_size_group (GCAL_WEEK_HEADER (self->header));
            //gtk_size_group_add_widget (sidebar_sizegroup, self->hours_bar);
        }
    }
}
