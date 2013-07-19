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
        Granite.Widgets.WrapLabel name_label;

        // A label displaying the start date of the event
        Granite.Widgets.WrapLabel start_date_label;

        // A label displaying the end date of the event
        Granite.Widgets.WrapLabel end_date_label;

        // A label displaying the location of the event
        Granite.Widgets.WrapLabel location_label;

        // A Grid containing the labels
        Gtk.Grid grid;

        // The old close and edit button
        Gtk.Button close_button;
        Gtk.Button edit_button;

        // Signal sent out when a button is pressed

        public signal void removed (E.CalComponent event);
        public signal void modified (E.CalComponent event);


        /**
         * Creates a new event widget for the given event.
         */
        public EventWidget (Model.SourceManager sourcemgr, E.SourceGroup group, E.Source source, E.CalComponent event) {

            var style_provider = Util.Css.get_css_provider ();

            get_style_context().add_provider (style_provider, 600);
            get_style_context().add_class ("sidebarevent");

            grid = new Gtk.Grid ();

            name_label = new Granite.Widgets.WrapLabel ("");
            name_label.set_hexpand(true);
            name_label.set_alignment (0, 0.5f);
            grid.attach (name_label, 0, 0, 1, 1);

            start_date_label = new Granite.Widgets.WrapLabel ("");
            start_date_label.set_alignment (0, 0.5f);
            grid.attach (start_date_label, 0, 1, 3, 1);

            end_date_label = new Granite.Widgets.WrapLabel ("");
            end_date_label.set_alignment (0, 0.5f);
            end_date_label.no_show_all = true;
            grid.attach (end_date_label, 0, 2, 3, 1);

            location_label = new Granite.Widgets.WrapLabel ("");
            location_label.set_alignment (0, 0.5f);
            location_label.no_show_all = true;
            grid.attach (location_label, 0, 3, 3, 1);

            edit_button = new Gtk.Button ();
            edit_button.add (new Gtk.Image.from_stock ("gtk-edit", Gtk.IconSize.MENU));
            edit_button.set_relief (Gtk.ReliefStyle.NONE);
            grid.attach (edit_button, 1, 0, 1, 1);

            close_button = new Gtk.Button ();
            close_button.add (new Gtk.Image.from_stock ("gtk-close", Gtk.IconSize.MENU));
            close_button.set_relief (Gtk.ReliefStyle.NONE);
            // Don't show the delete button if the event can't be edited
            if (sourcemgr.can_edit_source (group, source)) {
                grid.attach (close_button, 2, 0, 1, 1);
            }

            grid.show ();
            add (grid);

            can_focus = true;
            set_visible_window (true);
            events |= Gdk.EventMask.BUTTON_PRESS_MASK;

            button_press_event.connect (on_button_press);

            close_button.clicked.connect( () => { removed(event); });
            edit_button.clicked.connect( () => { modified(event); });

            focus_in_event.connect (on_focus_in);
            focus_out_event.connect (on_focus_out);

            // Fill in the information
            update (event);

            grid.margin_left = 20;
        }

        private bool on_button_press (Gdk.EventButton event) {
            grab_focus ();
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
            name_label.set_markup ("<big>" + Markup.escape_text (get_label (event)) + "</big>");

            string end_string = get_end_string (event);
            string start_add = end_string == "" ? "" : _("Starts: \t");

            start_date_label.set_markup ("<span weight=\"light\">" + start_add + get_start_string (event) + "</span>");

            if (end_string != "") {
                end_date_label.set_markup ("<span weight=\"light\">" + _("Ends: \t") + end_string  + "</span>");
                end_date_label.show ();
            } else
                end_date_label.hide ();
            unowned iCal.icalcomponent ical_event = event.get_icalcomponent ();

            string location = ical_event.get_location ();

            if (location != null && location != "") {
                location_label.set_markup ("<span weight=\"light\">" + location + "</span>");
                location_label.show ();
            } else
                location_label.hide ();
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
        string get_start_string (E.CalComponent event) {
            DateTime start_date, end_date;
            get_dates (event, out start_date, out end_date);

            string date_string = start_date.format (Settings.DateFormat_Complete ());
            string time_string = start_date.format (Settings.TimeFormat ());
            if (Util.is_the_all_day(start_date, end_date) == true) {
                if (Util.is_multiday_event (event))
                    return date_string;
                else
                    return date_string + ", " + _("all day");
            }
            else {
                if (Util.is_multiday_event (event))
                    return date_string + " " + _("at") + " " + time_string;
                else {
                    string end_time_string = end_date.format (Settings.TimeFormat ());
                    return date_string + ", " + time_string + " - " + end_time_string;
                }
            }
        }

        string get_end_string (E.CalComponent event) {
            if (! Util.is_multiday_event (event))
                return "";

            DateTime start_date, end_date;
            get_dates (event, out start_date, out end_date);

            string date_string = end_date.format (Settings.DateFormat_Complete ());
            string time_string = end_date.format (Settings.TimeFormat ());
            if (Util.is_the_all_day(start_date, end_date) == true) {
                return end_date.add_days (-1).format (Settings.DateFormat_Complete ());
            }
            else {
                return date_string + " " + _("at") + " " + time_string;
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
