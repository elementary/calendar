/*
 * Copyright 2011-2020 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

namespace Calendar.Util {

    //--- ECal.Component Helpers ---//

    /* Returns true if 'a' and 'b' are the same ECal.Component */
    public bool ecalcomponent_equal_func (ECal.Component a, ECal.Component b) {
        return a.get_id ().equal (b.get_id ());
    }

    public int ecalcomponent_compare_func (ECal.Component? a, ECal.Component? b) {
        if (a == null && b != null) {
            return 1;
        } else if (b == null && a != null) {
            return -1;
        } else if (b == null && a == null) {
            return 0;
        }

        var a_id = a.get_id ();
        var b_id = b.get_id ();
        int res = GLib.strcmp (a_id.get_uid (), b_id.get_uid ());
        if (res == 0) {
            return GLib.strcmp (a_id.get_rid (), b_id.get_rid ());
        }

        return res;
    }

    public bool ecalcomponent_is_on_day (ECal.Component component, GLib.DateTime day) {
        var event_store = Calendar.EventStore.get_default ();
        unowned ICal.Timezone system_timezone = event_store.system_timezone;

        var stripped_time = new GLib.DateTime.local (day.get_year (), day.get_month (), day.get_day_of_month (), 0, 0, 0);

        var selected_date_unix = stripped_time.to_unix ();
        var selected_date_unix_next = stripped_time.add_days (1).to_unix ();

        /* We want to be relative to the local timezone */
        unowned ICal.Component? ical_component = component.get_icalcomponent ();
        ICal.Time? start_time;
        ICal.Time? end_time;
        switch (component.get_vtype ()) {
            case ECal.ComponentVType.EVENT:
                start_time = ical_component.get_dtstart ();
                end_time = ical_component.get_dtend ();
                break;

            case ECal.ComponentVType.TODO:
                start_time = ical_component.get_due ();
                end_time = ical_component.get_due ();
                break;

            default:
                return false;
        }

        time_t start_unix = start_time.as_timet_with_zone (system_timezone);
        time_t end_unix = end_time.as_timet_with_zone (system_timezone);

        /* If the selected date is inside the event */
        if (start_unix < selected_date_unix && selected_date_unix_next < end_unix) {
            return true;
        }

        /* If the event start before the selected date but finished in the selected date */
        if (start_unix < selected_date_unix && selected_date_unix < end_unix) {
            return true;
        }

        /* If the event start after the selected date but finished after the selected date */
        if (start_unix < selected_date_unix_next && selected_date_unix_next < end_unix) {
            return true;
        }

        /* If the event is inside the selected date */
        if (start_unix < selected_date_unix_next && selected_date_unix < end_unix) {
            return true;
        }

        return false;
    }
}
