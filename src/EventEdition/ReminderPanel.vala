/*
 * Copyright 2011-2020 elementary, Inc. (https://elementary.io)
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
 * Authored by: Jaap Broekhuizen
 */

public class Maya.View.EventEdition.ReminderPanel : Gtk.Grid {
    private EventDialog parent_dialog;
    private Gee.ArrayList<ReminderGrid> reminders;
    private Gee.ArrayList<string> reminders_to_remove;
    private Gtk.ListBox reminder_list;

    public ReminderPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;

        expand = true;
        margin_start = margin_end = 12;
        orientation = Gtk.Orientation.VERTICAL;
        sensitive = parent_dialog.can_edit;

        var reminder_label = new Granite.HeaderLabel (_("Reminders:"));

        var no_reminder_label = new Gtk.Label (_("No Reminders"));
        var no_reminder_label_context = no_reminder_label.get_style_context ();
        no_reminder_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        no_reminder_label.show ();

        reminders = new Gee.ArrayList<ReminderGrid> ();
        reminders_to_remove = new Gee.ArrayList<string> ();

        reminder_list = new Gtk.ListBox ();
        reminder_list.expand = true;
        reminder_list.set_selection_mode (Gtk.SelectionMode.NONE);
        reminder_list.set_placeholder (no_reminder_label);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (reminder_list);
        scrolled.expand = true;

        var add_button = new Gtk.Button.with_label (_("Add Reminder"));
        add_button.always_show_image = true;
        add_button.image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON);
        add_button.margin = 3;
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var inline_toolbar = new Gtk.ActionBar ();
        inline_toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        inline_toolbar.add (add_button);

        var grid = new Gtk.Grid ();
        grid.attach (scrolled, 0, 0);
        grid.attach (inline_toolbar, 0, 1);

        var frame = new Gtk.Frame (null);
        frame.margin_top = 6;
        frame.add (grid);

        add (reminder_label);
        add (frame);
        load ();

        add_button.clicked.connect (() => {
            add_reminder ("");
        });
    }

    private ReminderGrid add_reminder (string uid) {
        var reminder = new ReminderGrid (uid);
        reminder.show_all ();

        reminder_list.add (reminder);

        reminders.add (reminder);

        reminder.removed.connect (() => {
            reminders.remove (reminder);
            reminders_to_remove.add (reminder.uid);
        });

        return reminder;
    }

    private void load () {
        if (parent_dialog.ecal == null)
            return;

        foreach (var alarm_uid in parent_dialog.ecal.get_alarm_uids ()) {
            ECal.ComponentAlarm e_alarm = parent_dialog.ecal.get_alarm (alarm_uid);
            ECal.ComponentAlarmAction action;
#if E_CAL_2_0
            action = e_alarm.get_action ();
#else
            e_alarm.get_action (out action);
#endif
            switch (action) {
                case (ECal.ComponentAlarmAction.DISPLAY):
                    ECal.ComponentAlarmTrigger trigger;
#if E_CAL_2_0
                    trigger = e_alarm.get_trigger ();
#else
                    e_alarm.get_trigger (out trigger);
#endif
                    if (trigger.get_kind () == ECal.ComponentAlarmTriggerKind.RELATIVE_START) {
                        ICal.Duration duration = trigger.get_duration ();
                        var reminder = add_reminder (alarm_uid);
                        reminder.set_duration (duration);
                    }
                    continue;
                default:
                    continue;
            }
        }
    }

    /**
     * Save the values in the dialog into the component.
     */
    public void save () {
        // Add the comment
        foreach (var reminder in reminders) {
            if (reminder.uid == "") {
                var alarm = new ECal.ComponentAlarm ();
                alarm.set_action (ECal.ComponentAlarmAction.DISPLAY);
                ECal.ComponentAlarmTrigger trigger;
#if E_CAL_2_0
                trigger = alarm.get_trigger ();
                trigger.set_duration (reminder.get_duration ());
                trigger.set_kind (ECal.ComponentAlarmTriggerKind.RELATIVE_START);
#else
                alarm.get_trigger (out trigger);
                trigger.rel_duration = reminder.get_duration ();
                trigger.type = ECal.ComponentAlarmTriggerKind.RELATIVE_START;
#endif

                alarm.set_trigger (trigger);
                parent_dialog.ecal.add_alarm (alarm);
            } else if (reminder.change == true) {
                var alarm = parent_dialog.ecal.get_alarm (reminder.uid);
                alarm.set_action (ECal.ComponentAlarmAction.DISPLAY);
                ECal.ComponentAlarmTrigger trigger;
#if E_CAL_2_0
                trigger = alarm.get_trigger ();
                trigger.set_kind (ECal.ComponentAlarmTriggerKind.RELATIVE_START);
                trigger.set_duration (reminder.get_duration ());
#else
                alarm.get_trigger (out trigger);
                trigger.rel_duration = reminder.get_duration ();
                trigger.type = ECal.ComponentAlarmTriggerKind.RELATIVE_START;
#endif
                alarm.set_trigger (trigger);
            }
        }

        foreach (var uid in reminders_to_remove) {
            parent_dialog.ecal.remove_alarm (uid);
        }
    }
}

