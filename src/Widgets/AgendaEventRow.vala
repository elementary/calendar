/*
 * Copyright 2011-2018 elementary, Inc. (https://elementary.io)
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
 * Authored by: Maxwell Barvian
 *              Niels Avonds <niels.avonds@gmail.com>
 *              Corentin Noël <corentin@elementaryos.org>
 */

const string EVENT_CSS = """
    @define-color accent_color %s;
""";

public class Maya.View.AgendaEventRow : Gtk.ListBoxRow {
    public signal void removed (E.CalComponent event);
    public signal void modified (E.CalComponent event);

    public E.CalComponent calevent { get; construct; }
    public E.Source source { get; construct; }
    public bool is_upcoming { get; construct; }

    public string summary { public get; private set; }
    public bool is_allday { public get; private set; default = false; }
    public bool is_multiday { public get; private set; default = false; }
    public Gtk.Revealer revealer { public get; private set; }

    private Gtk.Label name_label;
    private Gtk.Label datatime_label;
    private Gtk.Label location_label;
    private Gtk.LinkButton location_button;
    private Gtk.StyleContext main_grid_context;

    public AgendaEventRow (E.Source source, E.CalComponent calevent, bool is_upcoming) {
        Object (
            calevent: calevent,
            is_upcoming: is_upcoming,
            source: source
        );
    }

    construct {
        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/calendar/AgendaEventRow.css");

        var event_image = new Gtk.Image.from_icon_name ("office-calendar-symbolic", Gtk.IconSize.MENU);
        event_image.valign = Gtk.Align.START;

        name_label = new Gtk.Label ("");
        name_label.hexpand = true;
        name_label.selectable = true;
        name_label.wrap = true;
        name_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        name_label.xalign = 0;

        var name_label_context = name_label.get_style_context ();
        name_label_context.add_class ("title");
        name_label_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        datatime_label = new Gtk.Label ("");
        datatime_label.ellipsize = Pango.EllipsizeMode.END;
        datatime_label.selectable = true;
        datatime_label.use_markup = true;
        datatime_label.xalign = 0;
        datatime_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        location_label = new Gtk.Label ("");
        location_label.wrap = true;
        location_label.xalign = 0;
        location_label.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        location_button = new Gtk.LinkButton ("");
        location_button.halign = Gtk.Align.START;
        location_button.margin_top = 6;
        location_button.get_child ().destroy ();
        location_button.add (location_label);

        var location_revealer = new Gtk.Revealer ();
        location_revealer.add (location_button);

        var main_grid = new Gtk.Grid ();
        main_grid.column_spacing = 6;
        main_grid.margin = 6;
        main_grid.margin_start = main_grid.margin_end = 12;
        main_grid.attach (event_image, 0, 0, 1, 1);
        main_grid.attach (name_label, 1, 0, 1, 1);
        main_grid.attach (datatime_label, 1, 1, 1, 1);
        main_grid.attach (location_revealer, 1, 2);

        main_grid_context = main_grid.get_style_context ();
        main_grid_context.add_class ("event");
        main_grid_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var event_box = new Gtk.EventBox ();
        event_box.add (main_grid);

        revealer = new Gtk.Revealer ();
        revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        revealer.add (event_box);
        add (revealer);

        var cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        reload_css (cal.dup_color ());

        cal.notify["color"].connect (() => {
            reload_css (cal.dup_color ());
        });

        location_label.notify["label"].connect (() => {
            location_revealer.reveal_child = location_label.label != null && location_label.label != "";
        });

        show.connect (() => {
            revealer.set_reveal_child (true);
        });

        hide.connect (() => {
            revealer.set_reveal_child (false);
        });

        add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
        button_press_event.connect (on_button_press);

        // Fill in the information
        update (calevent);
    }

    private bool on_button_press (Gdk.EventButton event) {
        if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
             modified (calevent);
        } else if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == Gdk.BUTTON_SECONDARY) {
            var start_date = Util.ical_to_date_time (calevent.get_icalcomponent ().get_dtstart ());

            var menu = new Maya.EventMenu (calevent, start_date);
            menu.attach_to_widget (this, null);
            menu.popup_at_pointer (event);
            menu.show_all ();
        }

        return true;
    }

    /**
     * Updates the event to match the given event.
     */
    public void update (E.CalComponent event) {
        unowned iCal.Component ical_event = event.get_icalcomponent ();
        summary = ical_event.get_summary ();
        name_label.set_markup (Markup.escape_text (summary));

        DateTime start_date, end_date;
        Util.get_local_datetimes_from_icalcomponent (ical_event, out start_date, out end_date);

        is_allday = Util.is_all_day (start_date, end_date);
        is_multiday = Util.is_multiday_event (ical_event);

        string start_date_string = start_date.format (Settings.DateFormat_Complete ());
        string end_date_string = end_date.format (Settings.DateFormat_Complete ());
        string start_time_string = start_date.format (Settings.TimeFormat ());
        string end_time_string = end_date.format (Settings.TimeFormat ());
        string datetime_string = null;

        datatime_label.show ();
        datatime_label.no_show_all = false;
        if (is_multiday) {
            if (is_allday) {
                // TRANSLATORS: A range from start date to end date i.e. "Friday, Dec 21 – Saturday, Dec 22"
                datetime_string = C_("date-range", "%s – %s").printf (start_date_string, end_date_string);
            } else {
                // TRANSLATORS: A range from start date and time to end date and time i.e. "Friday, Dec 21, 7:00 PM – Saturday, Dec 22, 12:00 AM"
                datetime_string = _("%s, %s – %s, %s").printf (start_date_string, start_time_string, end_date_string, end_time_string);
            }
        } else {
            if (!is_upcoming) {
                if (is_allday) {
                    datatime_label.hide ();
                    datatime_label.no_show_all = true;
                } else {
                    // TRANSLATORS: A range from start time to end time i.e. "7:00 PM – 9:00 PM"
                    datetime_string = C_("time-range", "%s – %s").printf (start_time_string, end_time_string);
                }
            } else {
                if (is_allday) {
                    datetime_string = "%s".printf (start_date_string);
                } else {
                    // TRANSLATORS: A range from start date and time to end time i.e. "Friday, Dec 21, 7:00 PM – 9:00 PM"
                    datetime_string = _("%s, %s – %s").printf (start_date_string, start_time_string, end_time_string);
                }
            }
        }

        datatime_label.label = "<small>%s</small>".printf (datetime_string);

        var location_string = ical_event.get_location ();
        string location_query;

        if (location_string != null) {
            if ("\n" in location_string) {
                var words = location_string.split ("\n");
                location_button.tooltip_text = words[1];
                location_label.label = words[0];
                location_query = words[1];
            } else {
                location_label.label = location_string;
                location_query = location_string;
            }

            location_button.uri = "https://openstreetmap.org/search?query=%s".printf (Uri.escape_string (location_query));
        }
    }

    private void reload_css (string background_color) {
        var provider = new Gtk.CssProvider ();
        try {
            var colored_css = EVENT_CSS.printf (background_color);
            provider.load_from_data (colored_css, colored_css.length);

            main_grid_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            location_label.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            critical (e.message);
        }
    }
}
