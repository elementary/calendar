/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2013-2025 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class Calendar.Widgets.SourcePopover : Gtk.Popover {
    private GLib.HashTable<string, SourceRow?> src_map;

    private Maya.View.SourceDialog src_dialog = null;

    private Gtk.ListBox calendar_box;

    construct {
        calendar_box = new Gtk.ListBox () {
            selection_mode = BROWSE
        };
        calendar_box.set_header_func (header_update_func);
        calendar_box.set_sort_func ((child1, child2) => {
            var comparison = ((SourceRow)child1).location.collate (((SourceRow)child2).location);
            if (comparison == 0) {
                return ((SourceRow)child1).label.collate (((SourceRow)child2).label);
           } else {
                return comparison;
           }
        });

        var scroll = new Gtk.ScrolledWindow (null, null) {
            child = calendar_box,
            hscrollbar_policy = NEVER,
            max_content_height = 300,
            propagate_natural_height = true
        };

        src_map = new GLib.HashTable<string, SourceRow?> (str_hash, str_equal);

        var separator = new Gtk.Separator (HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        };

        var add_calendar_button = new Gtk.ModelButton () {
            text = _("Add New Calendar…")
        };

        var import_calendar_button = new Gtk.ModelButton () {
            text = _("Import iCalendar File…")
        };

        var accounts_button = new Gtk.ModelButton () {
            text = _("Online Accounts Settings…")
        };

        var main_box = new Gtk.Box (VERTICAL, 0) {
            margin_bottom = 3,
        };

        main_box.append (scroll);
        main_box.append (separator);
        main_box.append (add_calendar_button);
        main_box.append (import_calendar_button);
        main_box.append (accounts_button);

        child = main_box;
        populate.begin ();

        add_calendar_button.button_release_event.connect (() => {
            edit_source ();
            return Gdk.EVENT_STOP;
        });

        import_calendar_button.button_release_event.connect (() => {
            var ics_filter = new Gtk.FileFilter ();
            ics_filter.add_mime_type ("application/ics");

            var file_chooser = new Gtk.FileChooserNative (
                _("Select ICS File to Import"),
                null,
                Gtk.FileChooserAction.OPEN,
                _("Open"),
                _("Cancel")
            );

            file_chooser.set_local_only (true);
            file_chooser.set_select_multiple (true);
            file_chooser.set_filter (ics_filter);

            file_chooser.show ();
            popdown ();

            file_chooser.response.connect ((response_id) => {
                GLib.File[] files = null;

                if (response_id == Gtk.ResponseType.ACCEPT) {
                    foreach (unowned GLib.File selected_file in file_chooser.get_files ()) {
                        files += selected_file;
                    }
                }

                if (files != null) {
                    var dialog = new Maya.View.ImportDialog (files);
                    dialog.present ();
                }
            });

            return Gdk.EVENT_STOP;
        });

        accounts_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("settings://accounts/online", null);
            } catch (Error e) {
                warning ("Failed to open account settings: %s", e.message);
            }
        });
    }

    private async void populate () {
        try {
            var registry = yield new E.SourceRegistry (null);
            registry.source_removed.connect (source_removed);
            registry.source_disabled.connect (source_disabled);
            registry.source_enabled.connect (add_source_to_view);
            registry.source_added.connect (add_source_to_view);

            // Add sources
            registry.list_sources (E.SOURCE_EXTENSION_CALENDAR).foreach ((source) => {
                add_source_to_view (source);
            });
        } catch (GLib.Error error) {
            critical (error.message);
        }
    }

    private void header_update_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
        var row_location = ((SourceRow)row).location;
        if (before != null) {
            var before_row_location = ((SourceRow)before).location;
            if (before_row_location == row_location) {
                row.set_header (null);
                return;
            }
        }

        var header = new Granite.HeaderLabel (row_location);
        row.set_header (header);
    }

    private void source_removed (E.Source source) {
        var source_item = src_map.get (source.dup_uid ());
        source_item.hide ();
        src_map.remove (source.dup_uid ());
        source_item.destroy ();
    }

    private void source_disabled (E.Source source) {
        var source_item = src_map.get (source.dup_uid ());
        source_item.source_has_changed ();
    }

    private void add_source_to_view (E.Source source) {
        if (source.enabled == false) {
            return;
        }

        if (source.dup_uid () in src_map) {
            return;
        }

        var source_item = new SourceRow (source);
        source_item.edit_request.connect (edit_source);
        source_item.remove_request.connect (remove_source);

        calendar_box.append (source_item);

        src_map.set (source.dup_uid (), source_item);
    }

    private void remove_source (E.Source source) {
        Calendar.EventStore.get_default ().trash_calendar (source);
        var source_item = src_map.get (source.dup_uid ());
        source_item.show_calendar_removed ();
    }

    private void edit_source (E.Source? source = null) {
        if (src_dialog == null) {
            src_dialog = new Maya.View.SourceDialog () {
                modal = true,
                transient_for = ((Gtk.Application) GLib.Application.get_default ()).active_window
            };

            src_dialog.go_back.connect (() => {
                src_dialog.hide ();
            });
        }

        popdown ();
        src_dialog.set_source (source);
        src_dialog.present ();
    }
}
