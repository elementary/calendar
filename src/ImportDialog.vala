/*-
 * Copyright (c) 2011-2018 elementary, Inc. (https://elementary.io)
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

public class Maya.View.ImportDialog : Granite.MessageDialog {
    private File[] files;
    private Widgets.CalendarButton calchooser_button;

    public ImportDialog (File[] files) {
        Object (
            buttons: Gtk.ButtonsType.CANCEL,
            image_icon: new ThemedIcon ("document-import"),
            primary_text: _("Select a Calendar to Import Into")
        );

        this.files = files;

        if (files.length == 1) {
            string name = "";
            var file = files[0];
            try {
                var fileinfo = file.query_info (FileAttribute.STANDARD_DISPLAY_NAME, FileQueryInfoFlags.NONE, null);
                name = fileinfo.get_display_name ();
            } catch (Error e) {
                // This should never happen.
                critical (e.message);
            }

            secondary_text = _("Events from \"%s\" will be merged with this calendar:").printf (name);
        } else {
            secondary_text = ngettext (
                "Events from %d file will be merged with this calendar:",
                "Events from %d files will be merged with this calendar:",
                files.length
            );
        }

        calchooser_button = new Widgets.CalendarButton ();

        custom_bin.add (calchooser_button);

        var ok_button = (Gtk.Button) add_button (_("Import"), Gtk.ResponseType.APPLY);
        ok_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.APPLY) {
                import_files ();
            }
            destroy ();
        });
    }

    private void import_files () {
        var source = calchooser_button.current_source;
        var calmodel = Model.CalendarModel.get_default ();
        foreach (var file in files) {
            var ical = ECal.Util.parse_ics_file (file.get_path ());
            if (ical.is_valid () == 1) {
                for (unowned ICal.Component comp = ical.get_first_component (ICal.ComponentKind.VEVENT);
                     comp != null;
                     comp = ical.get_next_component (ICal.ComponentKind.VEVENT)) {
                    var ecal = new ECal.Component.from_string (comp.as_ical_string ());
                    calmodel.add_event (source, ecal);
                }
            }
        }
    }
}
