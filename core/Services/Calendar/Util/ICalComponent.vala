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

    //--- ICal.Component Helpers ---//

    /** Gets the start and end times of @component as {@link ICal.Time} objects.
     * 
     * This accounts for implicit end times by calculating its value from a
     * duration, if necessary.
     */
    public void icalcomponent_get_icaltimes (ICal.Component component, out ICal.Time dt_start, out ICal.Time dt_end) {
        dt_start = component.get_dtstart ();
        dt_end = component.get_dtend ();

        // If dt_end is implicit, calculate from dt_start
        if (dt_end.is_null_time ()) {
            if (!component.get_duration ().is_null_duration ()) {
                // Given duration
                dt_end = dt_start.add (component.get_duration ());
            } else if (dt_start.is_date ()) {
                // Implicit duration for DATE-type: 1 day
                dt_end = dt_start.clone ();
                dt_end.adjust (1, 0, 0, 0);
            } else {
                // Implicit duration for DATE-TIME-type: 0
                dt_end = dt_start;
            }
        }
    }

    /** Gets a pair of {@link GLib.DateTime} objects representing the start and
     *  end of the given component, represented in the system time zone.
     *
     * The conversion behavior differs based on the type of {@link ICal.Time}.
     * DATE type times (which contain no time information) are represented as
     * midnight on the given date in the local timezone
     * (see {@link Calendar.Util.datetime_is_all_day}).
     * DATE-TIME type times are converted to the local timezone if they have
     * a time zone, and are represented at the given time in the local timezone
     * if they are floating.
     *
     * Note that unlike {@link icalcomponent_get_datetimes}, the
     * {@link GLib.TimeZone} contained in @start_date and @end_date is
     * guaranteed to be correct, since there is a well-defined local timezone
     * between both libical and GLib. For
     * more details, see {@link Calendar.Util.icaltime_to_local_datetime}.
     *
     * @see icalcomponent_get_datetimes
     */
    public void icalcomponent_get_local_datetimes (ICal.Component component, out GLib.DateTime start_date, out GLib.DateTime end_date) {
        ICal.Time dt_start;
        ICal.Time dt_end;
        icalcomponent_get_icaltimes (component, out dt_start, out dt_end);

        start_date = Calendar.Util.icaltime_to_local_datetime (dt_start);
        end_date = Calendar.Util.icaltime_to_local_datetime (dt_end);
    }


    /** Gets a pair of {@link GLib.DateTime} objects representing the start and
     *  end of the given component, represented in the time zone of @component.
     *
     * **Note:** the {@link GLib.TimeZone} data of @start_date and @end_date
     * is not guaranteed to be correct. You should never assume that the time
     * zone data contained in the resulting objects is correct. The intention
     * is that all time zone calculations should be done in libical directly,
     * where time zone data should be correct. This is because it's not
     * always possible to map a libical timezone to a GLib timezone. For
     * more details, see {@link Calendar.Util.icaltime_to_datetime}.
     *
     * @see icalcomponent_get_local_datetimes
     */
    public void icalcomponent_get_datetimes (ICal.Component component, out GLib.DateTime start_date, out GLib.DateTime end_date) {
        ICal.Time dt_start;
        ICal.Time dt_end;
        icalcomponent_get_icaltimes (component, out dt_start, out dt_end);

        start_date = Calendar.Util.icaltime_to_datetime (dt_start);
        end_date = Calendar.Util.icaltime_to_datetime (dt_end);
    }

    /** Wraps {@link icalcomponent_get_local_datetimes()}, including date
     *  adjustments for all-day events.
     *
     * Like {@link icalcomponent_get_local_datetimes()}, this gets a pair of
     * {@link GLib.DateTime} objects representing the start and end of the
     * given component.
     *
     * It differs in its handling of all-day events. According to
     * RFC 5545, their end time is exclusive, representing the day after the
     * last day the event occurs. To handle this, we must "fake" an earlier
     * date to replicate the expected experience of an inclusive end date.
     * It substracts a single day from the end time of all-day events. It leaves
     * other events unchanged.
     *
     * This should be used for user-facing display only. It breaks from spec to
     * make the display of all-day events more intuitive, and doesn't reflect
     * the actual times the events occur.
     *
     * This converts the resulting times to the local timezone. If you want to keep
     * the result in @component's timezone, use {@link icalcmponent_get_datetimes_for_display}.
     */
    public void icalcomponent_get_local_datetimes_for_display (ICal.Component component, out GLib.DateTime start_date, out GLib.DateTime end_date) {
        icalcomponent_get_local_datetimes (component, out start_date, out end_date);

        if (datetime_is_all_day (start_date, end_date)) {
            end_date = end_date.add_days (-1);
        }
    }

    /** Wraps {@link icalcomponent_get_datetimes()}, including date
     *  adjustments for all-day events.
     *
     * Like {@link icalcomponent_get_datetimes()}, this gets a pair of
     * {@link GLib.DateTime} objects representing the start and end of the
     * given component.
     *
     * It differs in its handling of all-day events. According to
     * RFC 5545, their end time is exclusive, representing the day after the
     * last day the event occurs. To handle this, we must "fake" an earlier
     * date to replicate the expected experience of an inclusive end date.
     * It substracts a single day from the end time of all-day events. It leaves
     * other events unchanged.
     *
     * This should be used for user-facing display only. It breaks from spec to
     * make the display of all-day events more intuitive, and doesn't reflect
     * the actual times the events occur.
     *
     * This keeps the resulting times in @component's timezone. If you want to convert
     * the result to local time, use {@link icalcmponent_get_local_datetimes_for_display}.
     */
    public void icalcomponent_get_datetimes_for_display (ICal.Component component, out GLib.DateTime start_date, out GLib.DateTime end_date) {
        icalcomponent_get_datetimes (component, out start_date, out end_date);

        if (datetime_is_all_day (start_date, end_date)) {
            end_date = end_date.add_days (-1);
        }
    }

    /** Returns whether the given icalcomponent overlaps with the time range.
     *
     * This is true if the icalcomponent either starts or ends within the range, even
     * if the entire icalcomponent doesn't happen within the range.
     */
    public bool icalcomponent_is_in_range (ICal.Component component, Calendar.Util.DateRange range) {
        GLib.DateTime start, end;
        icalcomponent_get_local_datetimes (component, out start, out end);

        int c1 = start.compare (range.first_dt);
        int c2 = start.compare (range.last_dt);
        int c3 = end.compare (range.first_dt);
        int c4 = end.compare (range.last_dt);

        if (c1 <= 0 && c3 > 0) {
            return true;
        }
        if (c2 < 0 && c4 > 0) {
            return true;
        }
        if (c1 >= 0 && c2 < 0) {
            return true;
        }
        if (c3 > 0 && c4 < 0) {
            return true;
        }

        return false;
    }

    public bool icalcomponent_is_multiday (ICal.Component component) {
        GLib.DateTime start, end;
        icalcomponent_get_local_datetimes_for_display (component, out start, out end);

        if (start.get_year () != end.get_year () || start.get_day_of_year () != end.get_day_of_year ())
            return true;

        return false;
    }
}
