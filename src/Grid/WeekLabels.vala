/*-
 * Copyright (c) 2011-2026 elementary, Inc. (https://elementary.io)
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
 * Represent the week labels at the left side of the grid.
 */
public class Maya.View.WeekLabels : Gtk.Bin {
    private Gtk.Grid day_grid;
    private Gtk.Label[] labels;
    private int nr_of_weeks;

    private static GLib.Settings show_weeks;
    private static Gtk.CssProvider style_provider;

    private Gtk.GestureMultiPress click_gesture;
    private Gtk.GestureLongPress long_press_gesture;

    static construct {
        style_provider = new Gtk.CssProvider ();
        style_provider.load_from_resource ("/io/elementary/calendar/WeekLabels.css");

        if (Application.wingpanel_settings != null) {
            show_weeks = Application.wingpanel_settings;
        } else {
            show_weeks = Application.saved_state;
        }
    }

    construct {
        day_grid = new Gtk.Grid () {
            row_homogeneous = true
        };
        day_grid.get_style_context ().add_class ("weeks");

        set_nr_of_weeks (5);
        day_grid.insert_row (1);

        unowned Gtk.StyleContext day_grid_context = day_grid.get_style_context ();
        day_grid_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var revealer = new Gtk.Revealer () {
            child = day_grid,
            transition_type = SLIDE_RIGHT
        };

        child = revealer;
        vexpand = true;

        show_weeks.bind ("show-weeks", revealer, "reveal-child", GLib.SettingsBindFlags.DEFAULT);

        var action_show_weeks = show_weeks.create_action ("show-weeks");

        var action_group = new SimpleActionGroup ();
        action_group.add_action (action_show_weeks);

        insert_action_group ("week-labels", action_group);

        var menu = new GLib.Menu ();
        menu.append (_("Show Week Numbers"), "week-labels.show-weeks");

        var gtk_menu = new Gtk.Menu.from_model (menu) {
            attach_widget = this
        };

        click_gesture = new Gtk.GestureMultiPress (revealer) {
            button = 0
        };
        click_gesture.pressed.connect ((n_press, x, y) => {
            var sequence = click_gesture.get_current_sequence ();
            var event = click_gesture.get_last_event (sequence);

            if (event.triggers_context_menu ()) {
                gtk_menu.popup_at_pointer (event);

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

            gtk_menu.popup_at_pointer (event);

            long_press_gesture.set_state (CLAIMED);
            long_press_gesture.reset ();
        });
    }

    public void update (DateTime date, int nr_of_weeks) {
        if (show_weeks.get_boolean ("show-weeks")) {
            if (labels != null) {
                foreach (var label in labels) {
                    label.destroy ();
                }
            }

            labels = new Gtk.Label[nr_of_weeks];
            for (int c = 0; c < nr_of_weeks; c++) {
                labels[c] = new Gtk.Label ("") {
                    valign = START,
                    width_chars = 2
                };
                labels[c].get_style_context ().add_class ("weeklabel");

                unowned Gtk.StyleContext label_context = labels[c].get_style_context ();
                label_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

                day_grid.attach (labels[c], 0, c);
                labels[c].show ();
            }

            var next = date;
            // Find the beginning of the week which is apparently always a monday
            int days_to_add = (8 - next.get_day_of_week ()) % 7;
            next = next.add_days (days_to_add);
            foreach (var label in labels) {
                label.label = next.get_week_of_year ().to_string ();
                next = next.add_weeks (1);
            }
        }
    }

    public void set_nr_of_weeks (int new_number) {
        day_grid.insert_row (new_number);
        nr_of_weeks = new_number;
    }

    public int get_nr_of_weeks () {
        return nr_of_weeks;
    }
}