public class Maya.View.EventEdition.ReminderGrid : Gtk.ListBoxRow {
    public signal void removed ();
    public bool change = false;
    public string uid;

    private bool is_human_change = true;

    private Gtk.ComboBoxText time;

    public ReminderGrid (string uid) {
        this.uid = uid;

        time = new Gtk.ComboBoxText ();
        time.hexpand = true;
        time.append_text (_("At time of event"));
        time.append_text (_("1 minute before"));
        time.append_text (_("5 minutes before"));
        time.append_text (_("10 minutes before"));
        time.append_text (_("15 minutes before"));
        time.append_text (_("20 minutes before"));
        time.append_text (_("25 minutes before"));
        time.append_text (_("30 minutes before"));
        time.append_text (_("45 minutes before"));
        time.append_text (_("1 hour before"));
        time.append_text (_("2 hours before"));
        time.append_text (_("3 hours before"));
        time.append_text (_("12 hours before"));
        time.append_text (_("24 hours before"));
        time.append_text (_("2 days before"));
        time.append_text (_("1 week before"));
        time.active = 3;

        time.changed.connect (() => {
            if (is_human_change == true) {
                change = true;
            }
        });

        var remove_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON);
        remove_button.relief = Gtk.ReliefStyle.NONE;
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 6;
        grid.attach (time, 0, 0, 1, 1);
        grid.attach (remove_button, 2, 0, 1, 1);

        add (grid);

        remove_button.clicked.connect (() => {
            removed ();
            destroy ();
        });
    }

    public void set_duration (ICal.Duration duration) {
        is_human_change = false;
        if (duration.get_weeks () > 0) {
            time.active = 15;
        } else if (duration.get_days () > 1) {
            time.active = 14;
        } else if (duration.get_days () > 0) {
            time.active = 13;
        } else if (duration.get_hours () > 15) {
            time.active = 13;
        } else if (duration.get_hours () > 5) {
            time.active = 12;
        } else if (duration.get_hours () > 2) {
            time.active = 11;
        } else if (duration.get_hours () > 1) {
            time.active = 10;
        } else if (duration.get_hours () > 0) {
            time.active = 9;
        } else if (duration.get_minutes () > 30) {
            time.active = 8;
        } else if (duration.get_minutes () > 25) {
            time.active = 7;
        } else if (duration.get_minutes () > 20) {
            time.active = 6;
        } else if (duration.get_minutes () > 15) {
            time.active = 5;
        } else if (duration.get_minutes () > 10) {
            time.active = 4;
        } else if (duration.get_minutes () > 5) {
            time.active = 3;
        } else if (duration.get_minutes () > 1) {
            time.active = 2;
        } else if (duration.get_minutes () > 0) {
            time.active = 1;
        } else {
            time.active = 0;
        }
        is_human_change = true;
    }

    public ICal.Duration get_duration () {
#if E_CAL_2_0
        var duration = new ICal.Duration.null_duration ();
#else
        var duration = ICal.Duration.null_duration ();
#endif
        switch (time.active) {
            case 1:
#if E_CAL_2_0
                duration.set_minutes (1);
#else
                duration.minutes = 1;
#endif
                break;
            case 2:
#if E_CAL_2_0
                duration.set_minutes (5);
#else
                duration.minutes = 5;
#endif
                break;
            case 3:
#if E_CAL_2_0
                duration.set_minutes (10);
#else
                duration.minutes = 10;
#endif
                break;
            case 4:
#if E_CAL_2_0
                duration.set_minutes (15);
#else
                duration.minutes = 15;
#endif
                break;
            case 5:
#if E_CAL_2_0
                duration.set_minutes (20);
#else
                duration.minutes = 20;
#endif
                break;
            case 6:
#if E_CAL_2_0
                duration.set_minutes (25);
#else
                duration.minutes = 25;
#endif
                break;
            case 7:
#if E_CAL_2_0
                duration.set_minutes (30);
#else
                duration.minutes = 30;
#endif
                break;
            case 8:
#if E_CAL_2_0
                duration.set_minutes (45);
#else
                duration.minutes = 45;
#endif
                break;
            case 9:
#if E_CAL_2_0
                duration.set_hours (1);
#else
                duration.hours = 1;
#endif
                break;
            case 10:
#if E_CAL_2_0
                duration.set_hours (2);
#else
                duration.hours = 2;
#endif
                break;
            case 11:
#if E_CAL_2_0
                duration.set_hours (3);
#else
                duration.hours = 3;
#endif
                break;
            case 12:
#if E_CAL_2_0
                duration.set_hours (12);
#else
                duration.hours = 12;
#endif
                break;
            case 13:
#if E_CAL_2_0
                duration.set_hours (24);
#else
                duration.hours = 24;
#endif
                break;
            case 14:
#if E_CAL_2_0
                duration.set_days (2);
#else
                duration.days = 2;
#endif
                break;
            case 15:
#if E_CAL_2_0
                duration.set_weeks (1);
#else
                duration.weeks = 1;
#endif
                break;
        }
        return duration;
    }
}
