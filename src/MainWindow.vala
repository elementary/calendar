// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2020 elementary, Inc. (https://elementary.io)
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

public class Maya.MainWindow : Hdy.ApplicationWindow {
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
            icon_name: "io.elementary.calendar",
            width_request: 625
        );
    }

    static construct {
        action_accelerators[ACTION_NEW_EVENT] = "<Control>n";
        action_accelerators[ACTION_SHOW_TODAY] = "<Control>t";
    }

    construct {
        Hdy.init ();
        add_action_entries (ACTION_ENTRIES, this);

        foreach (var action in action_accelerators.get_keys ()) {
            ((Gtk.Application) GLib.Application.get_default ()).set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
        }

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/io/elementary/calendar");

        var headerbar = new Calendar.Widgets.HeaderBar ();

        var error_label = new Gtk.Label (null);
        error_label.show ();

        var error_bar = new Gtk.InfoBar () {
            message_type = Gtk.MessageType.ERROR,
            revealed = false,
            show_close_button = true
        };
        error_bar.get_content_area ().add (error_label);

        var info_bar = new Calendar.Widgets.ConnectivityInfoBar ();

        var sidebar = new View.AgendaView () {
            no_show_all = true,
            width_request = 160
        };
        sidebar.show ();

        calview = new View.CalendarView () {
            vexpand = true
        };

        var hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        hpaned.pack1 (calview, true, false);
        hpaned.pack2 (sidebar, false, false);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (headerbar);
        grid.add (error_bar);
        grid.add (info_bar);
        grid.add (hpaned);

        add (grid);

        calview.on_event_add.connect ((date) => on_tb_add_clicked (date));
        calview.selection_changed.connect ((date) => sidebar.set_selected_date (date));
        error_bar.response.connect ((id) => error_bar.set_revealed (false));
        sidebar.event_removed.connect (on_remove);

        new Calendar.Settings ().window.bind_property (
            "hpaned", hpaned, "position",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );

        Calendar.EventStore.get_default ().error_received.connect ((message) => {
            Idle.add (() => {
                error_label.label = message;
                error_bar.set_revealed (true);
                return false;
            });
        });
    }

    public void on_tb_add_clicked (DateTime dt) {
        var dialog = new Maya.View.EventDialog (null, dt, this);
        dialog.show_all ();
    }

    private void action_new_event () {
        on_tb_add_clicked (calview.selected_date);
    }

    private void action_show_today () {
        calview.today ();
    }

    private void on_remove (ECal.Component comp) {
        Calendar.EventStore.get_default ().remove_event (comp.get_data<E.Source> ("source"), comp, ECal.ObjModType.THIS);
    }

    public void on_modified (ECal.Component comp) {
        E.Source src = comp.get_data ("source");

        if (src.writable == true && Calendar.EventStore.get_default ().calclient_is_readonly (src) == false) {
            var dialog = new Maya.View.EventDialog (comp, null, this);
            dialog.present ();
        } else {
            Gdk.beep ();
        }
    }

    public void on_duplicated (ECal.Component comp) {
        E.Source src = comp.get_data ("source");

        if (src.writable == true && Calendar.EventStore.get_default ().calclient_is_readonly (src) == false) {
            var dup_comp = Util.copy_ecal_component (comp);
            dup_comp.set_uid (Util.mangle_uid (comp.get_id ().get_uid ()));
            var dialog = new Maya.View.EventDialog (dup_comp, null, this);
            dialog.transient_for = this;

            dialog.present ();
        } else {
            Gdk.beep ();
        }
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            var window = new Calendar.Settings ().window;
            configure_id = 0;

            window.maximized = is_maximized;
            if (!is_maximized) {
                Gdk.Rectangle rect;
                int root_x, root_y;

                get_position (out root_x, out root_y);
                get_allocation (out rect);

                window.width = rect.width;
                window.height = rect.height;
                window.x = root_x;
                window.y = root_y;
            }

            return Source.REMOVE;
        });

        return base.configure_event (event);
    }
}
