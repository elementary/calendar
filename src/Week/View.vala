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

        private Sidebar hours_bar;
        private Gtk.SizeGroup sidebar_sizegroup;

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


            sidebar_sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            hours_bar = new Sidebar (sidebar_sizegroup);

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

            var header = new Header (sidebar_sizegroup);

            add (header);
            add (scrolled_window);

            update_hours_sidebar_size ();
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
            //gcal_week_header_get_sidebar_size_group (GCAL_WEEK_HEADER (self->header));
            //gtk_size_group_add_widget (sidebar_sizegroup, self->hours_bar);
        }
    }
}
