/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
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
            icon_name: "io.elementary.calendar",
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

        calview = new View.CalendarView () {
            vexpand = true
        };

        var sidebar = new View.AgendaView () {
            width_request = 160
        };

        var hpaned = new Gtk.Paned (HORIZONTAL);
        hpaned.pack1 (calview, true, false);
        hpaned.pack2 (sidebar, false, false);

        child = hpaned;

        var header_group = new Adw.HeaderGroup ();
        header_group.add_header_bar (calview.header_bar);
        header_group.add_header_bar (sidebar.header_bar);

        var size_group = new Gtk.SizeGroup (VERTICAL);
        size_group.add_widget (calview.header_bar);
        size_group.add_widget (sidebar.header_bar);

        calview.on_event_add.connect ((date) => on_tb_add_clicked (date));
        calview.selection_changed.connect ((date) => sidebar.set_selected_date (date));
        sidebar.event_removed.connect (on_remove);

        Maya.Application.saved_state.bind ("hpaned-position", hpaned, "position", GLib.SettingsBindFlags.DEFAULT);
    }

    public void on_tb_add_clicked (DateTime dt) {
        var dialog = new Maya.View.EventDialog (null, dt, this);
        dialog.present ();
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

            var dialog = new Maya.View.EventDialog (dup_comp, null, this) {
                transient_for = this
            };
            dialog.present ();
        } else {
            Gdk.beep ();
        }
    }

    // public override bool delete_event (Gdk.EventAny event) {
    //     ((Application) application).ask_for_background.begin ((obj, res) => {
    //         unowned var app = (Application) obj;
    //         if (app.ask_for_background.end (res)) {
    //             hide ();
    //         } else {
    //             destroy ();
    //         }
    //     });

    //     return Gdk.EVENT_STOP;
    // }
}
