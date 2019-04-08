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

    public E.CalComponent calevent { get; construct; }
    public E.Source source { get; construct; }
    public bool is_upcoming { get; construct; }

    public string summary { public get; private set; }
    public bool is_allday { public get; private set; default = false; }
    public bool is_multiday { public get; private set; default = false; }
    public Gtk.Revealer revealer { public get; private set; }

    private Gtk.Image event_image;
    private Gtk.Label name_label;
    private Gtk.Label datatime_label;
    private Gtk.Label location_label;
    private Gtk.StyleContext event_image_context;
    private Gtk.StyleContext main_grid_context;

    private enum Category {
        NONE,
        APPOINTMENT,
        BIRTHDAY,
        CALL,
        DRIVING,
        FLIGHT,
        FOOD,
        LEGAL,
        MOVIE,
        WEDDING
    }

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

        event_image = new Gtk.Image.from_icon_name ("office-calendar-symbolic", Gtk.IconSize.MENU);
        event_image.pixel_size = 16;
        event_image.valign = Gtk.Align.START;

        event_image_context = event_image.get_style_context ();
        event_image_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        name_label = new Gtk.Label ("");
        name_label.selectable = true;
        name_label.wrap = true;
        name_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        name_label.xalign = 0;

        var name_label_context = name_label.get_style_context ();
        name_label_context.add_class ("title");
        name_label_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        datatime_label = new Gtk.Label ("");
        datatime_label.ellipsize = Pango.EllipsizeMode.END;
        datatime_label.halign = Gtk.Align.START;
        datatime_label.selectable = true;
        datatime_label.use_markup = true;
        datatime_label.xalign = 0;
        datatime_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        location_label = new Gtk.Label ("");
        location_label.margin_top = 6;
        location_label.selectable = true;
        location_label.wrap = true;
        location_label.xalign = 0;

        var location_revealer = new Gtk.Revealer ();
        location_revealer.add (location_label);

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
        if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == Gdk.BUTTON_SECONDARY) {
            var start_date = Util.ical_to_date_time (calevent.get_icalcomponent ().get_dtstart ());

            var menu = new Maya.EventMenu (calevent, start_date);
            menu.attach_to_widget (this, null);
            menu.popup_at_pointer (event);
            menu.show_all ();
        }

        return Gdk.EVENT_PROPAGATE;
    }

    /**
     * Updates the event to match the given event.
     */
    public void update (E.CalComponent event) {
        unowned iCal.Component ical_event = event.get_icalcomponent ();
        summary = ical_event.get_summary ();
        name_label.set_markup (Markup.escape_text (summary));

        string[] appointment_keywords = {
            _("appointment"),
            _("meeting")
        };

        string[] birthday_keywords = {
            _("birthday")
        };

        string[] call_keywords = {
            _("call"),
            _("phone")
        };

        string[] driving_keywords = {
            _("car"),
            _("drive"),
            _("rental"),
            _("road trip")
        };

        string[] flight_keywords = {
            _("flight")
        };

        string[] food_keywords = {
            _("breakfast"), 
            _("brunch"),
            _("dinner"),
            _("lunch"),
            _("reservation"),
            _("steakhouse"),
            _("supper"),
        };

        string[] legal_keywords = {
            _("court"),
            _("jury"),
            _("tax")
        };

        string[] movie_keywords = {
            _("movie")
        };

        string[] wedding_keywords = {
            _("wedding")
        };

        var event_name = name_label.label.down ();
        var appointment_hits = find_keywords (appointment_keywords, event_name);
        var birthday_hits = find_keywords (birthday_keywords, event_name);
        var call_hits = find_keywords (call_keywords, event_name);
        var driving_hits = find_keywords (driving_keywords, event_name);
        var flight_hits = find_keywords (flight_keywords, event_name);
        var food_hits = find_keywords (food_keywords, event_name);
        var legal_hits = find_keywords (legal_keywords, event_name);
        var movie_hits = find_keywords (movie_keywords, event_name);
        var wedding_hits = find_keywords (wedding_keywords, event_name);

        var largest_category = Category.NONE;
        int largest_value = 0;

        if (birthday_hits > largest_value) {
            largest_category = Category.BIRTHDAY;
            largest_value = birthday_hits;
        }

        if (call_hits > largest_value) {
            largest_category = Category.CALL;
            largest_value = call_hits;
        }

        if (driving_hits > largest_value) {
            largest_category = Category.DRIVING;
            largest_value = driving_hits;
        }

        if (flight_hits > largest_value) {
            largest_category = Category.FLIGHT;
            largest_value = flight_hits;
        }

        if (food_hits > largest_value) {
            largest_category = Category.FOOD;
            largest_value = food_hits;
        }

        if (legal_hits > largest_value) {
            largest_category = Category.LEGAL;
            largest_value = legal_hits;
        }

        if (movie_hits > largest_value) {
            largest_category = Category.MOVIE;
            largest_value = movie_hits;
        }

        if (wedding_hits > largest_value) {
            largest_category = Category.WEDDING;
        }

        /* "Appointment" is really generic, so only assign it if others have not been assigned */
        if (appointment_hits > largest_value) {
            largest_category = Category.APPOINTMENT;
            largest_value = appointment_hits;
        }

        switch (largest_category) {
            case Category.APPOINTMENT:
                event_image.icon_name = "event-appointment-symbolic";
                break;
            case Category.BIRTHDAY:
                event_image.icon_name = "event-birthday-symbolic";
                break;
            case Category.CALL:
                event_image.icon_name = "event-call-symbolic";
                break;
            case Category.DRIVING:
                event_image.icon_name = "event-driving-symbolic";
                break;
            case Category.FLIGHT:
                event_image.icon_name = "event-flight-symbolic";
                break;
            case Category.FOOD:
                event_image.icon_name = "event-food-symbolic";
                break;
            case Category.LEGAL:
                event_image.icon_name = "event-legal-symbolic";
                break;
            case Category.MOVIE:
                event_image.icon_name = "event-movie-symbolic";
                break;
            case Category.WEDDING:
                event_image.icon_name = "event-wedding-symbolic";
                break;
        }

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
        location_label.label = ical_event.get_location ();
    }

    private int find_keywords (string[] keywords, string phrase) {
        int hits = 0;
        foreach (unowned string keyword in keywords) {
            if (keyword in phrase) {
                hits++;
            }
        }

        return hits;
    }

    private void reload_css (string background_color) {
        var provider = new Gtk.CssProvider ();
        try {
            var colored_css = EVENT_CSS.printf (background_color);
            provider.load_from_data (colored_css, colored_css.length);

            event_image_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            main_grid_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            critical (e.message);
        }
    }
}
