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
    private Widgets.CalendarChooser calchooser;

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
                (ulong) files.length
            ).printf (files.length);
        }

        calchooser = new Widgets.CalendarChooser ();

        var frame = new Gtk.Frame (null);
        frame.add (calchooser);
        frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

        custom_bin.add (frame);

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
        var source = calchooser.current_source;
        var calmodel = Calendar.EventStore.get_default ();
        foreach (var file in files) {
#if E_CAL_2_0
            var ical = ECal.util_parse_ics_file (file.get_path ());
#else
            var ical = ECal.Util.parse_ics_file (file.get_path ());
#endif
            if (ical.is_valid ()) {
#if E_CAL_2_0
                for (ICal.Component comp = ical.get_first_component (ICal.ComponentKind.VEVENT_COMPONENT);
#else
                for (unowned ICal.Component comp = ical.get_first_component (ICal.ComponentKind.VEVENT_COMPONENT);
#endif
                     comp != null;
                     comp = ical.get_next_component (ICal.ComponentKind.VEVENT_COMPONENT)) {
                    var ecal = new ECal.Component.from_string (comp.as_ical_string ());
                    calmodel.add_event (source, ecal);
                }
            }
        }
    }
}
