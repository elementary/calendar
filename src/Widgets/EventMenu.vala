/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2026 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Maxwell Barvian
 *              Corentin Noël <corentin@elementaryos.org>
 */

namespace Maya.EventMenu {
    public static Gtk.PopoverMenu build (ECal.Component comp) {
        var action_edit = new GLib.SimpleAction ("edit", null);
        action_edit.activate.connect (() => {
            ((Maya.Application) GLib.Application.get_default ()).window.on_modified (comp);
        });

        var action_duplicate = new GLib.SimpleAction ("duplicate", null);
        action_duplicate.activate.connect (() => {
            ((Maya.Application) GLib.Application.get_default ()).window.on_duplicated (comp);
        });

        var action_remove = new GLib.SimpleAction ("remove", null);
        action_remove.activate.connect (() => remove_event (comp));

        var action_add_exception = new GLib.SimpleAction ("add-exception", null);
        action_add_exception.activate.connect (() => add_exception (comp));

        var action_group = new SimpleActionGroup ();
        action_group.add_action (action_edit);
        action_group.add_action (action_duplicate);
        action_group.add_action (action_remove);
        action_group.add_action (action_add_exception);

        var menu_model = new GLib.Menu ();
        menu_model.append (_("Edit…"), "event.edit");
        menu_model.append (_("Duplicate…"), "event.duplicate");

        if (comp.has_recurrences ()) {
            menu_model.prepend (_("Remove Event"), "event.remove");
            menu_model.insert (1, _("Remove Occurrence"), "event.add-exception");
        } else {
            menu_model.prepend (_("Remove"), "event.remove");
        }

        var menu = new Gtk.PopoverMenu.from_model (menu_model) {
            has_arrow = false
        };
        menu.insert_action_group ("event", action_group);

        E.Source src = comp.get_data ("source");

        var sensitive = src.writable && !Calendar.EventStore.get_default ().calclient_is_readonly (src);
        action_edit.set_enabled (sensitive);
        action_duplicate.set_enabled (sensitive);
        action_remove.set_enabled (sensitive);
        action_add_exception.set_enabled (sensitive);

        return menu;
    }

    private static void popup_at_pointer (Gtk.PopoverMenu popover, double x, double y) {
        var rect = Gdk.Rectangle () {
            x = (int) x,
            y = (int) y
        };
        popover.pointing_to = rect;
        popover.popup ();
    }

    private static void remove_event (ECal.Component comp) {
        var application = (Gtk.Application) GLib.Application.get_default ();
        var source = comp.get_data<E.Source> ("source");
        var delete_dialog = new Calendar.DeleteEventDialog (source, comp, ECal.ObjModType.ALL) {
            transient_for = application.active_window
        };
        delete_dialog.present ();
    }

    private static void add_exception (ECal.Component comp) {
        var application = (Gtk.Application) GLib.Application.get_default ();
        var source = comp.get_data<E.Source> ("source");
        var delete_dialog = new Calendar.DeleteEventDialog (source, comp, ECal.ObjModType.THIS) {
            transient_for = application.active_window
        };
        delete_dialog.present ();
    }
}
