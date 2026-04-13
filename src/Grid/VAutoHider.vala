/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Christian Dywan <christian@twotoasts.de>
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.VAutoHider : Gtk.Bin {
    private Gtk.Label more_label;
    private Gtk.ListBox list_box;
    private GLib.ListStore event_store;

    construct {
        more_label = new Gtk.Label ("") {
            valign = END
        };

        event_store = new GLib.ListStore (typeof (Gtk.Widget));
        event_store.append (more_label);

        var list_box = new Gtk.ListBox ();
        list_box.bind_model (event_store, create_widget_func);

        base.add (list_box);
    }

    public void append (EventButton event_button) {
        event_store.insert_sorted (event_button, compare_func);

        event_button.destroy.connect (() => {
            queue_resize ();
        });

        queue_resize ();
    }

    public void update (Gtk.Widget widget) {
        uint index = -1;
        if (event_store.find (widget, out index)) {
            event_store.remove (index);
        }

        event_store.insert_sorted (widget, compare_func);
    }

    public override void size_allocate (Gtk.Allocation allocation) {
        base.size_allocate (allocation);

        var children_length = event_store.n_items - 1;
        if (children_length == 0) {
            more_label.hide ();
            return;
        }

        int more_label_height;
        more_label.show ();
        more_label.vexpand = false;
        more_label.get_preferred_height (out more_label_height, null);
        more_label.hide ();

        int shown_children = 0;
        int shown_children_height = 0;
        for (int i = 0; i < event_store.n_items; i++) {
            var child = (Gtk.Widget) event_store.get_item (i);
            if (child == more_label) {
                continue;
            }

            int child_height;
            child.show ();
            child.get_preferred_height (out child_height, null);

            if (shown_children_height + child_height > allocation.height - more_label_height) {
                var last = shown_children == children_length - 1;
                if (!last || shown_children_height + child_height > allocation.height) {
                    ((Maya.View.EventButton) child).hide_without_animate ();
                    continue;
                }
            }

            ((Maya.View.EventButton) child).show_without_animate ();
            shown_children++;
            shown_children_height += child_height;
        }

        var hidden_children = children_length - shown_children;
        if (hidden_children > 0) {
            more_label.show ();
            more_label.label = _("%u more…").printf (hidden_children);
            more_label.vexpand = true;
        }
    }

    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        base.get_preferred_width (out minimum_width, out natural_width);
        more_label.get_preferred_width (out minimum_width, null);
        if (minimum_width > natural_width)
            natural_width = minimum_width;
    }

    public override void get_preferred_height (out int minimum_height, out int natural_height) {
        base.get_preferred_height (out minimum_height, out natural_height);
        more_label.get_preferred_height (out minimum_height, null);
        if (minimum_height > natural_height)
            natural_height = minimum_height;
    }

    private static int compare_func (Object obj1, Object obj2) {
        if (obj1 is Gtk.Label) {
            return 1;
        }

        if (obj2 is Gtk.Label) {
            return -1;
        }

        var button_1 = (EventButton) obj1;
        var button_2 = (EventButton) obj2;

        return Util.compare_events (button_1.comp, button_2.comp);
    }

    private static Gtk.Widget create_widget_func (Object obj) {
        return (Gtk.Widget) obj;
    }
}
