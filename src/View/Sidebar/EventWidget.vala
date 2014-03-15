//
//  Copyright (C) 2011-2012 Niels Avonds <niels.avonds@gmail.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


namespace Maya.View {

    /**
     * A widget displaying one event in the sidebar.
     */
    public class EventWidget : Gtk.EventBox {

        // A label displaying the name of the event
        Gtk.Label calendar_color_label;

        // A label displaying the name of the event
        Gtk.Label name_label;

        // A label displaying the date of the event
        Gtk.Label date_label;
        Gtk.Image date_image;

        // A label displaying the hour of the event
        Gtk.Label hour_label;
        Gtk.Image hour_image;

        // A label displaying the location of the event
        Gtk.Label location_label;
        Gtk.Image location_image;
        
        Gtk.Menu menu;

        // Signal sent out when a button is pressed

        public signal void removed (E.CalComponent event);
        public signal void modified (E.CalComponent event);

        private E.CalComponent calevent;
        /**
         * Creates a new event widget for the given event.
         */
        public EventWidget (E.Source source, E.CalComponent calevent) {
            this.calevent = calevent;
            var main_grid = new Gtk.Grid ();
            main_grid.column_spacing = 12;
            main_grid.row_spacing = 6;
            
            calendar_color_label = new Gtk.Label (" ");
            E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            var rgba = Gdk.RGBA();
            rgba.parse (cal.dup_color ());
            calendar_color_label.override_background_color (Gtk.StateFlags.NORMAL, rgba);
            main_grid.attach (calendar_color_label, 0, 0, 1, 1);
            
            var content_grid = new Gtk.Grid ();
            content_grid.column_spacing = 12;
            content_grid.row_spacing = 6;

            name_label = new Gtk.Label ("");
            name_label.set_line_wrap (true);
            name_label.set_alignment (0, 0.5f);
            name_label.hexpand = true;
            main_grid.attach (name_label, 1, 0, 1, 1);

            date_label = new Gtk.Label ("");
            date_label.set_line_wrap (true);
            date_label.set_alignment (0, 0.5f);
            content_grid.attach (date_label, 2, 1, 3, 1);

            date_image = new Gtk.Image.from_icon_name ("office-calendar-symbolic", Gtk.IconSize.MENU);
            content_grid.attach (date_image, 1, 1, 1, 1);

            hour_label = new Gtk.Label ("");
            hour_label.set_alignment (0, 0.5f);
            content_grid.attach (hour_label, 2, 2, 2, 1);

            hour_image = new Gtk.Image.from_icon_name ("appointment-symbolic", Gtk.IconSize.MENU);
            content_grid.attach (hour_image, 1, 2, 1, 1);

            location_label = new Gtk.Label ("");
            location_label.set_line_wrap (true);
            location_label.set_alignment (0, 0.5f);
            location_label.no_show_all = true;
            content_grid.attach (location_label, 2, 3, 2, 1);

            location_image = new Gtk.Image.from_icon_name ("go-next-symbolic", Gtk.IconSize.MENU);
            location_image.no_show_all = true;
            content_grid.attach (location_image, 1, 3, 1, 1);

            main_grid.attach (content_grid, 1, 1, 1, 1);

            can_focus = true;
            add_events (Gdk.EventMask.BUTTON_PRESS_MASK);

            add (main_grid);

            button_press_event.connect (on_button_press);

            focus_in_event.connect (on_focus_in);
            focus_out_event.connect (on_focus_out);

            // Fill in the information
            update (calevent);
        }

        private bool on_button_press (Gdk.EventButton event) {
            grab_focus ();
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                 modified (calevent);
            }
            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == Gdk.BUTTON_SECONDARY) {
                if (menu == null) {
                    menu = new Gtk.Menu ();
                    menu.attach_to_widget (this, null);
                    var edit_item = new Gtk.MenuItem.with_label (_("Edit…"));
                    var remove_item = new Gtk.MenuItem.with_label (_("Remove"));
                    edit_item.activate.connect (() => {modified (calevent);});
                    remove_item.activate.connect (() => {removed (calevent);});
                    menu.append (edit_item);
                    menu.append (remove_item);
                }
                menu.popup (null, null, null, event.button, event.time);
                menu.show_all ();
            }
            return true;
        }

        private bool on_focus_in (Gdk.EventFocus event) {
            return false;
        }

        private bool on_focus_out (Gdk.EventFocus event) {
            return false;
        }

        /**
         * Updates the event to match the given event.
         */
        public void update (E.CalComponent event) {
            name_label.set_markup ("<big><span size=\"xx-large\">" + Markup.escape_text (get_label (event)) + "</span></big>");

            date_label.set_markup ("<span weight=\"light\">" + Markup.escape_text (get_day_string (event)) + "</span>");
            hour_label.set_markup ("<span weight=\"light\">" + Markup.escape_text (get_hour_string (event)) + "</span>");
            unowned iCal.icalcomponent ical_event = event.get_icalcomponent ();

            string location = ical_event.get_location ();

            if (location != null && location != "") {
                location_label.set_markup ("<span weight=\"light\">" + Markup.escape_text (location) + "</span>");
                location_image.no_show_all = false;
                location_label.show ();
                location_image.show ();
            } else
                location_label.hide ();
                location_image.hide ();
        }

        /**
         * Returns the name that should be displayed for the given event.
         */
        string get_label (E.CalComponent event) {
            E.CalComponentText summary = E.CalComponentText ();
            event.get_summary (out summary);

            return summary.value;
        }

        /**
         * Returns the date that should be displayed for the given event.
         */
        string get_day_string (E.CalComponent event) {
            DateTime start_date, end_date;
            get_dates (event, out start_date, out end_date);
            string start_date_string = start_date.format (Settings.DateFormat_Complete ());
            if (Util.is_multiday_event (event) == true) {
                string end_date_string = end_date.format (Settings.DateFormat_Complete ());
                return ("%s to %s".printf (start_date_string, end_date_string));
            } else {
                date_label.no_show_all = true;
                date_image.no_show_all = true;
                date_label.hide ();
                date_image.hide ();
                return start_date_string;
            }
        }

        string get_hour_string (E.CalComponent event) {
            DateTime start_date, end_date;
            get_dates (event, out start_date, out end_date);
            if (Util.is_the_all_day(start_date, end_date) == true) {
                return _("all day");
            } else {
                string start_time_string = start_date.format (Settings.TimeFormat ());
                string end_time_string = end_date.format (Settings.TimeFormat ());
                return "%s - %s".printf (start_time_string, end_time_string);
            }
        }

        void get_dates (E.CalComponent event, out DateTime start_date, out DateTime end_date) {
            var datefrom = E.CalComponentDateTime ();
            var dateto = E.CalComponentDateTime ();
            event.get_dtstart (out datefrom);
            event.get_dtend (out dateto);

            start_date = Util.ical_to_date_time (*datefrom.value);
            end_date = Util.ical_to_date_time (*dateto.value);
        }

    }
}