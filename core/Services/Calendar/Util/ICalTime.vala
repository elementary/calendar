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

        unowned string? tzid = date.get_tzid ();
        if (tzid == null) {
            // In libical, null tzid means floating time
            assert (date.get_timezone () == null);
            return new GLib.TimeZone.local ();
        }

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
        const string LIBICAL_TZ_PREFIX = "/freeassociation.sourceforge.net/";
        if (tzid.has_prefix (LIBICAL_TZ_PREFIX)) {
            // TZID has prefix "/freeassociation.sourceforge.net/",
            // indicating a libical TZID.
            return new GLib.TimeZone (tzid.offset (LIBICAL_TZ_PREFIX.length));
        } else {
            // TZID does not have libical prefix, potentially indicating an Olson
            // standard city name.
            return new GLib.TimeZone (tzid);
        }
    }

    /**
     * Converts the given ICal.Time to a GLib.DateTime.
     *
     * XXX : Track next versions of evolution in order to convert ICal.Timezone
     * to GLib.TimeZone with a dedicated function…
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
     * However, if the event occurs at 8:15 AM on January 1, 2020, the time
     * contained in the returned DateTime will be 8:15 AM on January 1, 2020
     * in the local timezone. The wall clock time is correct, but the time
     * zone is not.
     */
    public GLib.DateTime icaltime_to_datetime (ICal.Time date) {
        int year, month, day, hour, minute, second;
        date.get_date (out year, out month, out day);
        date.get_time (out hour, out minute, out second);
        return new GLib.DateTime (icaltime_get_timezone (date), year, month,
            day, hour, minute, second);
    }

    /**
     * Converts the given ICal.Time to a GLib.DateTime, represented in the
     * system timezone.
     *
     * All timezone information in the original @date is lost. However, the
     * {@link GLib.TimeZone} contained in the resulting DateTime is correct,
     * since there is a well-defined local timezone between both libical and
     * GLib.
     */
    public GLib.DateTime icaltime_to_local_datetime (ICal.Time date) {
        assert (!date.is_null_time ());
        var converted = icaltime_convert_to_local (date);
        int year, month, day, hour, minute, second;
        converted.get_date (out year, out month, out day);
        converted.get_time (out hour, out minute, out second);
        return new GLib.DateTime.local (year, month,
            day, hour, minute, second);
    }

    /** Converts the given ICal.Time to the local (or system) timezone
     */
    public ICal.Time icaltime_convert_to_local (ICal.Time time) {
        var system_tz = Calendar.TimeManager.get_default ().system_timezone;
        return time.convert_to_zone (system_tz);
    }
}
