/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2026 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Jaap Broekhuizen
 */

public class Maya.View.EventEdition.RepeatPanel : Granite.Bin {
    private EventDialog parent_dialog;
    private Gtk.Switch repeat_switch;
    private Gtk.ComboBoxText repeat_combobox;
    private Gtk.ComboBoxText ends_combobox;
    private Gtk.SpinButton repeats_spinbutton;
    private Granite.DatePicker end_datepicker;
    private Gtk.Box week_box;
    private Gtk.SpinButton every_entry;
    private Gtk.ListBox exceptions_list;

    private Gtk.ToggleButton mon_button;
    private Gtk.ToggleButton tue_button;
    private Gtk.ToggleButton wed_button;
    private Gtk.ToggleButton thu_button;
    private Gtk.ToggleButton fri_button;
    private Gtk.ToggleButton sat_button;
    private Gtk.ToggleButton sun_button;

    private Gtk.CheckButton every_radiobutton;
    private Gtk.CheckButton same_radiobutton;

    public RepeatPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;

        var reminder_label = new Granite.HeaderLabel (_("Repeat:"));

        repeat_switch = new Gtk.Switch () {
            valign = CENTER
        };

        repeat_combobox = new Gtk.ComboBoxText () {
            hexpand = true,
            sensitive = false
        };
        repeat_combobox.append_text (_("Daily"));
        repeat_combobox.append_text (_("Weekly"));
        repeat_combobox.append_text (_("Monthly"));
        repeat_combobox.append_text (_("Yearly"));
        repeat_combobox.active = 1;

        var repeat_box = new Gtk.Box (HORIZONTAL, 12);
        repeat_box.append (repeat_switch);
        repeat_box.append (repeat_combobox);

        var every_label = new Granite.HeaderLabel (_("Every:"));

        every_entry = new Gtk.SpinButton.with_range (1, 99, 1) {
            hexpand = true
        };

        var every_unit_label = new Gtk.Label (ngettext ("Week", "Weeks", 1));

        var every_box = new Gtk.Box (HORIZONTAL, 12) {
            sensitive = false
        };
        every_box.append (every_entry);
        every_box.append (every_unit_label);

        var ends_label = new Granite.HeaderLabel (_("Ends:"));

        ends_combobox = new Gtk.ComboBoxText () {
            hexpand = true
        };
        ends_combobox.append_text (_("Never"));
        ends_combobox.append_text (_("Until"));
        ends_combobox.append_text (_("After"));
        ends_combobox.active = 0;

        repeats_spinbutton = new Gtk.SpinButton.with_range (1, 99, 1) {
            hexpand = true
        };

        ///Translators: Give a word to describe an event ending after a certain number of repeats.
        ///This will be displayed in the format like: "Ends After 2 Repeats",
        ///where this string always represents the last word in the phrase.
        var repeats_label = new Gtk.Label (ngettext ("Repeat", "Repeats", 1));

        var end_repeat_box = new Gtk.Box (HORIZONTAL, 12);
        end_repeat_box.append (repeats_spinbutton);
        end_repeat_box.append (repeats_label);

        var end_repeat_revealer = new Gtk.Revealer () {
            child = end_repeat_box
        };

        var format = Granite.DateTime.get_default_date_format (false, true, true);

        end_datepicker = new Granite.DatePicker.with_format (format);

        var end_date_revealer = new Gtk.Revealer () {
            child = end_datepicker
        };

        var ends_box = new Granite.Box (VERTICAL, HALF) {
            sensitive = false
        };
        ends_box.append (ends_combobox);
        ends_box.append (end_date_revealer);
        ends_box.append (end_repeat_revealer);

        mon_button = new Gtk.ToggleButton.with_label (_("Mon"));
        tue_button = new Gtk.ToggleButton.with_label (_("Tue"));
        wed_button = new Gtk.ToggleButton.with_label (_("Wed"));
        thu_button = new Gtk.ToggleButton.with_label (_("Thu"));
        fri_button = new Gtk.ToggleButton.with_label (_("Fri"));
        sat_button = new Gtk.ToggleButton.with_label (_("Sat"));
        sun_button = new Gtk.ToggleButton.with_label (_("Sun"));

