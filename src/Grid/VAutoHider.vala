/*
 Copyright (C) 2011 Christian Dywan <christian@twotoasts.de>

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 See the file COPYING for the full license text.
*/

namespace Maya.View {
    public class VAutoHider : Gtk.Box {

        Gtk.Label more_label;
        Gtk.Revealer more_revealer;

        public VAutoHider () {
            resize_mode = Gtk.ResizeMode.QUEUE;
            orientation = Gtk.Orientation.VERTICAL;
            more_label = new Gtk.Label ("");
            more_revealer = new Gtk.Revealer ();
            more_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            more_revealer.add (more_label);
            more_revealer.show_all ();
            pack_end (more_revealer);
            add.connect (() => {
                Gtk.Allocation allocation;
                get_allocation (out allocation);
                change_shown_events (allocation);
            });

            events |= Gdk.EventMask.SCROLL_MASK;
            events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        }

        public void change_allocation (Gtk.Allocation allocation) {
            set_size_request (allocation.width, allocation.height);
            change_shown_events (allocation);
        }

        public override void show_all () {
            base.show_all ();
            Gtk.Allocation alloc;
            get_allocation (out alloc);
            change_shown_events (alloc);
        }

        public override void show () {
            base.show ();
            Gtk.Allocation alloc;
            get_allocation (out alloc);
            change_shown_events (alloc);
        }

        public void change_shown_events (Gtk.Allocation allocation) {
            int children_length = (int)get_children ().length ();
            if (children_length == 0)
                return;
            int height = 0;

            Gtk.Requisition more_label_size;
            more_revealer.set_reveal_child (true);
            more_revealer.transition_type = Gtk.RevealerTransitionType.NONE;
            more_revealer.get_preferred_size (out more_label_size, null);
            more_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            for (int i = 0; i < children_length; i++) {
                var child = get_children ().nth_data (i);
                if (child == more_revealer)
                    continue;

                bool last = (i == children_length - 1);

                Gtk.Requisition child_size;
                child.show ();
                child.get_preferred_size (out child_size, null);
                height += child_size.height;

                bool should_hide;
                if (last)
                    should_hide = height > allocation.height;
                else
                    should_hide = height > allocation.height - more_label_size.height;

                if (should_hide) {
                    ((Gtk.Revealer)child).set_reveal_child (false);
                    child.hide ();
                } else {
                    var child_allocation = Gtk.Allocation ();
                    child_allocation.width = allocation.width;
                    child_allocation.height = child_size.height;
                    child_allocation.x = allocation.x;
                    child_allocation.y = allocation.y + height - child_size.height;
                    child.size_allocate (child_allocation);
                    child.show ();
                    ((Gtk.Revealer)child).set_reveal_child (true);
                }
            }

            int more = children_length - get_shown_children ();
            if (get_shown_children () != children_length && more > 0) {
                more_revealer.set_reveal_child (true);
                more_label.set_label (_("%u more…").printf (more));
            } else {
                more_revealer.set_reveal_child (false);
            }
        }

        /**
         * Returns the number of currently visible children.
         */
        public int get_shown_children () {
            int result = 0;
            foreach (var child in get_children ())
                if (child.visible)
                    result++;
            return result;
        }

    }
}