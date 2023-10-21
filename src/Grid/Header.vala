// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
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
 *              Corentin Noël <corentin@elementaryos.org>
 */

namespace Maya.View {

/**
 * Represents the header at the top of the calendar grid.
 */
public class Header : Gtk.EventBox {
    private Gtk.Grid header_grid;
    private Gtk.Label[] labels;

    private static GLib.Settings show_weeks;
    private static Gtk.CssProvider style_provider;

    static construct {
        style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("/io/elementary/calendar/Header.css");

        if (Application.wingpanel_settings != null) {
            show_weeks = Application.wingpanel_settings;
        } else {
            show_weeks = Application.saved_state;
        }
    }

    construct {
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;

        header_grid = new Gtk.Grid ();
        header_grid.insert_column (7);
        header_grid.insert_row (1);
        header_grid.set_column_homogeneous (true);
        header_grid.set_row_homogeneous (true);
        header_grid.column_spacing = 0;
        header_grid.row_spacing = 0;

        // EventBox properties
        set_visible_window (true); // needed for style
        get_style_context ().add_provider (style_provider, 600);

        labels = new Gtk.Label[7];
        for (int c = 0; c < 7; c++) {
            labels[c] = new Gtk.Label ("");
            labels[c].hexpand = true;

            unowned Gtk.StyleContext label_context = labels[c].get_style_context ();
            label_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            label_context.add_class ("daylabel");

            header_grid.attach (labels[c], c, 0);
        }

        add (header_grid);

        button_press_event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == Gdk.BUTTON_SECONDARY) {
                var show_weeks_menuitem = new Gtk.MenuItem ();
                if (show_weeks.get_boolean ("show-weeks")) {
                    show_weeks_menuitem.label = _("Hide Week Numbers");
                } else {
                    show_weeks_menuitem.label = _("Show Week Numbers");
                }

                show_weeks_menuitem.activate.connect (() => {
                    show_weeks.set_boolean ("show-weeks", !show_weeks.get_boolean ("show-weeks"));
                });

                var menu = new Gtk.Menu ();
                menu.attach_to_widget (this, null);
                menu.add (show_weeks_menuitem);
                menu.show_all ();
                menu.popup_at_pointer (event);
            }

            return false;
        });
    }

    public void update_columns (int week_starts_on) {
        var date = Calendar.Util.datetime_strip_time (new DateTime.now_local ());
        date = date.add_days (week_starts_on - date.get_day_of_week ());
        foreach (var label in labels) {
            label.label = date.format ("%a");
            date = date.add_days (1);
        }
    }
}

}
