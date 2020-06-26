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

    //--- ICal.Time Helpers ---//

    /**
     * Gets the timezone of the given TimeType as a GLib.TimeZone.
     */
    public GLib.TimeZone icaltime_get_timezone (ICal.Time date) {
        // Special case: return default UTC time zone for all-day events
        if (date.is_date ()) {
            debug ("Given date is 'DATE' type, not 'DATE_TIME': Using timezone UTC");
            return new GLib.TimeZone.utc ();
        }

        // Otherwise, get timezone from ICal
        unowned ICal.Timezone? timezone = null;
        var tzid = date.get_tzid ();
        // First, try using the tzid property
        if (tzid != null) {
            /* Standard city names are usable directly by GLib, so we can bypass
             * the ICal scaffolding completely and just return a new
             * GLib.TimeZone here. This method also preserves all the timezone
             * information, like going in/out of daylight savings, which parsing
             * from UTC offset does not.
             * Note, this can't recover from failure, since GLib.TimeZone
             * constructor doesn't communicate failure information. This block
             * will always return a GLib.TimeZone, which will be UTC if parsing
             * fails for some reason.
             */
            var prefix = "/freeassociation.sourceforge.net/";
            if (tzid.has_prefix (prefix)) {
                // TZID has prefix "/freeassociation.sourceforge.net/",
                // indicating a libical TZID.
                return new GLib.TimeZone (tzid.offset (prefix.length));
            } else {
                // TZID does not have libical prefix, indicating an Olson
                // standard city name.
                return new GLib.TimeZone (tzid);
            }
        }
        // If tzid fails, try ICal.Time.get_timezone ()
        if (timezone == null && date.get_timezone () != null) {
            timezone = date.get_timezone ();
        }
        // If nothing else works (timezone is still null), default to UTC
        if (timezone == null) {
            debug ("Date has no timezone info: defaulting to UTC");
            return new GLib.TimeZone.utc ();
        }

        // Get UTC offset and format for GLib.TimeZone constructor
        int is_daylight;
        int interval = timezone.get_utc_offset (date, out is_daylight);
        bool is_positive = interval >= 0;
        interval = interval.abs ();
        var hours = (interval / 3600);
        var minutes = (interval % 3600) / 60;
        var hour_string = "%s%02d:%02d".printf (is_positive ? "+" : "-", hours, minutes);

        return new GLib.TimeZone (hour_string);
    }

    /**
     * Converts the given ICal.Time to a DateTime.
     * XXX : Track next versions of evolution in order to convert ICal.Timezone to GLib.TimeZone with a dedicated function…
     */
    public GLib.DateTime icaltime_to_datetime (ICal.Time date) {
#if E_CAL_2_0
        int year, month, day, hour, minute, second;
        date.get_date (out year, out month, out day);
        date.get_time (out hour, out minute, out second);
        return new GLib.DateTime (icaltime_get_timezone (date), year, month,
            day, hour, minute, second);
#else
        return new GLib.DateTime (icaltime_get_timezone (date), date.year, date.month,
            date.day, date.hour, date.minute, date.second);
#endif
    }
}
