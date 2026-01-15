/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Maxwell Barvian
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.EventMenu : Gtk.Menu {
    public ECal.Component comp { get; construct set; }

    public EventMenu (ECal.Component comp) {
        Object (comp: comp);
    }

    construct {
        E.Source src = comp.get_data ("source");
        bool sensitive = src.writable == true && Calendar.EventStore.get_default ().calclient_is_readonly (src) == false;

        var action_edit = new GLib.SimpleAction ("edit", null);
        action_edit.set_enabled (sensitive);
        action_edit.activate.connect (() => {
            ((Maya.Application) GLib.Application.get_default ()).window.on_modified (comp);
        });

        var action_duplicate = new GLib.SimpleAction ("duplicate", null);
        action_duplicate.set_enabled (sensitive);
        action_duplicate.activate.connect (() => {
            ((Maya.Application) GLib.Application.get_default ()).window.on_duplicated (comp);
        });

        var action_remove = new GLib.SimpleAction ("remove", null);
        action_remove.set_enabled (sensitive);
        action_remove.activate.connect (remove_event);

        var action_add_exception = new GLib.SimpleAction ("add-exception", null);
        action_add_exception.set_enabled (sensitive);
        action_add_exception.activate.connect (add_exception);


        var action_group = new SimpleActionGroup ();
        action_group.add_action (action_edit);
        action_group.add_action (action_duplicate);
        action_group.add_action (action_remove);
        action_group.add_action (action_add_exception);

        insert_action_group ("event", action_group);

        var edit_item = new Gtk.MenuItem.with_label (_("Edit…")) {
            action_name = "event.edit"
        };

        var duplicate_item = new Gtk.MenuItem.with_label (_("Duplicate…")) {
            action_name = "event.duplicate"
        };

        Gtk.MenuItem remove_item;
        if (comp.has_recurrences ()) {
            remove_item = new Gtk.MenuItem.with_label (_("Remove Event")) {
                action_name = "event.remove"
            };

            var exception_item = new Gtk.MenuItem.with_label (_("Remove Occurrence")) {
                action_name = "event.add-exception"
            };

            append (exception_item);
        } else {
            remove_item = new Gtk.MenuItem.with_label (_("Remove")) {
                action_name = "event.remove"
            };
        }

        append (remove_item);
        append (edit_item);
        append (duplicate_item);

        show_all ();
    }

    private void remove_event () {
        var application = (Gtk.Application) GLib.Application.get_default ();
        var source = comp.get_data<E.Source> ("source");
        var delete_dialog = new Calendar.DeleteEventDialog (source, comp, ECal.ObjModType.ALL) {
            transient_for = application.active_window
        };
        delete_dialog.run_dialog ();
    }

    private void add_exception () {
        var application = (Gtk.Application) GLib.Application.get_default ();
        var source = comp.get_data<E.Source> ("source");
        var delete_dialog = new Calendar.DeleteEventDialog (source, comp, ECal.ObjModType.THIS) {
            transient_for = application.active_window
        };
        delete_dialog.run_dialog ();
    }
}
