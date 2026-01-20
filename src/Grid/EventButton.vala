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
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.EventButton : Gtk.Revealer {
    public ECal.Component comp { get; construct set; }

    private Gtk.Label label;
    private Gtk.StyleContext grid_style_context;

    public EventButton (ECal.Component comp) {
        Object (
             comp: comp
         );
    }

    construct {
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;

        label = new Gtk.Label (comp.get_summary ().get_value ());
        label.hexpand = true;
        label.ellipsize = Pango.EllipsizeMode.END;
        label.xalign = 0;
        label.show ();

        var internal_grid = new Gtk.Grid ();
        internal_grid.add (label);

        grid_style_context = internal_grid.get_style_context ();
        grid_style_context.add_class ("event");

        var event_box = new Gtk.EventBox ();
        event_box.add (internal_grid);

        add (event_box);

        var context_menu = Maya.EventMenu.build (comp);
        context_menu.attach_to_widget (this, null);

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
                context_menu.popup_at_pointer (event);

                click_gesture.set_state (CLAIMED);
                click_gesture.reset ();
            }
        });

        var long_press_gesture = new Gtk.GestureLongPress () {
            touch_only = true
        };
        long_press_gesture.pressed.connect ((x, y) => {
            var sequence = long_press_gesture.get_current_sequence ();
            var event = long_press_gesture.get_last_event (sequence);

            context_menu.popup_at_pointer (event);

            long_press_gesture.set_state (CLAIMED);
            long_press_gesture.reset ();
        });

        add_controller (click_gesture);
        add_controller (long_press_gesture);

        Gtk.TargetEntry dnd = {"binary/calendar", 0, 0};
        Gtk.TargetEntry dnd2 = {"text/uri-list", 0, 0};
        Gtk.drag_source_set (event_box, Gdk.ModifierType.BUTTON1_MASK, {dnd, dnd2}, Gdk.DragAction.MOVE);

        event_box.drag_data_get.connect ( (ctx, sel, info, time) => {
            Calendar.EventStore.get_default ().drag_component = comp;
            unowned ICal.Component icalcomp = comp.get_icalcomponent ();
            var ical_str = icalcomp.as_ical_string ();
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
            provider.load_from_data (colored_css, colored_css.length);

            grid_style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            critical (e.message);
        }
    }

    public void destroy_button () {
        set_reveal_child (false);
        Timeout.add (transition_duration, () => {
            destroy ();
            return false;
        });
    }
}
