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

public class Calendar.EventStore : Calendar.Store {

    protected EventStore () {
        Object (source_extension_name: E.SOURCE_EXTENSION_CALENDAR);
    }

    public static Calendar.Store get_default () {
        if (store == null)
            store = new Calendar.EventStore ();
        return store;
    }

    static construct {
        if (SettingsSchemaSource.get_default ().lookup ("io.elementary.calendar.savedstate", true) != null) {
            state_settings = new GLib.Settings ("io.elementary.calendar.savedstate");
        }
    }

    //--- Public Methods ---//

    public override bool is_source_active (E.Source source) {
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        if (cal.selected == true && source.enabled == true) {
            return true;
        }
        return false;
    }
}
