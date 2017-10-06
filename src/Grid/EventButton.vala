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

/**
 * Represents a single event on the grid.
 */
public class Maya.View.EventButton : Gtk.Revealer {
    public signal void edition_request ();
    public E.CalComponent comp {get; private set;}
    private Gtk.EventBox event_box;
    private Gtk.Grid internal_grid;
    Gtk.Label label;

    public EventButton (E.CalComponent comp) {
        this.comp = comp;
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        internal_grid = new Gtk.Grid ();
        internal_grid.column_spacing = 6;
        event_box = new Gtk.EventBox ();
        var fake_label = new Gtk.Label (" ");
        event_box.add (fake_label);
        event_box.set_size_request (4, 2);

        event_box.scroll_event.connect ((event) => {return GesturesUtils.on_scroll_event (event);});
        internal_grid.attach (event_box, 0, 0, 1, 1);
        event_box.show ();
        var event_box = new Gtk.EventBox ();
        event_box.events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        event_box.events |= Gdk.EventMask.SCROLL_MASK;
        event_box.events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        event_box.add (internal_grid);
        event_box.button_press_event.connect ((event) => {
            if (event.type == Gdk.EventType.2BUTTON_PRESS && event.button == Gdk.BUTTON_PRIMARY) {
                E.Source src = comp.get_data ("source");
                if (src.writable == true && Model.CalendarModel.get_default ().calclient_is_readonly (src) == false) {
                    edition_request ();
                    return true;
                }
            }

            return false;
        });

        Gtk.TargetEntry dnd = {"binary/calendar", 0, 0};
        Gtk.TargetEntry dnd2 = {"text/uri-list", 0, 0};
        Gtk.drag_source_set (event_box, Gdk.ModifierType.BUTTON1_MASK, {dnd, dnd2}, Gdk.DragAction.MOVE);
        event_box.drag_data_get.connect ( (ctx, sel, info, time) => {
            Model.CalendarModel.get_default ().drag_component = comp;
            unowned iCal.Component icalcomp = comp.get_icalcomponent ();
            unowned string ical_str = icalcomp.as_ical_string ();
            sel.set_text (ical_str, ical_str.length);
            try {
                var path = GLib.Path.build_filename (GLib.Environment.get_tmp_dir (), icalcomp.get_summary () + ".ics");
                var file = File.new_for_path (path);
                if (file.replace_contents (ical_str.data, null, false, FileCreateFlags.PRIVATE, null))
                    sel.set_uris ({file.get_uri ()});
            } catch (Error e) {
                critical (e.message);
            }
        });

        add (event_box);
        label = new Gtk.Label(get_summary ());
        label.set_ellipsize(Pango.EllipsizeMode.END);
        internal_grid.attach (label, 1, 0, 1, 1);
        label.hexpand = true;
        label.wrap = false;
        ((Gtk.Misc) label).xalign = 0.0f;
        label.show ();

        E.Source source = comp.get_data ("source");
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
        cal.notify["color"].connect (() => {
            set_color (cal.dup_color ());
        });

        set_color (cal.dup_color ());
    }

    public void update (E.CalComponent event) {
       this.comp = comp;
       label.label = get_summary ();
    }

    public string get_summary () {
        return comp.get_summary ().value;
    }

    public void set_color (string color) {
        var rgba = Gdk.RGBA();
        rgba.parse (color);
        event_box.override_background_color (Gtk.StateFlags.NORMAL, rgba);
    }

    /**
     * Compares the given buttons according to date.
     */
    public static GLib.CompareDataFunc<Maya.View.EventButton>? compare_buttons = (button1, button2) => {
        var comp1 = button1.comp;
        var comp2 = button2.comp;

        return Util.compare_events (comp1, comp2);
    };

}
