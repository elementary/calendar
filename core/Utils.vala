//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Maya.Util {

    public int compare_events (ECal.Component comp1, ECal.Component comp2) {
        var res = comp1.get_icalcomponent ().get_dtstart ().compare (comp2.get_icalcomponent ().get_dtstart ());
        if (res != 0)
            return res;

        // If they have the same date, sort them alphabetically
        return comp1.get_summary ().get_value ().collate (comp2.get_summary ().get_value ());
    }

    /*
     * Gee Utility Functions
     */

    /* Computes hash value for E.Source */
    private uint source_hash_func (E.Source key) {
        return key.dup_uid (). hash ();
    }

    /*
     * E.Source Utils
     */
    public string get_source_location (E.Source source) {
        var registry = Calendar.EventStore.get_default ().registry;
        string parent_uid = source.parent;
        E.Source parent_source = source;
        while (parent_source != null) {
            parent_uid = parent_source.parent;

            if (parent_source.has_extension (E.SOURCE_EXTENSION_AUTHENTICATION)) {
                var collection = (E.SourceAuthentication)parent_source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
                if (collection.user != null) {
                    return collection.user;
                }
            }

            if (parent_source.has_extension (E.SOURCE_EXTENSION_COLLECTION)) {
                var collection = (E.SourceCollection)parent_source.get_extension (E.SOURCE_EXTENSION_COLLECTION);
                if (collection.identity != null) {
                    return collection.identity;
                }
            }

            if (parent_uid == null)
                break;

            parent_source = registry.ref_source (parent_uid);
        }

        return _("On this computer");
    }

    /*
     * ical Exportation
     */

    public void save_temp_selected_calendars () {
        var calmodel = Calendar.EventStore.get_default ();
        var events = calmodel.get_events ();
        var builder = new StringBuilder ();
        builder.append ("BEGIN:VCALENDAR\n");
        builder.append ("VERSION:2.0\n");
        foreach (ECal.Component event in events) {
            builder.append (event.get_as_string ());
        }
        builder.append ("END:VCALENDAR");

        string file_path = GLib.Environment.get_tmp_dir () + "/calendar.ics";
        try {
            var file = File.new_for_path (file_path);
            file.replace_contents (builder.data, null, false, FileCreateFlags.REPLACE_DESTINATION, null);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }

    public ECal.Component? copy_ecal_component (ECal.Component? original) {
        if (original == null) {
            return null;
        }

        ECal.Component copy = original.clone ();
        E.Source source = original.get_data<E.Source> ("source");
        copy.set_data<E.Source> ("source", source);
        return copy;
    }
}
