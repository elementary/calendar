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
     * - https://gitlab.gnome.org/GNOME/gnome-calendar/-/blob/master/src/gui/gcal-event-widget.ui
     */
    public class EventWidget : Gtk.GtkBin {

        private Gtk.Stack stack;
        private Gtk.Grid horizontal_grid;
        private Gtk.Grid vertical_grid;

        private Gtk.Label hour_label;
        private Gtk.Label summary_label;

        public ECal.Component event { get; construct; }
        public E.Source source { get; construct; }

        private DateTime date_start;
        private DateTime date_end;

        private string css_class;

        public EventButton (ECal.Component event, E.Source source) {
            Object (event: event, source: source);
        }

        construct {
            summary_label = new Gtk.Label ();
            summary_label.can_focus = false;
            summary_label.hexpand = true;
            summary_label.xalign = 0.0;
            summary_label.ellipsize = Pango.EllipsizeMode.END;

            hour_label = new Gtk.Label ();
            hour_label.can_focus = false;
            hour_label.no_show_all = true;
            hour_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            /* -- Horizontal Page -- */

            horizontal_grid = new Gtk.Grid ();
            horizontal_grid.orientation = Gtk.Orientation.HORIZONTAL;
            horizontal_grid.column_spacing = 4;
            horizontal_grid.can_focus = false;

            horizontal_grid.attach (summary_label, 1, 0);
            horizontal_grid.attach (hour_label, 2, 0);

            /* -- Vertical Page -- */

            var vertical_hour_label = new Gtk.Label ();
            vertical_hour_label.can_focus = false;
            vertical_hour_label.xalign = 0.0;
            vertical_hour_label.bind ("label", hour_label, "label", SettingsBindFlags.DEFAULT);
            vertical_hour_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            var vertical_summary_label = new Gtk.Label ();
            vertical_summary_label.can_focus = false;
            vertical_summary_label.hexpand = true;
            vertical_summary_label.xalign = 0.0;
            vertical_summary_label.ellipsize = Pango.EllipsizeMode.END;
            vertical_summary_label.bind ("label", summary_label, "label", SettingsBindFlags.DEFAULT);

            vertical_grid = new Gtk.Grid ();
            vertical_grid.orientation = Gtk.Orientation.VERTICAL;
            vertical_grid.can_focus = false;

            vertical_grid.attach (vertical_hour_label, 0, 0);
            vertical_grid.attach (vertical_summary_label, 0, 1);

            /* -- Switch Page -- */

            stack = new Gtk.Stack ();
            stack.can_focus = false;
            stack.hexpand = false;
            stack.margin_top = stack.margin_bottom = 1;
            stack.margin_start = 6;
            stack.margin_end = 4;
            stack.homogeneous = false;

            stack.add (horizontal_grid);
            stack.add (vertical_grid);

            update_request ();
        }

        private void update_request () {
            unowned ICal.Component comp = event.get_icalcomponent ();

            date_start = Maya.Util.ical_to_date_time (comp.get_dtstart ());
            date_end = Maya.Util.ical_to_date_time (comp.get_dtend ());

            /* Update color */
            update_color ();

            /* Summary label */
            summary_label.label = comp.get_summary ();

            /* Hour label */
            var local_start_time = date_start.to_local ();

            // TODO: if (self->clock_format_24h)
            hour_label.label = local_start_time.format ("%R");
            // TODO: else: g_date_time_format (local_start_time, "%I:%M %P");
        }

        private void update_color () {
            E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

            var style_context = get_style_context ();
            var color = cal.color;
            var now = new DateTime.now_local ()
            var date_compare = date_end.compare (now);

            /* Fades out an event that's earlier than the current date */
            opacity = date_compare < 0 ? 0.6 : 1.0;

            /* Remove the old style class */
            style_context.remove_class (css_class);

            var color_id = Quark.from_string (color);

            css_class = "color-%d".printf (color_id);
            style_context.add_class (css_class);
        }
    }
}
