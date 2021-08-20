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

    /** Gets a pair of {@link GLib.DateTime} objects representing the start and
     *  end of the given component, represented in the system time zone.
     */
    public void icalcomponent_get_local_datetimes (ICal.Component component, out GLib.DateTime start_date, out GLib.DateTime end_date) {
        icalcomponent_get_datetimes (component, out start_date, out end_date);

        if (!Calendar.Util.datetime_is_all_day (start_date, end_date)) {
        // Don't convert timezone for date with only day info, which is considered floating
            start_date = start_date.to_local ();
            end_date = end_date.to_local ();
        }
    }

    /** Gets a pair of {@link GLib.DateTime} objects representing the start and
     *  end of the given component, represented in the time zone of @component.
     */
    public void icalcomponent_get_datetimes (ICal.Component component, out GLib.DateTime start_date, out GLib.DateTime end_date) {
        ICal.Time dt_start = component.get_dtstart ();
        ICal.Time dt_end = component.get_dtend ();
        start_date = Calendar.Util.icaltime_to_datetime (dt_start);

        // Get end date, which can be specified in multiple ways
        if (!dt_end.is_null_time ()) {
            end_date = Calendar.Util.icaltime_to_datetime (dt_end);
        } else if (dt_start.is_date ()) {
            end_date = start_date;
        } else if (!component.get_duration ().is_null_duration ()) {
            dt_end = dt_start.add (component.get_duration ());
            end_date = Calendar.Util.icaltime_to_datetime (dt_end);
        } else {
            end_date = start_date.add_days (1);
        }
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
     */
    public void icalcomponent_get_local_datetimes_for_display (ICal.Component component, out GLib.DateTime start_date, out GLib.DateTime end_date) {
        icalcomponent_get_local_datetimes (component, out start_date, out end_date);

        if (datetime_is_all_day (start_date, end_date)) {
            end_date = end_date.add_days (-1);
        }
    }

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
