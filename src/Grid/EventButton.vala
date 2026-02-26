/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Maxwell Barvian
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.EventButton : Gtk.Bin {
    public ECal.Component comp { get; construct set; }

    private const Gtk.TargetEntry DND = {"binary/calendar", 0, 0};
    private const Gtk.TargetEntry DND2 = {"text/uri-list", 0, 1};

    private Gtk.Revealer revealer;
    private Gtk.Label label;
    private Gtk.StyleContext grid_style_context;

    private Gtk.GestureMultiPress click_gesture;
    private Gtk.GestureLongPress long_press_gesture;

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
        internal_grid.add (label);

        grid_style_context = internal_grid.get_style_context ();
        grid_style_context.add_class ("event");

        var event_box = new Gtk.EventBox ();
        event_box.add (internal_grid);

        revealer = new Gtk.Revealer () {
            child = event_box,
            transition_type = CROSSFADE
        };

        child = revealer;

        var context_menu = Maya.EventMenu.build (comp);
        context_menu.attach_to_widget (this, null);

        click_gesture = new Gtk.GestureMultiPress (this) {
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
                context_menu.popup_at_pointer (event);

                click_gesture.set_state (CLAIMED);
                click_gesture.reset ();
            }
        });

        long_press_gesture = new Gtk.GestureLongPress (this) {
            touch_only = true
        };
        long_press_gesture.pressed.connect ((x, y) => {
            var sequence = long_press_gesture.get_current_sequence ();
            var event = long_press_gesture.get_last_event (sequence);

            context_menu.popup_at_pointer (event);

            long_press_gesture.set_state (CLAIMED);
            long_press_gesture.reset ();
        });

        Gtk.drag_source_set (event_box, Gdk.ModifierType.BUTTON1_MASK, {DND, DND2}, Gdk.DragAction.MOVE);

        event_box.drag_data_get.connect (on_drag_data_get);

        E.Source source = comp.get_data ("source");

        var cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        reload_css (cal.dup_color ());

        cal.notify["color"].connect (() => {
            reload_css (cal.dup_color ());
        });
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time) {
        unowned ICal.Component icalcomp = comp.get_icalcomponent ();
        switch (target_type) {
            case 0:
                var ical_str = icalcomp.as_ical_string ();
                selection_data.set_text (ical_str, ical_str.length);
                break;
            case 1:
                var ical_str = comp.get_as_string ();
                try {
                    var path = GLib.Path.build_filename (GLib.Environment.get_tmp_dir (), icalcomp.get_summary () + ".ics");
                    var file = File.new_for_path (path);
                    if (file.replace_contents (ical_str.data, null, false, FileCreateFlags.PRIVATE, null)) {
                        selection_data.set_uris ({file.get_uri ()});
                    }
                } catch (Error e) {
                    critical (e.message);
                }
                break;
        };
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
            provider.load_from_data (colored_css, colored_css.length);

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
