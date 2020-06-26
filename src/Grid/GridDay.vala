// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2018 elementary, Inc. (https://elementary.io)
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
 * Represents a single day on the grid.
 */
public class Maya.View.GridDay : Gtk.EventBox {

    /*
     * Event emitted when the day is double clicked or the ENTER key is pressed.
     */
    public signal void on_event_add (DateTime date);

    public DateTime date { get; construct set; }

    // We need to know if it is the first column in order to not draw it's left border
    public bool draw_left_border = true;
    private VAutoHider event_box;
    private GLib.HashTable<string, EventButton> event_buttons;

    public bool in_current_month {
        set {
            if (value) {
                get_style_context ().remove_class (Gtk.STYLE_CLASS_DIM_LABEL);
            } else {
                get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            }
        }
    }

    private const int EVENT_MARGIN = 3;

    private static Gtk.CssProvider style_provider;

    public GridDay (DateTime date) {
        Object (date: date);
    }

    static construct {
        style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("/io/elementary/calendar/Grid.css");
    }

    construct {
        event_buttons = new GLib.HashTable<string, EventButton> (str_hash, str_equal);

        event_box = new VAutoHider ();
        event_box.margin = EVENT_MARGIN;
        event_box.margin_top = 0;
        event_box.expand = true;

        // EventBox Properties
        can_focus = true;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;

        unowned Gtk.StyleContext style_context = get_style_context ();
        style_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        style_context.add_class ("cell");

        var label = new Gtk.Label ("");
        label.halign = Gtk.Align.END;
        label.get_style_context ().add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        label.margin = EVENT_MARGIN;
        label.margin_bottom = 0;
        label.name = "date";

        var container_grid = new Gtk.Grid ();
        container_grid.attach (label, 0, 0, 1, 1);
        container_grid.attach (event_box, 0, 1, 1, 1);
        container_grid.show_all ();

        add (container_grid);

        // Signals and handlers
        button_press_event.connect (on_button_press);
        key_press_event.connect (on_key_press);
        scroll_event.connect ((event) => {return GesturesUtils.on_scroll_event (event);});

        Gtk.TargetEntry dnd = {"binary/calendar", 0, 0};
        Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, {dnd}, Gdk.DragAction.MOVE);

        this.notify["date"].connect (() => {
            label.label = date.get_day_of_month ().to_string ();
        });
    }

    public override bool drag_drop (Gdk.DragContext context, int x, int y, uint time_) {
        Gtk.drag_finish (context, true, false, time_);
        Gdk.Atom atom = Gtk.drag_dest_find_target (this, context, Gtk.drag_dest_get_target_list (this));
        Gtk.drag_get_data (this, context, atom, time_);
        return true;
    }

    public override void drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint info, uint time_) {
        var calmodel = Calendar.Store.get_default ();
        var comp = calmodel.drag_component;
        unowned ICal.Component icalcomp = comp.get_icalcomponent ();
        E.Source src = comp.get_data ("source");
        var start = icalcomp.get_dtstart ();
        var end = icalcomp.get_dtend ();
        var gap = date.get_day_of_month () - start.get_day ();
#if E_CAL_2_0
        start.set_day (start.get_day () + gap);
#else
        start.day += gap;
#endif

        if (!end.is_null_time ()) {
#if E_CAL_2_0
            end.set_day (end.get_day () + gap);
#else
            end.day += gap;
#endif
            icalcomp.set_dtend (end);
        }

        icalcomp.set_dtstart (start);
        calmodel.update_event (src, comp, ECal.ObjModType.ALL);
    }

    public void add_event_button (EventButton button) {
        unowned ICal.Component calcomp = button.comp.get_icalcomponent ();
        string uid = calcomp.get_uid ();
        lock (event_buttons) {
            if (event_buttons.contains (uid)) {
                return;
            }

            event_buttons.set (uid, button);
        }

        if (button.get_parent () != null) {
            button.unparent ();
        }

        event_box.add (button);
        button.show_all ();

    }

    public bool update_event (ECal.Component comp) {
        unowned ICal.Component calcomp = comp.get_icalcomponent ();
        string uid = calcomp.get_uid ();

        lock (event_buttons) {
            var button = event_buttons.get (uid);
            if (button != null) {
                button.update (comp);
                event_box.update (button);
            } else {
                return false;
            }
        }

        return true;
    }

    public void remove_event (ECal.Component comp) {
        unowned ICal.Component calcomp = comp.get_icalcomponent ();
        string uid = calcomp.get_uid ();
        lock (event_buttons) {
            var button = event_buttons.get (uid);
            if (button != null) {
                event_buttons.remove (uid);
                destroy_button (button);
            }
        }
    }

    public void clear_events () {
        foreach (weak EventButton button in event_buttons.get_values ()) {
            destroy_button (button);
        }

        event_buttons.remove_all ();
    }

    private void destroy_button (EventButton button) {
        button.set_reveal_child (false);
        Timeout.add (button.transition_duration, () => {
            button.destroy ();
            return false;
        });
    }

    public void set_selected (bool selected) {
        if (selected) {
            set_state_flags (Gtk.StateFlags.SELECTED, true);
        } else {
            set_state_flags (Gtk.StateFlags.NORMAL, true);
        }
    }

    private bool on_button_press (Gdk.EventButton event) {
        if (event.type == Gdk.EventType.2BUTTON_PRESS && event.button == Gdk.BUTTON_PRIMARY)
            on_event_add (date);

        grab_focus ();
        return false;
    }

    private bool on_key_press (Gdk.EventKey event) {
        if (event.keyval == Gdk.keyval_from_name ("Return") ) {
            on_event_add (date);
            return true;
        }

        return false;
    }
}
