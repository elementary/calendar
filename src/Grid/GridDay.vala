/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
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
    private Gtk.EventControllerKey key_controller;
    private Gtk.GestureMultiPress click_gesture;

    public bool in_current_month {
        set {
            if (value) {
                get_style_context ().remove_class (Gtk.STYLE_CLASS_DIM_LABEL);
            } else {
                get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            }
        }
    }

    public GridDay (DateTime date) {
        Object (date: date);
    }

    static construct {
        var style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("/io/elementary/calendar/Grid.css");

        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
            style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    construct {
        event_buttons = new GLib.HashTable<string, EventButton>.full (str_hash, str_equal, null, (value_data) => {
            ((EventButton)value_data).destroy_button ();
        });

        event_box = new VAutoHider () {
            expand = true
        };

        var label = new Gtk.Label ("") {
            halign = END,
            name = "date",
        };

        var container_box = new Gtk.Box (VERTICAL, 0);
        container_box.add (label);
        container_box.add (event_box);

        can_focus = true;
        child = container_box;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        get_style_context ().add_class ("cell");

        // Signals and handlers
        click_gesture = new Gtk.GestureMultiPress (this) {
            button = Gdk.BUTTON_PRIMARY,
            propagation_phase = BUBBLE
        };
        click_gesture.released.connect (on_button_press);

        key_controller = new Gtk.EventControllerKey (this) {
            propagation_phase = BUBBLE
        };
        key_controller.key_pressed.connect (on_key_press);

        scroll_event.connect ((event) => {return GesturesUtils.on_scroll_event (event);});

        Gtk.TargetEntry dnd = {"binary/calendar", 0, 0};
        Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, {dnd}, Gdk.DragAction.MOVE);

        this.bind_property ("date", label, "label", BindingFlags.SYNC_CREATE, (binding, srcval, ref targetval) => {
            unowned var date = (GLib.DateTime) srcval.get_boxed ();
            targetval.take_string (date.get_day_of_month ().to_string ());
            return true;
        });
    }

    public override bool drag_drop (Gdk.DragContext context, int x, int y, uint time_) {
        Gtk.drag_finish (context, true, false, time_);
        Gdk.Atom atom = Gtk.drag_dest_find_target (this, context, Gtk.drag_dest_get_target_list (this));
        Gtk.drag_get_data (this, context, atom, time_);
        return true;
    }

    public override void drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint info, uint time_) {
        var calmodel = Calendar.EventStore.get_default ();
        var comp = calmodel.drag_component;
        unowned ICal.Component icalcomp = comp.get_icalcomponent ();
        E.Source src = comp.get_data ("source");
        var start = icalcomp.get_dtstart ();
        var end = icalcomp.get_dtend ();
        var gap = date.get_day_of_month () - start.get_day ();
        start.set_day (start.get_day () + gap);

        if (!end.is_null_time ()) {
            end.set_day (end.get_day () + gap);
            icalcomp.set_dtend (end);
        }

        icalcomp.set_dtstart (start);
        calmodel.update_event (src, comp, ECal.ObjModType.ALL);
    }

    public void add_event_button (EventButton button) {
        string uid = button.get_uid ();
        lock (event_buttons) {
            event_buttons.remove (uid);
            event_buttons.set (uid, button);
        }

        if (button.get_parent () != null) {
            button.unparent ();
        }

        event_box.add (button);
        button.show_all ();
    }

    public bool update_event (ECal.Component modified_event) {
        string uid = modified_event.get_id ().get_uid ();
        lock (event_buttons) {
            var uidbutton = event_buttons.get (uid);
            if (uidbutton != null) {
                uidbutton.update (modified_event);
                event_box.update (uidbutton);
                return true;
            }
        }

        return false;
    }

    public void remove_event (ECal.Component comp) {
        string uid = comp.get_id ().get_uid ();

        lock (event_buttons) {
            event_buttons.remove (uid);
        }
    }

    public void clear_events () {
        event_buttons.remove_all ();
    }

    public void set_selected (bool selected) {
        if (selected) {
            set_state_flags (Gtk.StateFlags.SELECTED, true);
        } else {
            set_state_flags (Gtk.StateFlags.NORMAL, true);
        }
    }

    private void on_button_press (int n_press, double x, double y) {
        if (n_press == 2) {
            on_event_add (date);
        }

        grab_focus ();
    }

    private bool on_key_press (Gtk.EventControllerKey event, uint keyval, uint keycode, Gdk.ModifierType state) {
        if (keyval == Gdk.keyval_from_name ("Return") ) {
            on_event_add (date);
            return true;
        }

        return false;
    }
}
