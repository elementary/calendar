/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Christian Dywan <christian@twotoasts.de>
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.VAutoHider : Granite.Bin {
    private List<unowned Gtk.Widget> children;
    private Gtk.Label more_label;
    private Gtk.Box main_box;

    construct {
        children = new List<unowned Gtk.Widget> ();

        more_label = new Gtk.Label ("") {
            valign = END
        };

        main_box = new Gtk.Box (VERTICAL, 0);
        main_box.append (more_label);

        child = main_box;
    }

    public void add (Gtk.Widget widget) {
        children.append (widget);
        main_box.append (widget);

        update (widget);

        widget.destroy.connect (() => {
            queue_resize ();
        });

        queue_resize ();
    }

    public void update (Gtk.Widget widget) {
        children.sort (compare_children);

        while (main_box.get_first_child () != null) {
            main_box.remove (main_box.get_first_child ());
        }

        foreach (var child in children) {
            main_box.append (child);
        }
    }

    public override void size_allocate (int width, int height, int baseline) {
        base.size_allocate (width, height, baseline);

        if (children.length () == 0) {
            more_label.hide ();
            return;
        }

        more_label.show ();
        more_label.vexpand = false;
        var more_label_height = more_label.get_height ();
        more_label.hide ();

        int shown_children = 0;
        int shown_children_height = 0;
        foreach (var child in children) {
            if (child == more_label) {
                continue;
            }

            child.show ();
            var child_height = child.get_height ();

            if (shown_children_height + child_height > get_height () - more_label_height) {
                var last = shown_children == children.length () - 1;
                if (!last || shown_children_height + child_height > get_height ()) {
                    ((Maya.View.EventButton) child).hide_without_animate ();
                    continue;
                }
            }

            ((Maya.View.EventButton) child).show_without_animate ();
            shown_children++;
            shown_children_height += child_height;
        }

        var hidden_children = children.length () - shown_children;
        if (hidden_children > 0) {
            more_label.show ();
            more_label.label = _("%u more…").printf (hidden_children);
            more_label.vexpand = true;
        }
    }

    public override void measure (Gtk.Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
        base.measure (orientation, for_size, out minimum, out natural, out minimum_baseline, out natural_baseline);

        for_size = more_label.get_width ();

        minimum = more_label.get_height ();
        if (minimum > natural) {
            natural = minimum;
        }
    }

    public static GLib.CompareFunc<weak Gtk.Widget> compare_children = (a, b) => {
        EventButton a2 = a as EventButton;
        EventButton b2 = b as EventButton;

        if (a2 == null) {
            return 1;
        } else if (b2 == null) {
            return 0;
        } else {
            return Util.compare_events (a2.comp, b2.comp);
        }
    };
}
