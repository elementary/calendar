/*
 Copyright (C) 2011 Christian Dywan <christian@twotoasts.de>

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 See the file COPYING for the full license text.
*/

namespace Maya.View {
    public class VAutoHider : Gtk.Container {
        List<Gtk.Widget> children;

        Gtk.Label more_label;

        //true if the object gets destroyed and notified via the destroy-signal
        bool end = false;

        public VAutoHider () {
            set_has_window (false);
            set_resize_mode(Gtk.ResizeMode.QUEUE);
            more_label = new Gtk.Label ("");
            more_label.set_parent (this);
            if (get_realized ())
                more_label.realize ();
            destroy.connect (() => {
                end = true;
            });
        }

        public override void add (Gtk.Widget widget) {
            children.append (widget);
            widget.set_parent (this);
            if (get_realized ())
                widget.realize ();
        }

        public override void remove (Gtk.Widget widget) {
            children.remove (widget);
            widget.unparent ();
            if (widget.get_realized ())
                widget.unrealize ();
            queue_resize ();
        }

        public override void forall_internal (bool internal, Gtk.Callback callback) {
            if (end) { //if widget already destroyed, abort the forall
                return;
            }
            foreach (var child in children)
                callback (child);
            callback (more_label);
        }

        public void reorder_child (Gtk.Widget widget, int position) {
            children.remove (widget);
            children.insert (widget, position);
        }

        public override void map () {
            set_mapped (true);
            foreach (var child in children) {
                if (child.visible && !child.get_mapped ())
                    child.map ();
            }
            if (more_label.visible && !more_label.get_mapped ())
                more_label.map ();
        }

        public override void size_allocate (Gtk.Allocation allocation) {

            set_allocation (allocation);

            int height = 0;

            Gtk.Requisition more_label_size;
            more_label.get_preferred_size (out more_label_size, null);

            for (int i = 0; i < children.length (); i++) {
                var child = children.nth_data (i);

                bool last = (i == children.length () - 1);

                Gtk.Requisition child_size;
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

            if (get_shown_children () != children.length ()) {
                uint more = children.length () - get_shown_children ();
                more_label.show ();
                var more_label_allocation = Gtk.Allocation ();
                more_label_allocation.width = allocation.width;
                more_label_allocation.height = more_label_size.height;
                more_label_allocation.x = allocation.x;
                more_label_allocation.y = allocation.y + allocation.height - more_label_size.height;
                more_label.size_allocate (more_label_allocation);
                more_label.set_label (_(@"$more more ..."));
            } else {
                more_label.hide ();
            }

        }

        /**
         * Returns the number of currently visible children.
         */
        public int get_shown_children () {
            int result = 0;

            foreach (var child in children)
                if (child.visible)
                    result++;
            return result;
        }

    }
}
