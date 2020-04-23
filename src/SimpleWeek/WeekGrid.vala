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

    public class WeekGrid : Gtk.Box {

        public Gtk.Box sidebar { get; construct; }
        private Gtk.Box[] weekday_columns;

        private bool is_ltr;

        construct {
            orientation = Gtk.Orientation.HORIZONTAL;
            expand = true;

            is_ltr = get_direction () != Gtk.TextDirection.RTL;

            sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            sidebar.vexpand = true;
            sidebar.hexpand = false;

            if (is_ltr) {
                add (sidebar);
            }

            weekday_columns = new Gtk.Box[7];
            for (var i = 0; i < 7; i++) {
                weekday_columns[i] = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                weekday_columns[i].expand = true;

                add (weekday_columns[i]);
            }

            if (!is_ltr) {
                add (sidebar);
            }
        }

        public void add_to_weekday_column (Gtk.Widget widget, int weekday_column) {
            if (is_ltr) {
                weekday_columns[weekday_column].add (widget);
            } else {
                weekday_columns[7 - weekday_column].add (widget);
            }
        }
    }
}
