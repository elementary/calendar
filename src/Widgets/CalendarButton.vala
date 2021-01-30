/*
 * Copyright 2014-2018 elementary, Inc. (https://elementary.io)
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
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.Widgets.CalendarButton : Gtk.MenuButton {

    private CalendarRow current_calendar_grid;
    private Widgets.CalendarChooser calchooser;

    public GLib.List<E.Source> sources {
        get { return calchooser.sources; }
    }
    public E.Source current_source {
        get {
            return calchooser.current_source;
        }
        set {
            calchooser.current_source = value;
        }
    }

    construct {
        calchooser = new Widgets.CalendarChooser ();
        calchooser.margin_bottom = 6;

        current_calendar_grid = new CalendarRow (current_source);
        assert (current_source != null);
        current_calendar_grid.halign = Gtk.Align.START;
        current_calendar_grid.hexpand = true;

        var button_grid = new Gtk.Grid ();
        button_grid.column_spacing = 6;
        button_grid.add (current_calendar_grid);
        button_grid.add (new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU));
        add (button_grid);

        popover = new Gtk.Popover (this);
        popover.width_request = 310;
        popover.add (calchooser);

        calchooser.notify["current-source"].connect ((s, p) => {
            current_calendar_grid.source = calchooser.current_source;
            tooltip_text = "%s - %s".printf (current_calendar_grid.label, current_calendar_grid.location);
        });

        popover.unmap.connect (() => {
            calchooser.clear_search_entry ();
        });

        // TODO popdown when selection changed
    }
}
