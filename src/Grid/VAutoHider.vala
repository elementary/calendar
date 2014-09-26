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

        public VAutoHider () {
            resize_mode = Gtk.ResizeMode.QUEUE;
            orientation = Gtk.Orientation.VERTICAL;
            more_label = new Gtk.Label ("");
            pack_end (more_label);
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
            int height = 0;

            Gtk.Requisition more_label_size;
            more_label.show ();
            more_label.get_preferred_size (out more_label_size, null);

            for (int i = 0; i < get_children ().length (); i++) {
                var child = get_children ().nth_data (i);

                bool last = (i == get_children ().length () - 1);

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
                    child.hide ();
                } else {
                    var child_allocation = Gtk.Allocation ();
                    child_allocation.width = allocation.width;
                    child_allocation.height = child_size.height;
                    child_allocation.x = allocation.x;
                    child_allocation.y = allocation.y + height - child_size.height;
                    child.size_allocate (child_allocation);
                    child.show ();
                }
            }

            uint more = get_children ().length () - get_shown_children () -1;
            if (get_shown_children () != get_children ().length () && more > 0) {
                more_label.show ();
                var more_label_allocation = Gtk.Allocation ();
                more_label_allocation.width = allocation.width;
                more_label_allocation.height = more_label_size.height;
                more_label_allocation.x = allocation.x;
                more_label_allocation.y = allocation.y + allocation.height - more_label_size.height;
                more_label.size_allocate (more_label_allocation);
                more_label.set_label (_("%u more…").printf (more));
            } else {
                more_label.hide ();
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