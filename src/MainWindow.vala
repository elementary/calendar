// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2018 elementary, Inc. (https://elementary.io)
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
 * Authored by: Maxwell Barvian <maxwell@elementary.io>
 *              Corentin Noël <corentin@elementary.io>
 */

public class Maya.MainWindow : Gtk.ApplicationWindow {
    public View.CalendarView calview;

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_NEW_EVENT = "action_new_event";
    public const string ACTION_SHOW_TODAY = "action_show_today";

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_NEW_EVENT, action_new_event },
        { ACTION_SHOW_TODAY, action_show_today }
    };

    private uint configure_id;
    private static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            height_request: 400,
            icon_name: "office-calendar",
            width_request: 625
        );
    }

    static construct {
        action_accelerators[ACTION_NEW_EVENT] = "<Control>n";
        action_accelerators[ACTION_SHOW_TODAY] = "<Control>t";
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);

        foreach (var action in action_accelerators.get_keys ()) {
            ((Gtk.Application) GLib.Application.get_default ()).set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
        }

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/io/elementary/calendar");

        var headerbar = new View.HeaderBar ();

        var infobar_label = new Gtk.Label (null);
        infobar_label.show ();

        var infobar = new Gtk.InfoBar ();
        infobar.message_type = Gtk.MessageType.ERROR;
        infobar.no_show_all = true;
        infobar.show_close_button = true;
        infobar.get_content_area ().add (infobar_label);

        var sidebar = new View.AgendaView ();
        sidebar.no_show_all = true;
        sidebar.width_request = 160;
        sidebar.show ();

        calview = new View.CalendarView ();
        calview.vexpand = true;

        var hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        hpaned.pack1 (calview, true, false);
        hpaned.pack2 (sidebar, true, false);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (infobar);
        grid.add (hpaned);

        add (grid);
        set_titlebar (headerbar);

        calview.on_event_add.connect ((date) => on_tb_add_clicked (date));
        calview.selection_changed.connect ((date) => sidebar.set_selected_date (date));

        infobar.response.connect ((id) => infobar.hide ());

        sidebar.event_removed.connect (on_remove);

        Maya.Application.saved_state.bind ("hpaned-position", hpaned, "position", GLib.SettingsBindFlags.DEFAULT);

        Model.CalendarModel.get_default ().error_received.connect ((message) => {
            Idle.add (() => {
                infobar_label.label = message;
                infobar.show ();
                return false;
            });
        });
    }

    public void on_tb_add_clicked (DateTime dt) {
        var dialog = new Maya.View.EventDialog (null, dt);
        dialog.transient_for = this;
        dialog.show_all ();
    }

    private void action_new_event () {
        on_tb_add_clicked (calview.selected_date);
    }

    private void action_show_today () {
        calview.today ();
    }

    private void on_remove (ECal.Component comp) {
        Model.CalendarModel.get_default ().remove_event (comp.get_data<E.Source> ("source"), comp, ECal.ObjModType.THIS);
    }

    public void on_modified (ECal.Component comp) {
        E.Source src = comp.get_data ("source");

        if (src.writable == true && Model.CalendarModel.get_default ().calclient_is_readonly (src) == false) {
            var dialog = new Maya.View.EventDialog (comp, null);
            dialog.transient_for = this;
            dialog.present ();
        } else {
            Gdk.beep ();
        }
    }

    public void on_duplicate (ECal.Component comp) {
        E.Source src = comp.get_data ("source");

        if (src.writable == true && Model.CalendarModel.get_default ().calclient_is_readonly (src) == false) {
            // The event editor dialog (EventDialog) uses its date/time parameter to tell
            // if we're editing an existing event (parameter is null) or creating a new one
            // (parameter is not null). Since here we're creating a new event as a copy of
            // an existing one, we have to pass that event's date/time.
            DateTime from_date, _;
            Util.get_local_datetimes_from_icalcomponent (comp.get_icalcomponent (), out from_date, out _);

            // Now open the editor dialog.
            var dialog = new Maya.View.EventDialog (comp, from_date);
            dialog.transient_for = this;
            dialog.present ();
        } else {
            Gdk.beep ();
        }
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            GLib.Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;

            if (is_maximized) {
                Maya.Application.saved_state.set_boolean ("window-maximized", true);
            } else {
                Maya.Application.saved_state.set_boolean ("window-maximized", false);

                Gdk.Rectangle rect;
                get_allocation (out rect);
                Maya.Application.saved_state.set ("window-size", "(ii)", rect.width, rect.height);

                int root_x, root_y;
                get_position (out root_x, out root_y);
                Maya.Application.saved_state.set ("window-position", "(ii)", root_x, root_y);
            }

            return GLib.Source.REMOVE;
        });

        return base.configure_event (event);
    }
}
