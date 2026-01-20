// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
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

    public Gtk.SearchEntry search_bar;
    private Calendar.Widgets.DateSwitcher month_switcher;
    private Calendar.Widgets.DateSwitcher year_switcher;

    public Adw.HeaderBar header_bar { get; private set; }
    public DateTime? selected_date { get; private set; }

    private Gtk.EventControllerScroll scroll_controller;
    private WeekLabels weeks { get; private set; }
    private Header header { get; private set; }
    private Grid days_grid { get; private set; }
    private Gtk.Stack stack { get; private set; }
    private Gtk.Label spacer { get; private set; }
    private static GLib.Settings show_weeks;

    static construct {
        if (Application.wingpanel_settings != null) {
            show_weeks = Application.wingpanel_settings;
        } else {
            show_weeks = Application.saved_state;
        }
    }

    construct {
        var export_action = new SimpleAction ("export", null);
        export_action.activate.connect (action_export);

        var action_group = new SimpleActionGroup ();
        action_group.add_action (export_action);

        var contractor_menu = new GLib.Menu ();

        try {
            var contracts = Granite.Services.ContractorProxy.get_contracts_by_mime ("text/calender");

            int i = 0;
            foreach (var contract in contracts) {
                var contract_action = new SimpleAction ("contract-%i".printf (i), null);
                contract_action.activate.connect (() => {
                    /* creates a .ics file */
                    Util.save_temp_selected_calendars ();

                    var file_path = GLib.Environment.get_tmp_dir () + "/calendar.ics";
                    var cal_file = File.new_for_path (file_path);

                    try {
                        contract.execute_with_file (cal_file);
                    } catch (Error err) {
                        warning (err.message);
                    }
                });

                action_group.add_action (contract_action);

                contractor_menu.append (
                    contract.get_display_name (),
                    ACTION_PREFIX + "contract-%i".printf (i)
                );
                i++;
            }
        } catch (GLib.Error error) {
            critical (error.message);
        }

        contractor_menu.append (
            _("Export Calendar…"),
            "calendar.export"
        );

        insert_action_group (ACTION_GROUP_PREFIX, action_group);

        selected_date = Maya.Application.get_selected_datetime ();

        var error_label = new Gtk.Label (null);
        error_label.show ();

        var error_bar = new Gtk.InfoBar () {
            message_type = Gtk.MessageType.ERROR,
            revealed = false,
            show_close_button = true
        };
        error_bar.get_content_area ().add (error_label);

        var info_bar = new Calendar.Widgets.ConnectivityInfoBar ();

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
        set_switcher_date (calmodel.month_start);

        var spinner = new Maya.View.Widgets.DynamicSpinner ();

        var contractor = new Gtk.MenuButton () {
            image = new Gtk.Image.from_icon_name ("document-export", LARGE_TOOLBAR),
            popup = new Gtk.Menu.from_model (contractor_menu),
            tooltip_text = _("Export or Share the default Calendar")
        };

        var source_popover = new Calendar.Widgets.SourcePopover ();

        var menu_button = new Gtk.MenuButton () {
            icon_name = "open-menu",
            popover = source_popover,
            tooltip_text = _("Manage Calendars")
        };

        header_bar = new Adw.HeaderBar () {
            show_close_button = true
        };
        header_bar.pack_start (month_switcher);
        header_bar.pack_start (year_switcher);
        header_bar.pack_start (button_today);
        header_bar.pack_end (menu_button);
        header_bar.pack_end (contractor);
        header_bar.pack_end (spinner);

        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);

        stack = new Gtk.Stack ();
        stack.expand = true;

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

        show_weeks.changed["show-weeks"].connect (on_show_weeks_changed);
        show_weeks.get_value ("show-weeks");

        orientation = VERTICAL;
        add_css_class (Granite.STYLE_CLASS_VIEW);
        append (header_bar);
        append (error_bar);
        append (info_bar);
        append (stack);

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
        calmodel.parameters_changed.connect (() => {
            set_switcher_date (calmodel.month_start);
        });

        scroll_controller = new Gtk.EventControllerScroll (this, Gtk.EventControllerScrollFlags.BOTH_AXES);
        scroll_controller.scroll.connect (GesturesUtils.on_scroll);
    }

    private void action_export () {
        /* creates a .ics file */
        Util.save_temp_selected_calendars ();

        var filter = new Gtk.FileFilter ();
        filter.add_mime_type ("text/calendar");

        var filechooser = new Gtk.FileChooserNative (
            _("Export Calendar…"),
            null,
            Gtk.FileChooserAction.SAVE,
            _("Save"),
            _("Cancel")
        );
        filechooser.do_overwrite_confirmation = true;
        filechooser.filter = filter;
        filechooser.set_current_name (_("calendar.ics"));

        if (filechooser.run () == Gtk.ResponseType.ACCEPT) {
            var destination = filechooser.get_filename ();
            if (destination == null) {
                destination = filechooser.get_current_folder ();
            } else if (!destination.has_suffix (".ics")) {
                destination += ".ics";
            }
            try {
                GLib.Process.spawn_command_line_async ("mv " + GLib.Environment.get_tmp_dir () + "/calendar.ics " + destination);
            } catch (SpawnError e) {
                warning (e.message);
            }
        }

        filechooser.destroy ();
    }

    private void set_switcher_date (DateTime date) {
        month_switcher.text = date.format ("%OB");
        year_switcher.text = date.format ("%Y");
    }

    //--- Public Methods ---//

    public void today () {
        var today = Calendar.Util.datetime_strip_time (new DateTime.now_local ());
        var calmodel = Calendar.EventStore.get_default ();
        var start = Calendar.Util.datetime_get_start_of_month (today);
        if (!start.equal (calmodel.month_start))
            calmodel.month_start = start;
        sync_with_model ();
        days_grid.focus_date (today);
    }

    //--- Signal Handlers ---//

    void on_show_weeks_changed () {
        var model = Calendar.EventStore.get_default ();
        weeks.update (model.data_range.first_dt, model.num_weeks);
        update_spacer_visible ();
    }

    private void update_spacer_visible () {
        if (show_weeks.get_boolean ("show-weeks")) {
            spacer.show ();
        } else {
            spacer.hide ();
        }
    }

    void on_events_added (E.Source source, Gee.Collection<ECal.Component> events) {
        Idle.add ( () => {
            foreach (var event in events) {
                add_event (source, event);
            }

            return false;
        });
    }

    void on_events_updated (E.Source source, Gee.Collection<ECal.Component> events) {
        Idle.add ( () => {
            foreach (var event in events) {
                update_event (source, event);
            }

            return false;
        });
    }

    void on_events_removed (E.Source source, Gee.Collection<ECal.Component> events) {
        Idle.add ( () => {
            foreach (var event in events)
                remove_event (source, event);

            return false;
        });
    }

    /* Indicates the month has changed */
    void on_model_parameters_changed () {
        var model = Calendar.EventStore.get_default ();
        if (days_grid.grid_range != null && model.data_range.equals (days_grid.grid_range))
            return; // nothing to do

        Idle.add ( () => {
            remove_all_events ();
            sync_with_model ();
            return false;
        });
    }

    //--- Helper Methods ---//
    Gtk.Grid create_big_grid () {
        spacer = new Gtk.Label ("");
        spacer.no_show_all = true;
        spacer.get_style_context ().add_class ("weeks");

        weeks = new WeekLabels ();

        header = new Header ();
        days_grid = new Grid ();
        days_grid.focus_date (selected_date);
        days_grid.on_event_add.connect ((date) => on_event_add (date));
        days_grid.selection_changed.connect ((date) => {
            selected_date = date;
            selection_changed (date);
        });

        // Grid properties
        var new_big_grid = new Gtk.Grid ();
        new_big_grid.attach (spacer, 0, 0, 1, 1);
        new_big_grid.attach (header, 1, 0, 1, 1);
        new_big_grid.attach (days_grid, 1, 1, 1, 1);
        new_big_grid.attach (weeks, 0, 1, 1, 1);
        new_big_grid.expand = true;

        update_spacer_visible ();

        return new_big_grid;
    }

    /* Sets the calendar widgets to the date range of the model */
    void sync_with_model () {
        var model = Calendar.EventStore.get_default ();
        DateTime previous_first = null;
        if (days_grid != null) {
            if (days_grid.grid_range != null && (model.data_range.equals (days_grid.grid_range) || days_grid.grid_range.first_dt.compare (model.data_range.first_dt) == 0))
                return; // nothing to do
            if (days_grid.grid_range != null)
                previous_first = days_grid.grid_range.first_dt;
        }

        var big_grid = create_big_grid ();
        stack.add (big_grid);

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
                stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
            } else {
                stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;
            }
        }

        stack.set_visible_child (big_grid);
    }

    /* Render new event on the grid */
    void add_event (E.Source source, ECal.Component event) {
        /* The "source" data is added to events by the Calendar.EventStore. The grid must only show events that have
           been added to the model first */
        assert (event.get_data<E.Source> ("source") != null);
        days_grid.add_event (event);
    }

    /* Update the event on the grid */
    void update_event (E.Source source, ECal.Component event) {
        days_grid.update_event (event);
    }

    /* Remove event from the grid */
    void remove_event (E.Source source, ECal.Component event) {
        days_grid.remove_event (event);
    }

    /* Remove all events from the grid */
    void remove_all_events () {
        days_grid.remove_all_events ();
    }
}
