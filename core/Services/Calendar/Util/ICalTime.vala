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
     *
     * For floating times, returns the local timezone.
     * Dates (with no time component) are considered floating.
     */
    public GLib.TimeZone icaltime_get_timezone (ICal.Time date) {
        // Special case: dates are floating, so return local time zone
        if (date.is_date ()) {
            return new GLib.TimeZone.local ();
        }

        var tzid = date.get_tzid ();
        if (tzid == null) {
            return new GLib.TimeZone.local ();
        }

        // Otherwise, get timezone from ICal
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
                // TZID does not have libical prefix, potentially indicating an Olson
                // standard city name.
                return new GLib.TimeZone (tzid);
            }
        }

        //FIXME See https://github.com/libical/libical/pull/513
        // If tzid fails, try ICal.Time.get_timezone ()
        ICal.Timezone* timezone = date.get_timezone ();

        // Get UTC offset and format for GLib.TimeZone constructor
        int is_daylight;
        int interval = timezone->get_utc_offset (date, out is_daylight);
        bool is_positive = interval >= 0;
        interval = interval.abs ();
        var hours = (interval / 3600);
        var minutes = (interval % 3600) / 60;
        var hour_string = "%s%02d:%02d".printf (is_positive ? "+" : "-", hours, minutes);

        delete timezone;

        return new GLib.TimeZone (hour_string);
    }

    /**
     * Converts the given ICal.Time to a DateTime.
     *
     * XXX : Track next versions of evolution in order to convert ICal.Timezone to GLib.TimeZone with a dedicated function…
     *
     * **Note:** All timezone information in the original @date is lost.
     * While this function attempts to convert the timezone data contained in
     * @date to GLib, this process does not always work. You should never
     * assume that the {@link GLib.TimeZone} contained in the resulting
     * DateTime is correct. The wall-clock date and time are correct for the
     * original timezone, however.
     *
     * For example, a timezone like `Western European Standard Time` is not
     * easily representable in GLib. The resulting {@link GLib.TimeZone} is
     * likely to be the system's local timezone, which is (probably) incorrect.
     * However, if the event occurrs at 8:15 AM on January 1, 2020, the time
     * contained in the returned DateTime will be 8:15 AM on January 1, 2020
     * in the local timezone. The wall clock time is correct, but the time
     * zone is not.
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

    /**
     * Converts the given ICal.Time to a DateTime, represented in the system
     * timezone.
     *
     * All timezone information in the original @date is lost. However, the
     * {@link GLib.TimeZone} contained in the resulting DateTime is correct,
     * since there is a well-defined local timezone between both libical and
     * GLib.
     */
    public GLib.DateTime icaltime_to_local_datetime (ICal.Time date) {
        assert (!date.is_null_time ());
        var converted = icaltime_convert_to_local (date);
#if E_CAL_2_0
        int year, month, day, hour, minute, second;
        converted.get_date (out year, out month, out day);
        converted.get_time (out hour, out minute, out second);
        return new GLib.DateTime.local (year, month,
            day, hour, minute, second);
#else
        return new GLib.DateTime.local (date.year, date.month,
            date.day, date.hour, date.minute, date.second);
#endif
    }

    public ICal.Time icaltime_convert_to_local (ICal.Time time) {
        var system_tz = Calendar.TimeManager.get_default ().system_timezone;
        return time.convert_to_zone (system_tz);
    }
}
