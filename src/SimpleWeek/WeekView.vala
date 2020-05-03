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

    public class WeekView : Gtk.Box {

        internal static Gtk.CssProvider style_provider;

        static construct {
            style_provider = new Gtk.CssProvider ();
            style_provider.load_from_resource ("/io/elementary/calendar/WeekView.css");
        }

        private WeekHead head;
        private WeekBody body;

        construct {
            orientation = Gtk.Orientation.VERTICAL;
            homogeneous = false;

            head = new WeekHead ();
            body = new WeekBody ();

            var scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.add (body);

            add (head);
            add (scrolled_window);

            var style_context = get_style_context ();
            style_context.add_class ("week-view");
            style_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }
    }
}
