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
public class Maya.View.WeekLabels : Granite.Bin {
    private Gtk.Grid day_grid;
    private Gtk.Label[] labels;
    private int nr_of_weeks;

    private static GLib.Settings show_weeks;

    static construct {
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
        day_grid.add_css_class ("weeks");

        set_nr_of_weeks (5);
        day_grid.insert_row (1);

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

        var gtk_menu = new Gtk.PopoverMenu.from_model (menu) {
            has_arrow = false
        };
        gtk_menu.set_parent (this);

        var click_gesture = new Gtk.GestureClick () {
            button = 0
        };
        click_gesture.pressed.connect ((n_press, x, y) => {
            var sequence = click_gesture.get_current_sequence ();
            var event = click_gesture.get_last_event (sequence);

            if (event.triggers_context_menu ()) {
                Maya.EventMenu.popup_at_pointer (gtk_menu, x, y);

                click_gesture.set_state (CLAIMED);
                click_gesture.reset ();
            }
        });

        var long_press_gesture = new Gtk.GestureLongPress () {
            touch_only = true
        };
        long_press_gesture.pressed.connect ((x, y) => {
            Maya.EventMenu.popup_at_pointer (gtk_menu, x, y);

            long_press_gesture.set_state (CLAIMED);
            long_press_gesture.reset ();
        });

        add_controller (click_gesture);
        add_controller (long_press_gesture);
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
                labels[c].add_css_class ("weeklabel");

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
