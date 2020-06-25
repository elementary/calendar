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
    public signal void removed (ECal.Component event);

    public ECal.Component calevent { get; construct; }
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
        CELEBRATION,
        CALL,
        DRINKS,
        DRIVING,
        FLIGHT,
        FOOD,
        LEGAL,
        MOVIE,
        WEDDING,
        N_CATEGORIES;

        public unowned string get_builtin_keywords () {
            switch (this) {
                case APPOINTMENT:
                    ///Translators: Give a list of appointment related keywords, separated by semicolons.
                    ///The number of words can differ from US English and need not be a direct translation.
                    return _("appointment;meeting");

                case CELEBRATION:
                    ///Translators: Give a list of celebration (party) related keywords, separated by semicolons.
                    ///The number of words can differ from US English and need not be a direct translation.
                    return _("birthday;anniversary;party");

                case CALL:
                    ///Translators: Give a list of voice call related keywords, separated by semicolons.
                    ///The number of words can differ from US English and need not be a direct translation.
                    return _("call;phone;telephone;ring");

                case DRINKS:
                    ///Translators: Give a list of social drinking related keywords, separated by semicolons.
                    ///The number of words can differ from US English and need not be a direct translation.
                    return _("bar;cocktails;drinks;happy hour");

                case DRIVING:
                    ///Translators: Give a list of car driving related keywords, separated by semicolons.
                    ///The number of words can differ from US English and need not be a direct translation.
                    return _("car;drive;driving;road trip;");

                case FLIGHT:
                    ///Translators: Give a list of air travel related keywords, separated by semicolons.
                    ///The number of words can differ from US English and need not be a direct translation.
                    return _("flight;airport;");

                case FOOD:
                    ///Translators: Give a list of food consumption related keywords, separated by semicolons.
                    ///The number of words can differ from US English and need not be a direct translation.
                    return _("breakfast;brunch;dinner;lunch;supper;steakhouse;burger;meal;barbecue");

                case LEGAL:
                    ///Translators: Give a list of law related keywords, separated by semicolons.
                    ///The number of words can differ from US English and need not be a direct translation.
                   return _("court;jury;tax;attorney;lawyer;contract");

                case MOVIE:
                    ///Translators: Give a list of movie (film) related keywords, separated by semicolons.
                    ///The number of words can differ from US English and need not be a direct translation.
                    return _("movie");

                case WEDDING:
                    ///Translators: Give a list of wedding related keywords, separated by semicolons.
                    ///The number of words can differ from US English and need not be a direct translation.
                    return _("wedding");

                default:
                    return "";
            }
        }

        public unowned string? get_icon_name () {
            switch (this) {
                case APPOINTMENT:
                    return "event-appointment-symbolic";

                case CELEBRATION:
                    return "event-birthday-symbolic";

                case CALL:
                    return "event-call-symbolic";

                case DRINKS:
                    return "event-cocktails-symbolic";

                case DRIVING:
                    return "event-driving-symbolic";

                case FLIGHT:
                    return "event-flight-symbolic";

                case FOOD:
                    return "event-food-symbolic";

                case LEGAL:
                    return "event-legal-symbolic";

                case MOVIE:
                    return "event-movie-symbolic";

                case WEDDING:
                    return "event-wedding-symbolic";

                default:
                    return null;
            }
        }
    }

    private Gee.HashMultiMap<Category, string> keyword_map;


    public AgendaEventRow (E.Source source, ECal.Component calevent, bool is_upcoming) {
        Object (
            calevent: calevent,
            is_upcoming: is_upcoming,
            source: source
        );
    }

    construct {
        keyword_map = new Gee.HashMultiMap<Category, string> ();
        for (uint cat = Category.APPOINTMENT; cat < Category.N_CATEGORIES; cat++) {
            split_keywords ((Category)cat);
        }

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
            var menu = new Maya.EventMenu (calevent);
            menu.attach_to_widget (this, null);
            menu.popup_at_pointer (event);
            menu.show_all ();
        }

        return Gdk.EVENT_PROPAGATE;
    }

    /**
     * Updates the event to match the given event.
     */
    public void update (ECal.Component event) {
        unowned ICal.Component ical_event = event.get_icalcomponent ();
        summary = ical_event.get_summary ();
        name_label.set_markup (Markup.escape_text (summary));

        var event_name = name_label.label.down ();

        var current_category = Category.NONE;
        var current_hits = 0;

        for (uint u = Category.APPOINTMENT; u < Category.N_CATEGORIES; u++) {
            find_keywords ((Category)u, event_name, ref current_category, ref current_hits);
        }

        var icon_name_from_keywords = current_category.get_icon_name ();
        if (icon_name_from_keywords != null) {
            event_image.icon_name = icon_name_from_keywords;
        }

        DateTime start_date, end_date;
        Calendar.Util.icalcomponent_get_local_datetimes (ical_event, out start_date, out end_date);

        is_allday = Calendar.Util.datetime_is_all_day (start_date, end_date);
        is_multiday = Calendar.Util.icalcomponent_is_multiday (ical_event);

        var date_format = Granite.DateTime.get_default_date_format (true, true, false);
        string start_date_string = start_date.format (date_format);
        string end_date_string = end_date.format (date_format);
        string start_time_string = start_date.format (Settings.time_format ());
        string end_time_string = end_date.format (Settings.time_format ());
        string? datetime_string = null;

        var is_same_time = start_time_string == end_time_string;

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
                    if (is_same_time) {
                        datetime_string = start_time_string;
                    } else {
                        // TRANSLATORS: A range from start time to end time i.e. "7:00 PM – 9:00 PM"
                        datetime_string = C_("time-range", "%s – %s").printf (start_time_string, end_time_string);
                    }
                }
            } else {
                if (is_allday) {
                    datetime_string = "%s".printf (start_date_string);
                } else {
                    if (is_same_time) {
                        // TRANSLATORS: A single time from the start date i.e. "Friday, Dec 21 at 7:00 PM"
                        datetime_string = _("%s at %s").printf (start_date_string, start_time_string);
                    } else {
                        // TRANSLATORS: A range from start date and time to end time i.e. "Friday, Dec 21, 7:00 PM – 9:00 PM"
                        datetime_string = _("%s, %s – %s").printf (start_date_string, start_time_string, end_time_string);
                    }
                }
            }
        }

        datatime_label.label = "<small>%s</small>".printf (datetime_string);
        location_label.label = ical_event.get_location ();
    }

    private void find_keywords (Category category, string phrase, ref Category current_category, ref int current_hits) {
        int hits = 0;
        foreach (string keyword in keyword_map.@get (category)) {
            if (phrase.contains (keyword)) {
                hits += keyword.length;
            }
        }

        if (hits > current_hits) {
            current_hits = hits;
            current_category = category;
        }
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

    private void split_keywords (Category category) {
        var words = category.get_builtin_keywords ().split (";");
        foreach (unowned string? word in words) {
            if (word != null && word != "") {
                keyword_map.@set (category, word);
            }
        }
    }
}
