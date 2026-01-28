/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2014-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.Widgets.DynamicSpinner : Granite.Bin {
    private Gtk.ListBox list_box;
    private Gtk.Revealer revealer;

    private HashTable<string, Gtk.Widget> children_matcher;

    construct {
        children_matcher = new HashTable<string, Gtk.Widget> (str_hash, str_equal);

        var spinner = new Gtk.Spinner ();
        spinner.start ();

        list_box = new Gtk.ListBox () {
            selection_mode = NONE
        };

        var info_popover = new Gtk.Popover (null) {
            child = list_box,
            position = BOTTOM
        };

        var button = new Gtk.MenuButton () {
            child = spinner,
            popover = info_popover,
            valign = CENTER
        };

        var calmodel = Calendar.EventStore.get_default ();
        calmodel.connecting.connect ((source, cancellable) => add_source.begin (source, cancellable));
        calmodel.connected.connect ((source) => remove_source.begin (source));

        revealer = new Gtk.Revealer () {
            child = button,
            transition_type = CROSSFADE
        };

        child = revealer;
    }

    public async void add_source (E.Source source, Cancellable cancellable) {
        Idle.add (() => {
            revealer.reveal_child = true;

            var label = new Gtk.Label (source.get_display_name ());

            var stop_button = new Gtk.Button.from_icon_name ("process-stop-symbolic") {
                has_frame = false
            };

            stop_button.clicked.connect (() => {
                cancellable.cancel ();
            });

            var box = new Gtk.Box (HORIZONTAL, 12) {
                margin_top = 6,
                margin_end = 6,
                margin_bottom = 6,
                margin_start = 6
            };

            box.append (label);
            box.append (stop_button);

            lock (children_matcher) {
                children_matcher.insert (source.dup_uid (), box);
            }

            list_box.append (box);

            return false;
        });
    }

    public async void remove_source (E.Source source) {
        Idle.add (() => {
            lock (children_matcher) {
                var widget = children_matcher.get (source.dup_uid ());
                children_matcher.remove (source.dup_uid ());
                if (widget != null)
                    widget.destroy ();
                if (children_matcher.size () == 0) {
                    revealer.reveal_child = false;
                }
            }

            return false;
        });
    }
}
