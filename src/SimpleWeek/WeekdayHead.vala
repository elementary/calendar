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

    public class WeekdayHead : Gtk.Grid {

        public string title { get; set; }
        private Gtk.Label title_label;

        construct {
            expand = true;

            title_label = new Gtk.Label (null);
            add (title_label);

            bind_property ("title", title_label, "label");

            var style_context = get_style_context ();
            style_context.add_class ("weekday-head");
            style_context.add_provider (WeekView.style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }
    }
}
