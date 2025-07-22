// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013 Maya Developers (https://launchpad.net/maya)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

// This is needed in order to have good placement for widgets
public class Maya.PlacementWidget : GLib.Object {

    ~PlacementWidget () {
        widget.destroy ();
    }

    public Gtk.Widget widget;
    public int row = 0;
    public int column = 0;
    public string ref_name;
    public bool needed = false; // Only usefull for Gtk.Entry and his derivates
}

namespace Maya.DefaultPlacementWidgets {
    public Gee.LinkedList<Maya.PlacementWidget> get_user (int row, bool needed = true, string entry_text = "", string? ph_text = null) {
        var user_label = new PlacementWidget () {
            column = 0,
            row = row,
            ref_name = "user_label",
            widget = new Gtk.Label (_("User:")) {
                xalign = 1.0f
            }
        };

        var user_entry = new PlacementWidget () {
            column = 1,
            row = row,
            needed = needed,
            ref_name = "user_entry",
            widget = new Gtk.Entry () {
                placeholder_text = ph_text ?? _("user.name"),
                text = entry_text
            }
        };

        var collection = new Gee.LinkedList<Maya.PlacementWidget> ();
        collection.add (user_label);
        collection.add (user_entry);

        return collection;
    }

    public Gee.LinkedList<Maya.PlacementWidget> get_email (int row, bool needed = true, string entry_text = "", string? ph_text = null) {
        var user_label = new PlacementWidget () {
            column = 0,
            row = row,
            ref_name = "email_label",
            widget = new Gtk.Label (_("Email:")) {
                xalign = 1.0f
            }
        };

        var user_entry = new PlacementWidget () {
            column = 1,
            row = row,
            needed = needed,
            ref_name = "email_entry",
            widget = new Gtk.Entry () {
                placeholder_text = ph_text ?? _("john@doe.com"),
                text = entry_text
            }
        };

        var collection = new Gee.LinkedList<Maya.PlacementWidget> ();
        collection.add (user_label);
        collection.add (user_entry);

        return collection;
    }

    public Maya.PlacementWidget get_keep_copy (int row, bool default_value = false) {
        var keep_check = new PlacementWidget () {
            column = 1,
            row = row,
            ref_name = "keep_copy",
            widget = new Gtk.CheckButton.with_label (_("Keep a copy locally")) {
                active = default_value
            }
        };

        return keep_check;
    }
}
