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

        more_label = new Gtk.Label (" ") {
            valign = END
        };

        main_box = new Gtk.Box (VERTICAL, 0);
        main_box.append (more_label);

        set_layout_manager (new Gtk.CustomLayout (null, layout_measure, layout_allocate));
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

        main_box.append (more_label);
        foreach (var child in children) {
            main_box.append (child);
        }
    }

    private static void layout_allocate (Gtk.Widget widget, int width, int height, int baseline) {
        var self = (VAutoHider) widget;

        if (self.children.length () == 0) {
            self.more_label.hide ();
            self.main_box.allocate (width, height, baseline, null);
            return;
        }

        self.more_label.label = _("%u more…").printf (self.children.length ());
        int more_label_minimum;
        int more_label_height;
        int more_label_minimum_baseline;
        int more_label_natural_baseline;
        self.more_label.measure (
            VERTICAL,
            width,
            out more_label_minimum,
            out more_label_height,
            out more_label_minimum_baseline,
            out more_label_natural_baseline
        );

        int shown_children = 0;
        int shown_children_height = 0;

        foreach (var child in self.children) {
            var event_button = (Maya.View.EventButton) child;
            event_button.show_without_animate ();

            int child_minimum;
            int child_height;
            int child_minimum_baseline;
            int child_natural_baseline;
            child.measure (
                VERTICAL,
                width,
                out child_minimum,
                out child_height,
                out child_minimum_baseline,
                out child_natural_baseline
            );

            if (shown_children_height + child_height > height - more_label_height) {
                var last = shown_children == self.children.length () - 1;

                if (!last || shown_children_height + child_height > height) {
                    event_button.hide_without_animate ();
                    continue;
                }
            }

            shown_children++;
            shown_children_height += child_height;
        }

        var hidden_children = self.children.length () - shown_children;

        if (hidden_children > 0) {
            self.more_label.label = _("%u more…").printf (hidden_children);
            self.more_label.show ();
            self.more_label.vexpand = true;
        } else {
            self.more_label.hide ();
            self.more_label.vexpand = false;
        }

        self.main_box.allocate (width, height, baseline, null);
    }

    private static void layout_measure (
        Gtk.Widget widget,
        Gtk.Orientation orientation,
        int for_size,
        out int minimum,
        out int natural,
        out int minimum_baseline,
        out int natural_baseline
    ) {
        var self = (VAutoHider) widget;

        if (orientation == VERTICAL) {
            if (self.children.length () == 0) {
                minimum = 0;
                natural = 0;
                minimum_baseline = -1;
                natural_baseline = -1;
                return;
            }

            self.more_label.measure (
                orientation,
                for_size,
                out minimum,
                out natural,
                out minimum_baseline,
                out natural_baseline
            );
        } else {
            self.main_box.measure (
                orientation,
                for_size,
                out minimum,
                out natural,
                out minimum_baseline,
                out natural_baseline
            );
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
