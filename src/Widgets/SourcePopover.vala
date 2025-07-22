/*
 * Copyright 2013-2020 elementary, Inc. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class Calendar.Widgets.SourcePopover : Gtk.Popover {
    private GLib.HashTable<string, SourceRow?> src_map;

    private Maya.View.SourceDialog src_dialog = null;

    private Gtk.Grid main_grid;
    private Gtk.ListBox calendar_box;
    private Gtk.ScrolledWindow scroll;

    construct {
        calendar_box = new Gtk.ListBox () {
            selection_mode = Gtk.SelectionMode.NONE
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

        scroll = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            max_content_height = 300,
            propagate_natural_height = true
        };
        scroll.add (calendar_box);

        src_map = new GLib.HashTable<string, SourceRow?> (str_hash, str_equal);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
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

        main_grid = new Gtk.Grid () {
            margin_bottom = 3,
            orientation = Gtk.Orientation.VERTICAL
        };

        main_grid.add (scroll);
        main_grid.add (separator);
        main_grid.add (add_calendar_button);
        main_grid.add (import_calendar_button);
        main_grid.add (accounts_button);
        main_grid.show_all ();

        add (main_grid);
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
            this.hide ();

            file_chooser.response.connect ((response_id) => {
                GLib.File[] files = null;

                if (response_id == Gtk.ResponseType.ACCEPT) {
                    foreach (unowned GLib.File selected_file in file_chooser.get_files ()) {
                        files += selected_file;
                    }
                }

                if (files != null) {
                    var dialog = new Maya.View.ImportDialog (files);
                    dialog.show_all ();
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
        header.show_all ();
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
        if (source.enabled == false)
            return;

        if (source.dup_uid () in src_map)
            return;

        var source_item = new SourceRow (source);
        source_item.edit_request.connect (edit_source);
        source_item.remove_request.connect (remove_source);

        calendar_box.add (source_item);

        int minimum_height;
        int natural_height;
        calendar_box.show_all ();
        calendar_box.get_preferred_height (out minimum_height, out natural_height);
        if (natural_height > 200) {
            scroll.set_size_request (-1, 200);
        } else {
            scroll.set_size_request (-1, natural_height);
        }

        source_item.destroy.connect (() => {
            calendar_box.show_all ();
            calendar_box.get_preferred_height (out minimum_height, out natural_height);
            if (natural_height > 200) {
                scroll.set_size_request (-1, 200);
            } else {
                scroll.set_size_request (-1, natural_height);
            }
        });

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
