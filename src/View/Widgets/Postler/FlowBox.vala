/*
 Copyright (C) 2011 Christian Dywan <christian@twotoasts.de>

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 See the file COPYING for the full license text.
*/

namespace Maya.View.Widgets {
    public class FlowBox : Gtk.Container {
        List<Gtk.Widget> children;
        int last_row_count;
        int last_row_height;

        public FlowBox () {
            set_has_window (false);
            set_resize_mode(Gtk.ResizeMode.IMMEDIATE);
        }

        public override void add (Gtk.Widget widget) {
            children.append (widget);
            widget.set_parent (this);
            if (get_realized ())
                widget.realize ();
            queue_resize ();
        }

        public override void remove (Gtk.Widget widget) {
            children.remove (widget);
            check_preferred_size (null, null);
            widget.unparent ();
            if (widget.get_realized ())
                widget.unrealize ();
            queue_resize ();
        }

        public override void forall_internal (bool internal, Gtk.Callback callback) {
            foreach (var child in children)
                callback (child);
        }

        public void reorder_child (Gtk.Widget widget, int position) {
            children.remove (widget);
            children.insert (widget, position);
            queue_resize ();
        }

        public override void map () {
            set_mapped (true);
            foreach (var child in children) {
                if (child.visible && !child.get_mapped ())
                    child.map ();
            }
        }

        public override void size_allocate (Gtk.Allocation allocation) {
            set_allocation (allocation);

            int row_count;
            int row_height;
            check_preferred_size (out row_count, out row_height);
            int width = 0;
            int row = 1;
            foreach (var child in children) {
                if (child.visible) {
                    Gtk.Requisition child_size;
                    child.get_preferred_size (out child_size, null);
                    width += child_size.width;
                    if (width > allocation.width && width != child_size.width) {
                        row++;
                        width = child_size.width;
                    }

                    var child_allocation = Gtk.Allocation ();
                    child_allocation.width = child_size.width;
                    child_allocation.height = row_height;
                    child_allocation.x = allocation.x + width - child_size.width;
                    child_allocation.y = allocation.y + row_height * (row - 1);
                    child.size_allocate (child_allocation);
                }
            }
            queue_resize ();
        }

        void check_preferred_size (out int row_count, out int row_height) {
            Gtk.Allocation allocation;
            get_allocation (out allocation);

            int width = 0;
            row_count = 1;
            row_height = 1;

            foreach (var child in children) {
                if (child.visible) {
                    Gtk.Requisition child_size;
                    child.get_preferred_size (out child_size, null);
                    width += child_size.width;

                    if (width > allocation.width && width != child_size.width) {
                        row_count++;
                        width = child_size.width;
                    }
                    row_height = int.max (row_height, child_size.height);
                }
            }

            if (last_row_count != row_count || last_row_height != row_height) {
                last_row_count = row_count;
                last_row_height = row_height;
                set_size_request (-1, row_height * row_count);
            }
        }

    }
}
