/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2026 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Maxwell Barvian
 *              Corentin Noël <corentin@elementaryos.org>
 */

/**
 * Represents the entire calendar, including the headers, the week labels and the grid.
 */
public class Maya.View.CalendarView : Gtk.Box {
    /*
     * Event emitted when the day is double clicked or the ENTER key is pressed.
     */
    public signal void on_event_add (DateTime date);
    public signal void selection_changed (DateTime new_date);

    private const string ACTION_GROUP_PREFIX = "calendar";
    private const string ACTION_PREFIX = ACTION_GROUP_PREFIX + ".";

    public DateTime? selected_date { get; private set; }
    public Gtk.SearchEntry search_bar { get; private set; }
    public Adw.HeaderBar header_bar { get; private set; }

    private Calendar.Widgets.DateSwitcher month_switcher;
    private Calendar.Widgets.DateSwitcher year_switcher;
    private Grid days_grid;
    private Gtk.Stack stack;
    private WeekLabels weeks;

    private static GLib.Settings settings;

    static construct {
        if (Application.wingpanel_settings != null) {
            settings = Application.wingpanel_settings;
        } else {
            settings = Application.saved_state;
        }
    }

    construct {
        var export_action = new SimpleAction ("export", null);
        export_action.activate.connect (action_export);

        var action_group = new SimpleActionGroup ();
        action_group.add_action (export_action);

        insert_action_group (ACTION_GROUP_PREFIX, action_group);

        selected_date = Maya.Application.get_selected_datetime ();

        var error_label = new Gtk.Label (null);

        var error_bar = new Gtk.InfoBar () {
            message_type = Gtk.MessageType.ERROR,
            revealed = false,
            show_close_button = true
        };
        error_bar.add_child (error_label);

        var info_label = new Gtk.Label ("<b>%s</b> %s".printf (
            _("Network Not Available."),
            _("Connect to the Internet to see additional details and new events from online calendars.")
        )) {
            use_markup = true,
            wrap = true
        };

        var info_bar = new Gtk.InfoBar () {
            message_type = WARNING,
            revealed = false
        };
        info_bar.add_child (info_label);
        info_bar.add_button (_("Network Settings…"), Gtk.ResponseType.ACCEPT);

        var application_instance = ((Gtk.Application) GLib.Application.get_default ());

        var button_today = new Gtk.Button.from_icon_name ("calendar-go-today") {
            action_name = Maya.MainWindow.ACTION_PREFIX + Maya.MainWindow.ACTION_SHOW_TODAY
        };
        button_today.tooltip_markup = Granite.markup_accel_tooltip (
            application_instance.get_accels_for_action (button_today.action_name),
            _("Go to today's date")
        );

        month_switcher = new Calendar.Widgets.DateSwitcher (10) {
            valign = CENTER
        };
        year_switcher = new Calendar.Widgets.DateSwitcher (-1) {
            valign = CENTER
        };

        var calmodel = Calendar.EventStore.get_default ();

        var spinner = new Maya.View.Widgets.DynamicSpinner ();

        var source_popover = new Calendar.Widgets.SourcePopover ();

        var menu_button = new Gtk.MenuButton () {
            icon_name = "open-menu",
            popover = source_popover,
            tooltip_text = _("Manage Calendars")
        };

        header_bar = new Adw.HeaderBar () {
            show_start_title_buttons = true
        };
        header_bar.pack_start (month_switcher);
        header_bar.pack_start (year_switcher);
        header_bar.pack_start (button_today);
        header_bar.pack_end (menu_button);
        header_bar.pack_end (spinner);

        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);

        stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true
        };

        sync_with_model (); // Populate stack with a grid

        var model = Calendar.EventStore.get_default ();
        model.parameters_changed.connect (on_model_parameters_changed);

        model.events_added.connect (on_events_added);
        model.events_updated.connect (on_events_updated);
        model.events_removed.connect (on_events_removed);

        stack.notify["transition-running"].connect (() => {
            if (stack.transition_running == false) {
                stack.get_children ().foreach ((child) => {
                    if (child != stack.visible_child) {
                        child.destroy ();
                    }
                });
            }
        });

        settings.changed["show-weeks"].connect (on_show_weeks_changed);
        settings.get_value ("show-weeks");

        orientation = VERTICAL;
        add_css_class (Granite.STYLE_CLASS_VIEW);
        append (header_bar);
        append (error_bar);
        append (info_bar);
        append (stack);

        var network_monitor = GLib.NetworkMonitor.get_default ();
        network_monitor.network_changed.connect (() => {
            info_bar.revealed = !(
                network_monitor.get_network_available () &&
                network_monitor.get_connectivity () == FULL
            );
        });

        info_bar.response.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("settings://network", null);
            } catch (GLib.Error e) {
                critical (e.message);
            }
        });

        error_bar.response.connect ((id) => error_bar.set_revealed (false));

        Calendar.EventStore.get_default ().error_received.connect ((message) => {
            Idle.add (() => {
                error_label.label = message;
                error_bar.set_revealed (true);
                return false;
            });
        });

        month_switcher.left_clicked.connect (() => Calendar.EventStore.get_default ().change_month (-1));
        month_switcher.right_clicked.connect (() => Calendar.EventStore.get_default ().change_month (1));
        year_switcher.left_clicked.connect (() => Calendar.EventStore.get_default ().change_year (-1));
        year_switcher.right_clicked.connect (() => Calendar.EventStore.get_default ().change_year (1));

        set_switcher_date (calmodel.month_start);
        calmodel.parameters_changed.connect (() => {
            set_switcher_date (calmodel.month_start);
        });

        var scroll_controller = new Gtk.EventControllerScroll (Gtk.EventControllerScrollFlags.BOTH_AXES);
        scroll_controller.scroll.connect (GesturesUtils.on_scroll);

        add_controller (scroll_controller);
    }

    private void action_export () {
        var filter = new Gtk.FileFilter ();
        filter.add_mime_type ("text/calendar");

        var file_dialog = new Gtk.FileDialog () {
            title = _("Export Calendar…"),
            accept_label = _("Save"),
            default_filter = filter,
            initial_name = _("calendar.ics")
        };

        file_dialog.save.begin (window, null, (obj, res) => {
            try {
                var events = Calendar.EventStore.get_default ().get_events ();
                var builder = new StringBuilder ();
                builder.append ("BEGIN:VCALENDAR\n");
                builder.append ("VERSION:2.0\n");
                foreach (ECal.Component event in events) {
                    builder.append (event.get_as_string ());
                }
                builder.append ("END:VCALENDAR");

                var file = file_dialog.save.end (res);
                file.replace_contents (builder.data, null, false, FileCreateFlags.REPLACE_DESTINATION, null);
            } catch (Error e) {
                if (e.matches (Gtk.DialogError.quark (), Gtk.DialogError.DISMISSED)) {
                    return;
                }

                critical (e.message);
            }
        });
    }

    private void set_switcher_date (DateTime date) {
        month_switcher.text = date.format ("%OB");
        year_switcher.text = date.format ("%Y");
    }

    public void today () {
        var today = Calendar.Util.datetime_strip_time (new DateTime.now_local ());
        var calmodel = Calendar.EventStore.get_default ();
        var start = Calendar.Util.datetime_get_start_of_month (today);
        if (!start.equal (calmodel.month_start)) {
            calmodel.month_start = start;
        }

        sync_with_model ();
        days_grid.focus_date (today);
    }

    private void on_show_weeks_changed () {
        var model = Calendar.EventStore.get_default ();
        weeks.update (model.data_range.first_dt, model.num_weeks);
    }

    private void on_events_added (E.Source source, Gee.Collection<ECal.Component> events) {
        Idle.add ( () => {
            foreach (var event in events) {
                add_event (source, event);
            }

            return false;
        });
    }

    private void on_events_updated (E.Source source, Gee.Collection<ECal.Component> events) {
        Idle.add ( () => {
            foreach (var event in events) {
                update_event (source, event);
            }

            return false;
        });
    }

    private void on_events_removed (E.Source source, Gee.Collection<ECal.Component> events) {
        Idle.add ( () => {
            foreach (var event in events)
                remove_event (source, event);

            return false;
        });
    }

    /* Indicates the month has changed */
    private void on_model_parameters_changed () {
        var model = Calendar.EventStore.get_default ();
        if (days_grid.grid_range != null && model.data_range.equals (days_grid.grid_range))
            return; // nothing to do

        Idle.add ( () => {
            remove_all_events ();
            sync_with_model ();
            return false;
        });
    }

    /* Sets the calendar widgets to the date range of the model */
    private void sync_with_model () {
        var model = Calendar.EventStore.get_default ();
        DateTime previous_first = null;
        if (days_grid != null) {
            if (days_grid.grid_range != null && (model.data_range.equals (days_grid.grid_range) || days_grid.grid_range.first_dt.compare (model.data_range.first_dt) == 0)) {
                return; // nothing to do
            }

            if (days_grid.grid_range != null) {
                previous_first = days_grid.grid_range.first_dt;
            }
        }

        var spacer = new Gtk.Label ("");
        spacer.add_css_class ("weeks");

        var spacer_revealer = new Gtk.Revealer () {
            child = spacer,
            transition_type = CROSSFADE
        };

        weeks = new WeekLabels ();

        var header = new Header ();

        days_grid = new Grid ();
        days_grid.focus_date (selected_date);
        days_grid.on_event_add.connect ((date) => on_event_add (date));
        days_grid.selection_changed.connect ((date) => {
            selected_date = date;
            selection_changed (date);
        });

        var big_grid = new Gtk.Grid () {
            hexpand = true,
            vexpand = true
        };
        big_grid.attach (spacer_revealer, 0, 0);
        big_grid.attach (header, 1, 0);
        big_grid.attach (days_grid, 1, 1);
        big_grid.attach (weeks, 0, 1);

        settings.bind ("show-weeks", spacer_revealer, "reveal-child", SettingsBindFlags.GET);

        stack.add_child (big_grid);

        header.update_columns (model.week_starts_on);
        weeks.update (model.data_range.first_dt, model.num_weeks);
        days_grid.set_range (model.data_range, model.month_start);

        // keep focus date on the same day of the month
        if (selected_date != null) {
            var bumpdate = model.month_start.add_days (selected_date.get_day_of_month () - 1);
            days_grid.focus_date (bumpdate);
        }

        if (previous_first != null) {
            if (previous_first.compare (days_grid.grid_range.first_dt) == -1) {
                stack.transition_type = SLIDE_LEFT;
            } else {
                stack.transition_type = SLIDE_RIGHT;
            }
        }

        stack.set_visible_child (big_grid);
    }

    /* Render new event on the grid */
    private void add_event (E.Source source, ECal.Component event) {
        /* The "source" data is added to events by the Calendar.EventStore. The grid must only show events that have
           been added to the model first */
        assert (event.get_data<E.Source> ("source") != null);
        days_grid.add_event (event);
    }

    /* Update the event on the grid */
    private void update_event (E.Source source, ECal.Component event) {
        days_grid.update_event (event);
    }

    /* Remove event from the grid */
    private void remove_event (E.Source source, ECal.Component event) {
        days_grid.remove_event (event);
    }

    /* Remove all events from the grid */
    private void remove_all_events () {
        days_grid.remove_all_events ();
    }
}
