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
 * - https://gitlab.gnome.org/GNOME/gnome-calendar/-/blob/master/src/views/gcal-week-view.ui
 */
public class WeekView : Gtk.Box {

    construct {
        visible = true;
        orientation = Gtk.Orientation.VERTICAL;
        get_style_context ().add_class ("week-view");

        var header = new WeekHeader ();

        var hours_bar = new Gtk.DrawingArea ();
        hours_bar.height_request (2568);

        var week_grid = new WeekGrid ();

        var scrolled_window = new Gtk.ScrolledWindow ();
        scrolled_window.expand = true;

        scrolled_window.add (hours_bar);
        scrolled_window.add (week_grid);

        add (header);
        add (scrolled_window);
    }
}
