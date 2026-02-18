/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Jaap Broekhuizen
 */

public class Maya.View.EventEdition.ReminderPanel : Gtk.Box {
    private EventDialog parent_dialog;
    private Gee.ArrayList<ReminderGrid> reminders;
    private Gee.ArrayList<string> reminders_to_remove;
    private Gtk.ListBox reminder_list;

    public ReminderPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;

        var no_reminder_label = new Gtk.Label (_("No Reminders"));
        no_reminder_label.show ();

        no_reminder_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        no_reminder_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        reminders = new Gee.ArrayList<ReminderGrid> ();
        reminders_to_remove = new Gee.ArrayList<string> ();

        reminder_list = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true,
            selection_mode = NONE
        };
        reminder_list.set_placeholder (no_reminder_label);

        var reminder_label = new Granite.HeaderLabel (_("Reminders")) {
            mnemonic_widget = reminder_list
        };

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            child = reminder_list,
            hexpand = true,
            vexpand = true,
        };

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.add (new Gtk.Image.from_icon_name ("list-add-symbolic", BUTTON));
        add_button_box.add (new Gtk.Label (_("Add Reminder")));

        var add_button = new Gtk.Button () {
            child = add_button_box
        };
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var inline_toolbar = new Gtk.ActionBar ();
        inline_toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        inline_toolbar.pack_start (add_button);

        var box = new Gtk.Box (VERTICAL, 0);
        box.add (scrolled);
        box.add (inline_toolbar);

        var frame = new Gtk.Frame (null) {
            child = box,
            margin_top = 6
        };

        margin_start = margin_end = 12;
        orientation = VERTICAL;
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
            action = e_alarm.get_action ();
            switch (action) {
                case (ECal.ComponentAlarmAction.DISPLAY):
                    ECal.ComponentAlarmTrigger trigger;
                    trigger = e_alarm.get_trigger ();
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
                trigger = new ECal.ComponentAlarmTrigger.relative (
                    ECal.ComponentAlarmTriggerKind.RELATIVE_START,
                    reminder.get_duration ()
                );

                alarm.set_trigger (trigger);
                parent_dialog.ecal.add_alarm (alarm);
            } else if (reminder.change == true) {
                var alarm = parent_dialog.ecal.get_alarm (reminder.uid).copy ();
                alarm.set_action (ECal.ComponentAlarmAction.DISPLAY);
                ECal.ComponentAlarmTrigger trigger;
                trigger = alarm.get_trigger ();
                trigger.set_kind (ECal.ComponentAlarmTriggerKind.RELATIVE_START);
                trigger.set_duration (reminder.get_duration ());
                alarm.set_trigger (trigger);
                parent_dialog.ecal.remove_alarm (reminder.uid);
                parent_dialog.ecal.add_alarm (alarm);
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

        var remove_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", BUTTON) {
            relief = NONE
        };
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var box = new Gtk.Box (HORIZONTAL, 6) {
            margin_top = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6
        };
        box.add (time);
        box.add (remove_button);

        child = box;

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
        var duration = new ICal.Duration.null_duration ();
        switch (time.active) {
            case 1:
                duration.set_minutes (1);
                break;
            case 2:
                duration.set_minutes (5);
                break;
            case 3:
                duration.set_minutes (10);
                break;
            case 4:
                duration.set_minutes (15);
                break;
            case 5:
                duration.set_minutes (20);
                break;
            case 6:
                duration.set_minutes (25);
                break;
            case 7:
                duration.set_minutes (30);
                break;
            case 8:
                duration.set_minutes (45);
                break;
            case 9:
                duration.set_hours (1);
                break;
            case 10:
                duration.set_hours (2);
                break;
            case 11:
                duration.set_hours (3);
                break;
            case 12:
                duration.set_hours (12);
                break;
            case 13:
                duration.set_hours (24);
                break;
            case 14:
                duration.set_days (2);
                break;
            case 15:
                duration.set_weeks (1);
                break;
        }
        return duration;
    }
}