        week_box = new Gtk.Box (HORIZONTAL, 6) {
            homogeneous = true,
            sensitive = false
        };
        week_box.append (mon_button);
        week_box.append (tue_button);
        week_box.append (wed_button);
        week_box.append (thu_button);
        week_box.append (fri_button);
        week_box.append (sat_button);
        week_box.append (sun_button);

        var weekday_revealer = new Gtk.Revealer () {
            child = week_box
        };

        same_radiobutton = new Gtk.CheckButton.with_label (_("The same day every month"));
        every_radiobutton = new Gtk.CheckButton () {
            group = same_radiobutton
        };

        var monthly_box = new Gtk.Box (VERTICAL, 6) {
            sensitive = false
        };
        monthly_box.append (same_radiobutton);
        monthly_box.append (every_radiobutton);

        var monthly_revealer = new Gtk.Revealer () {
            child = monthly_box
        };

        var exceptions_label = new Granite.HeaderLabel (_("Exceptions:"));

        var no_exceptions_label = new Gtk.Label (_("No Exceptions")) {
            margin_top = 12,
            margin_bottom = 12
        };
        no_exceptions_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);
        no_exceptions_label.add_css_class (Granite.CssClass.DIM);

        exceptions_list = new Gtk.ListBox () {
            selection_mode = NONE
        };
        exceptions_list.set_placeholder (no_exceptions_label);

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.append (new Gtk.Image.from_icon_name ("list-add-symbolic"));
        add_button_box.append (new Gtk.Label (_("Add Exception")));

        var add_button = new Gtk.Button () {
            child = add_button_box,
            has_frame = false
        };

        var inline_toolbar = new Gtk.ActionBar ();
        inline_toolbar.add_css_class (Granite.STYLE_CLASS_FLAT);
        inline_toolbar.pack_start (add_button);

        var exceptions_box = new Gtk.Box (VERTICAL, 0) {
            margin_bottom = 12,
            overflow = HIDDEN,
            sensitive = false
        };
        exceptions_box.append (exceptions_list);
        exceptions_box.append (inline_toolbar);
        exceptions_box.add_css_class (Granite.CssClass.CARD);

        var main_box = new Granite.Box (VERTICAL, HALF) {
            margin_start = 12,
            margin_end = 12
        };
        main_box.append (reminder_label);
        main_box.append (repeat_box);
        main_box.append (every_label);
        main_box.append (every_box);
        main_box.append (weekday_revealer);
        main_box.append (monthly_revealer);
        main_box.append (ends_label);
        main_box.append (ends_box);
        main_box.append (exceptions_label);
        main_box.append (exceptions_box);

        var scrolled = new Gtk.ScrolledWindow () {
            child = main_box
        };

        child = scrolled;

        reorder_week_box ();
        Calendar.EventStore.get_default ().notify["week-starts-on"].connect (reorder_week_box);

        add_button.clicked.connect (() => {
            var exception_grid = new ExceptionGrid (new GLib.DateTime.now_local ());
            exceptions_list.append (exception_grid);
        });

        repeat_switch.notify["active"].connect (() => {
            bool active = repeat_switch.active;
            repeat_combobox.sensitive = active;
            every_box.sensitive = active;
            week_box.sensitive = active;
            monthly_box.sensitive = active;
            ends_box.sensitive = active;
            exceptions_box.sensitive = active;
        });
        repeat_switch.active = false;

        repeat_combobox.changed.connect (() => {
            switch (repeat_combobox.active) {
                // Weekly
                case 1:
                    weekday_revealer.reveal_child = true;
                    monthly_revealer.reveal_child = false;
                    break;
                // Monthly
                case 2:
                    int day_of_week = parent_dialog.date_time.get_day_of_week () + 1;
                    if (day_of_week > 7) {
                        day_of_week = 1;
                    }
                    set_every_day ((short)(day_of_week + Math.ceil ((double)parent_dialog.date_time.get_day_of_month () / (double)7) * 8));

                    weekday_revealer.reveal_child = false;
                    monthly_revealer.reveal_child = true;
                    break;
                default:
                    monthly_revealer.reveal_child = false;
                    weekday_revealer.reveal_child = false;
                    break;
            }

            every_entry.value_changed ();
        });

        every_entry.value_changed.connect (() => {
            switch (repeat_combobox.active) {
                case 0:
                    every_unit_label.label = ngettext ("Day", "Days", (ulong)every_entry.value);
                    break;
                case 1:
                    every_unit_label.label = ngettext ("Week", "Weeks", (ulong)every_entry.value);
                    break;
                case 2:
                    every_unit_label.label = ngettext ("Month", "Months", (ulong)every_entry.value);
                    break;
                case 3:
                    every_unit_label.label = ngettext ("Year", "Years", (ulong)every_entry.value);
                    break;
            }
        });

        ends_combobox.changed.connect (() => {
            // On Date
            end_date_revealer.reveal_child = ends_combobox.active == 1;

            // After n repeats
            end_repeat_revealer.reveal_child = ends_combobox.active == 2;
        });

        repeats_spinbutton.value_changed.connect (() => {
            repeats_label.label = ngettext ("Repeat", "Repeats", (ulong)repeats_spinbutton.value);
        });

        load ();

        repeat_switch.grab_focus ();
    }

    private void load_weekly_recurrence (ICal.Recurrence rrule) {
        repeat_combobox.active = 1;
        var by_day = rrule.get_by_day_array ();
        for (
            uint i = 0;
            i < by_day.length && (by_day.index (i) != ICal.RecurrenceArrayMaxValues.RECURRENCE_ARRAY_MAX);
            i++
        ) {
            switch (ICal.Recurrence.day_day_of_week (by_day.index (i))) {
                case ICal.RecurrenceWeekday.SUNDAY_WEEKDAY:
                    sun_button.active = true;
                    break;
                case ICal.RecurrenceWeekday.MONDAY_WEEKDAY:
                    mon_button.active = true;
                    break;
                case ICal.RecurrenceWeekday.TUESDAY_WEEKDAY:
                    tue_button.active = true;
                    break;
                case ICal.RecurrenceWeekday.WEDNESDAY_WEEKDAY:
                    wed_button.active = true;
                    break;
                case ICal.RecurrenceWeekday.THURSDAY_WEEKDAY:
                    thu_button.active = true;
                    break;
                case ICal.RecurrenceWeekday.FRIDAY_WEEKDAY:
                    fri_button.active = true;
                    break;
                case ICal.RecurrenceWeekday.SATURDAY_WEEKDAY:
                    sat_button.active = true;
                    break;
                default:
                    i = by_day.length;
                    break;
            }
        }
    }

    private void load_monthly_recurrence (ICal.Recurrence rrule) {
        repeat_combobox.active = 2;
        if (rrule.get_by_month_day (0) != ICal.RecurrenceArrayMaxValues.RECURRENCE_ARRAY_MAX) {
            same_radiobutton.active = true;
        } else {
            var by_day = rrule.get_by_day (0);
            if (by_day != ICal.RecurrenceArrayMaxValues.RECURRENCE_ARRAY_MAX) {
                set_every_day (by_day);
                every_radiobutton.active = true;
            }
        }
    }

    private void load () {
        if (parent_dialog.ecal == null)
            return;

        unowned ICal.Component comp = parent_dialog.ecal.get_icalcomponent ();
        // Load the guests
        ICal.Property property;
        property = comp.get_first_property (ICal.PropertyKind.RRULE_PROPERTY);
        if (property != null) {
            repeat_switch.active = true;
            var rrule = property.get_rrule ();
            switch (rrule.get_freq ()) {
                case (ICal.RecurrenceFrequency.WEEKLY_RECURRENCE):
                    load_weekly_recurrence (rrule);
                    break;
                case (ICal.RecurrenceFrequency.MONTHLY_RECURRENCE):
                    load_monthly_recurrence (rrule);
                    break;
                case (ICal.RecurrenceFrequency.YEARLY_RECURRENCE):
                    repeat_combobox.active = 3;
                    break;
                default:
                    warning ("%d", (int)rrule.get_freq ());
                    repeat_combobox.active = 0;
                    break;
            }

            every_entry.value = rrule.get_interval ();
            var until = rrule.get_until ();
            if (until.is_null_time ()) {
                ends_combobox.active = 0;
            } else {
                ends_combobox.active = 1;
                end_datepicker.date = Calendar.Util.icaltime_to_datetime (until);
            }
            if (rrule.get_count () > 0) {
                repeats_spinbutton.value = rrule.get_count ();
                ends_combobox.active = 2;
            }
        }

        property = comp.get_first_property (ICal.PropertyKind.EXDATE_PROPERTY);
        while (property != null) {
            var exdate = property.get_exdate ();
            var exception_grid = new ExceptionGrid (Calendar.Util.icaltime_to_datetime (exdate));
            exceptions_list.append (exception_grid);
            property = comp.get_next_property (ICal.PropertyKind.EXDATE_PROPERTY);
        }
    }

    /**
     * This can't be simplified because of some problems with the translation.
     * see https://bugs.launchpad.net/maya/+bug/1405605 for reference.
     */
    private void set_every_day (short day) {
        var day_position = ICal.Recurrence.day_position (day);
        var weekday = ICal.Recurrence.day_day_of_week (day);
        switch (day_position) {
            case -1:
                switch (weekday) {
                    case ICal.RecurrenceWeekday.SUNDAY_WEEKDAY:
                        every_radiobutton.label = _("Every last Sunday");
                        break;
                    case ICal.RecurrenceWeekday.MONDAY_WEEKDAY:
                        every_radiobutton.label = _("Every last Monday");
                        break;
                    case ICal.RecurrenceWeekday.TUESDAY_WEEKDAY:
                        every_radiobutton.label = _("Every last Tuesday");
                        break;
                    case ICal.RecurrenceWeekday.WEDNESDAY_WEEKDAY:
                        every_radiobutton.label = _("Every last Wednesday");
                        break;
                    case ICal.RecurrenceWeekday.THURSDAY_WEEKDAY:
                        every_radiobutton.label = _("Every last Thursday");
                        break;
                    case ICal.RecurrenceWeekday.FRIDAY_WEEKDAY:
                        every_radiobutton.label = _("Every last Friday");
                        break;
                    default:
                        every_radiobutton.label = _("Every last Saturday");
                        break;
                }
                break;
            case 1:
                switch (weekday) {
                    case ICal.RecurrenceWeekday.SUNDAY_WEEKDAY:
                        every_radiobutton.label = _("Every first Sunday");
                        break;
                    case ICal.RecurrenceWeekday.MONDAY_WEEKDAY:
                        every_radiobutton.label = _("Every first Monday");
                        break;
                    case ICal.RecurrenceWeekday.TUESDAY_WEEKDAY:
                        every_radiobutton.label = _("Every first Tuesday");
                        break;
                    case ICal.RecurrenceWeekday.WEDNESDAY_WEEKDAY:
                        every_radiobutton.label = _("Every first Wednesday");
                        break;
                    case ICal.RecurrenceWeekday.THURSDAY_WEEKDAY:
                        every_radiobutton.label = _("Every first Thursday");
                        break;
                    case ICal.RecurrenceWeekday.FRIDAY_WEEKDAY:
                        every_radiobutton.label = _("Every first Friday");
                        break;
                    default:
                        every_radiobutton.label = _("Every first Saturday");
                        break;
                }
                break;
            case 2:
                switch (weekday) {
                    case ICal.RecurrenceWeekday.SUNDAY_WEEKDAY:
                        every_radiobutton.label = _("Every second Sunday");
                        break;
                    case ICal.RecurrenceWeekday.MONDAY_WEEKDAY:
                        every_radiobutton.label = _("Every second Monday");
                        break;
                    case ICal.RecurrenceWeekday.TUESDAY_WEEKDAY:
                        every_radiobutton.label = _("Every second Tuesday");
                        break;
                    case ICal.RecurrenceWeekday.WEDNESDAY_WEEKDAY:
                        every_radiobutton.label = _("Every second Wednesday");
                        break;
                    case ICal.RecurrenceWeekday.THURSDAY_WEEKDAY:
                        every_radiobutton.label = _("Every second Thursday");
                        break;
                    case ICal.RecurrenceWeekday.FRIDAY_WEEKDAY:
                        every_radiobutton.label = _("Every second Friday");
                        break;
                    default:
                        every_radiobutton.label = _("Every second Saturday");
                        break;
                }
                break;
            case 3:
                switch (weekday) {
                    case ICal.RecurrenceWeekday.SUNDAY_WEEKDAY:
                        every_radiobutton.label = _("Every third Sunday");
                        break;
                    case ICal.RecurrenceWeekday.MONDAY_WEEKDAY:
                        every_radiobutton.label = _("Every third Monday");
                        break;
                    case ICal.RecurrenceWeekday.TUESDAY_WEEKDAY:
                        every_radiobutton.label = _("Every third Tuesday");
                        break;
                    case ICal.RecurrenceWeekday.WEDNESDAY_WEEKDAY:
                        every_radiobutton.label = _("Every third Wednesday");
                        break;
                    case ICal.RecurrenceWeekday.THURSDAY_WEEKDAY:
                        every_radiobutton.label = _("Every third Thursday");
                        break;
                    case ICal.RecurrenceWeekday.FRIDAY_WEEKDAY:
                        every_radiobutton.label = _("Every third Friday");
                        break;
                    default:
                        every_radiobutton.label = _("Every third Saturday");
                        break;
                }
                break;
            case 4:
                switch (weekday) {
                    case ICal.RecurrenceWeekday.SUNDAY_WEEKDAY:
                        every_radiobutton.label = _("Every fourth Sunday");
                        break;
                    case ICal.RecurrenceWeekday.MONDAY_WEEKDAY:
                        every_radiobutton.label = _("Every fourth Monday");
                        break;
                    case ICal.RecurrenceWeekday.TUESDAY_WEEKDAY:
                        every_radiobutton.label = _("Every fourth Tuesday");
                        break;
                    case ICal.RecurrenceWeekday.WEDNESDAY_WEEKDAY:
                        every_radiobutton.label = _("Every fourth Wednesday");
                        break;
                    case ICal.RecurrenceWeekday.THURSDAY_WEEKDAY:
                        every_radiobutton.label = _("Every fourth Thursday");
                        break;
                    case ICal.RecurrenceWeekday.FRIDAY_WEEKDAY:
                        every_radiobutton.label = _("Every fourth Friday");
                        break;
                    default:
                        every_radiobutton.label = _("Every fourth Saturday");
                        break;
                }
                break;
            default:
                switch (weekday) {
                    case ICal.RecurrenceWeekday.SUNDAY_WEEKDAY:
                        every_radiobutton.label = _("Every fifth Sunday");
                        break;
                    case ICal.RecurrenceWeekday.MONDAY_WEEKDAY:
                        every_radiobutton.label = _("Every fifth Monday");
                        break;
                    case ICal.RecurrenceWeekday.TUESDAY_WEEKDAY:
                        every_radiobutton.label = _("Every fifth Tuesday");
                        break;
                    case ICal.RecurrenceWeekday.WEDNESDAY_WEEKDAY:
                        every_radiobutton.label = _("Every fifth Wednesday");
                        break;
                    case ICal.RecurrenceWeekday.THURSDAY_WEEKDAY:
                        every_radiobutton.label = _("Every fifth Thursday");
                        break;
                    case ICal.RecurrenceWeekday.FRIDAY_WEEKDAY:
                        every_radiobutton.label = _("Every fifth Friday");
                        break;
                    default:
                        every_radiobutton.label = _("Every fifth Saturday");
                        break;
                }
                break;
        }
    }

    private void reorder_week_box () {
        switch (Calendar.EventStore.get_default ().week_starts_on) {
            case MONDAY:
                week_box.reorder_child_after (tue_button, mon_button);
                week_box.reorder_child_after (wed_button, tue_button);
                week_box.reorder_child_after (thu_button, wed_button);
                week_box.reorder_child_after (fri_button, thu_button);
                week_box.reorder_child_after (sat_button, fri_button);
                week_box.reorder_child_after (sun_button, sat_button);
                break;
            case TUESDAY:
                week_box.reorder_child_after (wed_button, tue_button);
                week_box.reorder_child_after (thu_button, wed_button);
                week_box.reorder_child_after (fri_button, thu_button);
                week_box.reorder_child_after (sat_button, fri_button);
                week_box.reorder_child_after (sun_button, sat_button);
                week_box.reorder_child_after (mon_button, sun_button);
                break;
            case WEDNESDAY:
                week_box.reorder_child_after (thu_button, wed_button);
                week_box.reorder_child_after (fri_button, thu_button);
                week_box.reorder_child_after (sat_button, fri_button);
                week_box.reorder_child_after (sun_button, sat_button);
                week_box.reorder_child_after (mon_button, sun_button);
                week_box.reorder_child_after (tue_button, mon_button);
                break;
            case THURSDAY:
                week_box.reorder_child_after (fri_button, thu_button);
                week_box.reorder_child_after (sat_button, fri_button);
                week_box.reorder_child_after (sun_button, sat_button);
                week_box.reorder_child_after (mon_button, sun_button);
                week_box.reorder_child_after (tue_button, mon_button);
                week_box.reorder_child_after (wed_button, tue_button);
                break;
            case FRIDAY:
                week_box.reorder_child_after (sat_button, fri_button);
                week_box.reorder_child_after (sun_button, sat_button);
                week_box.reorder_child_after (mon_button, sun_button);
                week_box.reorder_child_after (tue_button, mon_button);
                week_box.reorder_child_after (wed_button, tue_button);
                week_box.reorder_child_after (thu_button, wed_button);
                break;
            case SATURDAY:
                week_box.reorder_child_after (sun_button, sat_button);
                week_box.reorder_child_after (mon_button, sun_button);
                week_box.reorder_child_after (tue_button, mon_button);
                week_box.reorder_child_after (wed_button, tue_button);
                week_box.reorder_child_after (thu_button, wed_button);
                week_box.reorder_child_after (fri_button, thu_button);
                break;
            case SUNDAY:
                week_box.reorder_child_after (mon_button, sun_button);
                week_box.reorder_child_after (tue_button, mon_button);
                week_box.reorder_child_after (wed_button, tue_button);
                week_box.reorder_child_after (thu_button, wed_button);
                week_box.reorder_child_after (fri_button, thu_button);
                week_box.reorder_child_after (sat_button, fri_button);
                break;
            case BAD_WEEKDAY:
                break;
        }
    }

    /*
     * Replace it by ICal.Recurrence.encode_day once libical-glib 3.1 is available
     */
    private short encode_day (ICal.RecurrenceWeekday weekday, int position) {
        return (weekday + (8 * position.abs ())) * ((position < 0) ? -1 : 1);
    }

    /**
     * Save the values in the dialog into the component.
     */
    public void save () {
        // First clear all rrules
        unowned ICal.Component comp = parent_dialog.ecal.get_icalcomponent ();
        int count = comp.count_properties (ICal.PropertyKind.RRULE_PROPERTY);

            ICal.Property remove_prop;

        for (int i = 0; i < count; i++) {
            remove_prop = comp.get_first_property (ICal.PropertyKind.RRULE_PROPERTY);
            comp.remove_property (remove_prop);
        }

        remove_prop = comp.get_first_property (ICal.PropertyKind.RECURRENCEID_PROPERTY);
        comp.remove_property (remove_prop);

        if (repeat_switch.active == false)
            return;

        // Add the rrule
        var property = new ICal.Property (ICal.PropertyKind.RRULE_PROPERTY);

        var rrule = new ICal.Recurrence.from_string ("");
        switch (repeat_combobox.active) {
            case 1:
                rrule.set_freq (ICal.RecurrenceFrequency.WEEKLY_RECURRENCE);
                var array = new GLib.Array<short> (false, false, sizeof (short));
                if (sun_button.active == true) {
                    short day = encode_day (ICal.RecurrenceWeekday.SUNDAY_WEEKDAY, 0);
                    array.append_val (day);
                }

                if (mon_button.active == true) {
                    short day = encode_day (ICal.RecurrenceWeekday.MONDAY_WEEKDAY, 0);
                    array.append_val (day);
                }

                if (tue_button.active == true) {
                    short day = encode_day (ICal.RecurrenceWeekday.TUESDAY_WEEKDAY, 0);
                    array.append_val (day);
                }

                if (wed_button.active == true) {
                    short day = encode_day (ICal.RecurrenceWeekday.WEDNESDAY_WEEKDAY, 0);
                    array.append_val (day);
                }

                if (thu_button.active == true) {
                    short day = encode_day (ICal.RecurrenceWeekday.THURSDAY_WEEKDAY, 0);
                    array.append_val (day);
                }

                if (fri_button.active == true) {
                    short day = encode_day (ICal.RecurrenceWeekday.FRIDAY_WEEKDAY, 0);
                    array.append_val (day);
                }

                if (sat_button.active == true) {
                    short day = encode_day (ICal.RecurrenceWeekday.SATURDAY_WEEKDAY, 0);
                    array.append_val (day);
                }

                rrule.set_by_day_array (array);
                break;
            case 2:
                rrule.set_freq (ICal.RecurrenceFrequency.MONTHLY_RECURRENCE);
                if (every_radiobutton.active == true) {
                    var array = new GLib.Array<short>.sized (false, false, sizeof (short), 1);
                    ICal.RecurrenceWeekday weekday;
                    switch (parent_dialog.date_time.get_day_of_week ()) {
                        case 2:
                            weekday = ICal.RecurrenceWeekday.TUESDAY_WEEKDAY;
                            break;
                        case 3:
                            weekday = ICal.RecurrenceWeekday.WEDNESDAY_WEEKDAY;
                            break;
                        case 4:
                            weekday = ICal.RecurrenceWeekday.THURSDAY_WEEKDAY;
                            break;
                        case 5:
                            weekday = ICal.RecurrenceWeekday.FRIDAY_WEEKDAY;
                            break;
                        case 6:
                            weekday = ICal.RecurrenceWeekday.SATURDAY_WEEKDAY;
                            break;
                        case 7:
                            weekday = ICal.RecurrenceWeekday.SUNDAY_WEEKDAY;
                            break;
                        default:
                            weekday = ICal.RecurrenceWeekday.MONDAY_WEEKDAY;
                            break;
                    }

                    short day = encode_day (weekday, (int) Math.ceil ((double)parent_dialog.date_time.get_day_of_month () / (double)7));
                    array.append_val (day);
                    rrule.set_by_day_array (array);
                } else {
                    var array = new GLib.Array<short>.sized (false, false, sizeof (short), 1);
                    var day_of_month = (short)parent_dialog.date_time.get_day_of_month ();
                    array.append_val (day_of_month);
                    rrule.set_by_month_day_array (array);
                }
                break;
            case 3:
                rrule.set_freq (ICal.RecurrenceFrequency.YEARLY_RECURRENCE);
                break;
            default:
                rrule.set_freq (ICal.RecurrenceFrequency.DAILY_RECURRENCE);
                break;
        }
        if (ends_combobox.active == 2) {
            rrule.set_count ((int)repeats_spinbutton.value);
        } else if (ends_combobox.active == 1) {
            rrule.set_until (new ICal.Time.from_day_of_year (end_datepicker.date.get_day_of_year (), end_datepicker.date.get_year ()));
        }

        rrule.set_interval ((short)every_entry.value);
        property.set_rrule (rrule);
        comp.add_property (property);

        // Save exceptions
        count = comp.count_properties (ICal.PropertyKind.EXDATE_PROPERTY);
        for (int i = 0; i < count; i++) {
            remove_prop = comp.get_first_property (ICal.PropertyKind.EXDATE_PROPERTY);
            comp.remove_property (remove_prop);
        }

        for (int i = 0; exceptions_list.get_row_at_index (i) != null; i++) {
            var exgrid = (ExceptionGrid) exceptions_list.get_row_at_index (i);
            var date = exgrid.get_date ();
            var exdate = new ICal.Property (ICal.PropertyKind.EXDATE_PROPERTY);
            exdate.set_exdate (Calendar.Util.datetimes_to_icaltime (date, null));
            comp.add_property (exdate);
        }
    }
}

public class Maya.View.EventEdition.ExceptionGrid : Gtk.ListBoxRow {
    private Granite.DatePicker date;

    public ExceptionGrid (GLib.DateTime dt) {
        date = new Granite.DatePicker () {
            date = dt,
            hexpand = true
        };

        var remove_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic") {
            has_frame = false
        };

        var box = new Gtk.Box (HORIZONTAL, 12);
        box.append (date);
        box.append (remove_button);

        margin_top = 12;
        margin_start = 12;
        margin_end = 12;
        margin_bottom = 12;
        child = box;

        remove_button.clicked.connect (() => {
            hide ();
            destroy ();
        });
    }

    public GLib.DateTime get_date () {
        return date.date;
    }
}
