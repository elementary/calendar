/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Christian Dywan <christian@twotoasts.de>
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.VAutoHider : Gtk.Bin {
    private Gtk.Label more_label;
    private Gtk.ListBox main_box;

    construct {
        more_label = new Gtk.Label ("") {
            valign = END
        };

        main_box = new Gtk.ListBox ();
        main_box.set_sort_func (sort_func);

        main_box.add (more_label);

        base.add (main_box);
    }

    public override void add (Gtk.Widget widget) {
        main_box.add (widget);
        main_box.invalidate_sort ();

        widget.destroy.connect (() => {
            queue_resize ();
        });

        queue_resize ();
    }

    public void update (Gtk.Widget widget) {
        main_box.invalidate_sort ();
    }

    public override void size_allocate (Gtk.Allocation allocation) {
        base.size_allocate (allocation);

        if (main_box.get_row_at_index (1) == null) {
            more_label.hide ();
            return;
        }

        int more_label_height;
        more_label.show ();
        more_label.vexpand = false;
        more_label.get_preferred_height (out more_label_height, null);
        more_label.hide ();

        int global_height = allocation.height;
        int height = 0;
        int shown_children = 0;
        for (int i = 0; main_box.get_row_at_index (i) != null; i++) {
            var child = main_box.get_row_at_index (i);

            if (((Gtk.ListBoxRow) child).get_child () == more_label) {
                continue;
            }

            int child_height;
            child.show ();
            child.get_preferred_height (out child_height, null);

            if (global_height - more_label_height < child_height + height) {
                child.hide ();
                continue;
            }

            ((Maya.View.EventButton) ((Gtk.ListBoxRow) child).get_child ()).show_without_animate ();
            height += child_height;
            shown_children++;
        }

        var children_length = (int) main_box.get_children ().length () - 1;
        var more = children_length - shown_children;
        if (more > 0) {
            more_label.show ();
            more_label.vexpand = true;
            more_label.label = _("%i more…").printf (more);
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

    private static int sort_func (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        if (row1.get_child () is Gtk.Label) {
            return 1;
        }

        if (row2.get_child () is Gtk.Label) {
            return -1;
        }

        var button_1 = (EventButton) row1.get_child ();
        var button_2 = (EventButton) row2.get_child ();

        return Util.compare_events (button_1.comp, button_2.comp);
    }
}
