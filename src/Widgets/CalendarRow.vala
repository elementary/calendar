/*
 * Copyright 2014-2021 elementary, Inc. (https://elementary.io)
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
 */

public class CalendarRow : Gtk.Box {

    private const string CALENDAR_COLOR_STYLE = """
        .cal-color {
            background-color: %s;
            border-radius: 50%;
        }
    """;

    public string label { public get; private set; }
    public string location { public get; private set; }
    public bool selected { public get; public set; }
    private E.Source _source;
    public E.Source source {
        get {
            return _source;
        }

        set {
            _source = value;
            apply_source ();
        }
    }

    private Gtk.StyleContext calendar_color_context;

    public CalendarRow (E.Source source) {
        Object (source: source);
    }

    construct {
        var calendar_color = new Gtk.Grid () {
            height_request = 12,
            width_request = 12,
            valign = CENTER
        };
        calendar_color.get_style_context ().add_class ("cal-color");

        calendar_color_context = calendar_color.get_style_context ();

        var calendar_name_label = new Gtk.Label ("") {
            hexpand = true,
            ellipsize = MIDDLE,
            xalign = 0
        };

        var selection_icon = new Gtk.Image.from_icon_name ("object-select-symbolic", Gtk.IconSize.MENU) {
            no_show_all = true,
            visible = false
        };

        spacing = 6;
        add (calendar_color);
        add (calendar_name_label);
        add (selection_icon);

        bind_property ("label", calendar_name_label, "label");
        bind_property ("selected", selection_icon, "visible");
    }

    private void apply_source () {
        E.SourceCalendar cal = (E.SourceCalendar)_source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
        label = _source.dup_display_name ();
        location = Maya.Util.get_source_location (_source);

        var css_color = CALENDAR_COLOR_STYLE.printf (cal.dup_color ());
        var style_provider = new Gtk.CssProvider ();

        try {
            style_provider.load_from_data (css_color, css_color.length);
            calendar_color_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, css_color);
        }
    }
}
