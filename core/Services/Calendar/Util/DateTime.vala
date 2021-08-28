/*
 * Copyright 2011-2021 elementary, Inc. (https://elementary.io)
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

    //--- GLib.DateTime Helpers ---//

    /* Returns true if 'a' and 'b' are the same GLib.DateTime */
    public bool datetime_equal_func (GLib.DateTime a, GLib.DateTime b) {
        return a.equal (b);
    }

    /**
     * Say if an event lasts all day.
     *
     * An all-day event is represented as both starting and ending at midnight
     * local time, so its duration is exactly a multiple of 24 hours.
     */
    public bool datetime_is_all_day (GLib.DateTime dtstart, GLib.DateTime dtend) {
        var timespan = dtend.difference (dtstart);

        if (timespan % GLib.TimeSpan.DAY == 0 && dtstart.get_hour () == 0) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * Converts two DateTimes representing a date and a time to one TimeType.
     *
     * The first contains the date; its time settings are ignored. The second
     * one contains the time itself; its date settings are ignored. If the time
     * is `null`, the resulting TimeType is of `DATE` type; if it is given, the
     * TimeType is of `DATE-TIME` type.
     *
     * This also accepts an optional `timezone` argument. If it is given a
     * timezone, the resulting TimeType will be relative to the given timezone.
     * If it is `null`, the resulting TimeType will be "floating" with no
     * timezone. If the argument is not given, it will default to the system
     * timezone.
     */
    public ICal.Time datetimes_to_icaltime (GLib.DateTime date, GLib.DateTime? time_local,
        ICal.Timezone? timezone = Calendar.TimeManager.get_default ().system_timezone) {

#if E_CAL_2_0
        var result = new ICal.Time.from_day_of_year (date.get_day_of_year (), date.get_year ());
#else
        var result = ICal.Time.from_day_of_year (date.get_day_of_year (), date.get_year ());
#endif

        // Check if it's a date. If so, set is_date to true and fix the time to be sure.
        // If it's not a date, first thing set is_date to false.
        // Then, set the timezone.
        // Then, set the time.
        if (time_local == null) {
            // Date type: ensure that everything corresponds to a date
#if E_CAL_2_0
            result.set_is_date (true);
            result.set_time (0, 0, 0);
#else
            result._is_date = 1;
            result.hour = 0;
            result.minute = 0;
            result.second = 0;
#endif
        } else {
            // Includes time
            // Set is_date first (otherwise timezone won't change)
#if E_CAL_2_0
            result.set_is_date (false);
#else
            result._is_date = 0;
#endif

            // Set timezone for the time to be relative to
#if E_CAL_2_0
            result.set_timezone (timezone);
#else
            result.zone = timezone;
#endif

            // Set the time with the updated time zone
#if E_CAL_2_0
            result.set_time (time_local.get_hour (), time_local.get_minute (), time_local.get_second ());
#else
            result._is_date = 0;
            result.hour = time_local.get_hour ();
            result.minute = time_local.get_minute ();
            result.second = time_local.get_second ();
#endif
        }

        return result;
    }

    /** Gets the start of the month that contains the given date
     *
     * Returns midnight (00:00) on that date.
     */
    public GLib.DateTime datetime_get_start_of_month (owned GLib.DateTime? date = null) {
        if (date == null) {
            date = new GLib.DateTime.now_local ();
        }

        return new GLib.DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
    }

    public GLib.DateTime datetime_strip_time (GLib.DateTime datetime) {
        return datetime.add_full (0, 0, 0, -datetime.get_hour (), -datetime.get_minute (), -datetime.get_second ());
    }
}
