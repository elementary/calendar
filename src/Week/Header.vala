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
     * - https://gitlab.gnome.org/GNOME/gnome-calendar/-/blob/master/src/views/gcal-week-header.ui
     */
    public class Header : Gtk.Grid {

        public signal void event_activated (/* TODO */);

        private Gtk.Grid grid;

        construct {
            hexpand = true;
            vexpand = false;
            get_style_context ().add_class ("week-header");

            var month_label = new Gtk.Label (_("Month"));
            month_label.yalign = 0;
            month_label.get_style_context ().add_class ("primary-label");

            var week_label = new Gtk.Label (_("Week"));
            week_label.hexpand = true;
            week_label.xalign = week_label.yalign = 0;
            week_label.get_style_context ().add_class ("secondary-label");

            var year_label = new Gtk.Label (_("Year"));
            year_label.yalign = 0;
            year_label.get_style_context ().add_class ("secondary-label");

            var header_labels_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

            header_labels_box.add (month_label);
            header_labels_box.add (week_label);
            header_labels_box.add (year_label);

            var expand_button = new Gtk.Button.from_icon_name ("go-down-symbolic");
            expand_button.can_focus = false;
            expand_button.hexpand = true;
            expand_button.halign = Gtk.Align.CENTER;
            expand_button.valign = Gtk.Align.END;

            var expand_button_style_context = expand_button.get_style_context ();
            expand_button_style_context.add_class ("flat");
            expand_button_style_context.add_class ("circular");

            var grid = new Gtk.Grid ();
            grid.hexpand = true;
            grid.column_homogeneous = true;
            grid.column_spacing = 6;
            grid.row_spacing = 2;

            /*grid.add (new Gtk.Box ());
            grid.add (new Gtk.Box ());
            grid.add (new Gtk.Box ());
            grid.add (new Gtk.Box ());
            grid.add (new Gtk.Box ());
            grid.add (new Gtk.Box ());
            grid.add (new Gtk.Box ());*/

            var scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.hscrollbar_policy = scrolled_window.vscrollbar_policy = Gtk.PolicyType.NEVER;
            scrolled_window.propagate_natural_height = true;

            scrolled_window.add (grid);

            add (header_labels_box);
            add (expand_button);
            add (scrolled_window);
        }
    }
}
