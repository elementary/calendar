/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Maxwell Barvian
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.EventButton : Granite.Bin {
    public ECal.Component comp { get; construct set; }

    private Gtk.Revealer revealer;
    private Gtk.Label label;
    private Gtk.StyleContext grid_style_context;

    public EventButton (ECal.Component comp) {
        Object (
             comp: comp
         );
    }

    construct {
        label = new Gtk.Label (comp.get_summary ().get_value ()) {
            hexpand = true,
            ellipsize = END,
            xalign = 0
        };
        label.show ();

        var internal_grid = new Gtk.Grid ();
        internal_grid.attach (label, 0, 0);

        grid_style_context = internal_grid.get_style_context ();
        grid_style_context.add_class ("event");

        revealer = new Gtk.Revealer () {
            child = internal_grid,
            transition_type = CROSSFADE
        };

        child = revealer;

        var context_menu = Maya.EventMenu.build (comp);
        context_menu.set_parent (this);

        var click_gesture = new Gtk.GestureClick () {
            button = 0
        };
        click_gesture.pressed.connect ((n_press, x, y) => {
            var sequence = click_gesture.get_current_sequence ();
            var event = click_gesture.get_last_event (sequence);

            if (n_press == 2 && click_gesture.get_current_button () == Gdk.BUTTON_PRIMARY) {
                ((Maya.Application) GLib.Application.get_default ()).window.on_modified (comp);
                click_gesture.set_state (CLAIMED);
                click_gesture.reset ();
                return;
            }

            if (event.triggers_context_menu ()) {
                Maya.EventMenu.popup_at_pointer (context_menu, x, y);

                click_gesture.set_state (CLAIMED);
                click_gesture.reset ();
            }
        });

        var long_press_gesture = new Gtk.GestureLongPress () {
            touch_only = true
        };
        long_press_gesture.pressed.connect ((x, y) => {
            Maya.EventMenu.popup_at_pointer (context_menu, x, y);

            long_press_gesture.set_state (CLAIMED);
            long_press_gesture.reset ();
        });

        add_controller (click_gesture);
        add_controller (long_press_gesture);

        // Gtk.TargetEntry dnd = {"binary/calendar", 0, 0};
        // Gtk.TargetEntry dnd2 = {"text/uri-list", 0, 0};
        // Gtk.drag_source_set (event_box, Gdk.ModifierType.BUTTON1_MASK, {dnd, dnd2}, Gdk.DragAction.MOVE);

        // event_box.drag_data_get.connect ( (ctx, sel, info, time) => {
        //     Calendar.EventStore.get_default ().drag_component = comp;
        //     unowned ICal.Component icalcomp = comp.get_icalcomponent ();
        //     var ical_str = icalcomp.as_ical_string ();
        //     sel.set_text (ical_str, ical_str.length);
        //     try {
        //         var path = GLib.Path.build_filename (GLib.Environment.get_tmp_dir (), icalcomp.get_summary () + ".ics");
        //         var file = File.new_for_path (path);
        //         if (file.replace_contents (ical_str.data, null, false, FileCreateFlags.PRIVATE, null))
        //             sel.set_uris ({file.get_uri ()});
        //     } catch (Error e) {
        //         critical (e.message);
        //     }
        // });

        E.Source source = comp.get_data ("source");

        var cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        reload_css (cal.dup_color ());

        cal.notify["color"].connect (() => {
            reload_css (cal.dup_color ());
        });
    }

    public string get_uid () {
        return comp.get_id ().get_uid ();
    }

    public void update (ECal.Component modified) {
        this.comp = modified;
        label.label = comp.get_summary ().get_value ();
    }

    private void reload_css (string background_color) {
        var provider = new Gtk.CssProvider ();
        try {
            var colored_css = EVENT_CSS.printf (background_color.slice (0, 7));
            provider.load_from_string (colored_css);

            grid_style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            critical (e.message);
        }
    }

    public void destroy_button () {
        revealer.reveal_child = false;
        Timeout.add (revealer.transition_duration, () => {
            destroy ();
            return false;
        });
    }

    public void hide_without_animate () {
        if (!revealer.child_revealed) {
            return;
        }

        var reveal_duration = revealer.transition_duration;
        revealer.transition_duration = 0;
        revealer.reveal_child = false;
        revealer.transition_duration = reveal_duration;

        hide ();
    }

    public void show_without_animate () {
        show ();

        if (revealer.child_revealed) {
            return;
        }

        var reveal_duration = revealer.transition_duration;
        revealer.transition_duration = 0;
        revealer.reveal_child = true;
        revealer.transition_duration = reveal_duration;
    }
}
