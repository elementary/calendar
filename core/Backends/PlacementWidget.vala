/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2013-2025 elementary, Inc. (https://elementary.io)
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
