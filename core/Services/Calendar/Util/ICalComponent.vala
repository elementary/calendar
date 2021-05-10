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
     *  end of the given component.
     */
    public void icalcomponent_get_local_datetimes_old1 (ICal.Component component, out GLib.DateTime start_date, out GLib.DateTime end_date) {
        ICal.Time dt_start = component.get_dtstart ();
        ICal.Time dt_end = component.get_dtend ();

        if (dt_start.is_date ()) {
            // Don't convert timezone for date with only day info, leave it at midnight UTC
            start_date = Calendar.Util.icaltime_to_datetime1 (dt_start);
        } else {
            start_date = Calendar.Util.icaltime_to_datetime1 (dt_start).to_local ();
        }

        if (!dt_end.is_null_time ()) {
            if (dt_end.is_date ()) {
                // Don't convert timezone for date with only day info, leave it at midnight UTC
                end_date = Calendar.Util.icaltime_to_datetime1 (dt_end);
            } else {
                end_date = Calendar.Util.icaltime_to_datetime1 (dt_end).to_local ();
            }
        } else if (dt_start.is_date ()) {
            end_date = start_date;
        } else if (!component.get_duration ().is_null_duration ()) {
            end_date = Calendar.Util.icaltime_to_datetime1 (dt_start.add (component.get_duration ())).to_local ();
        } else {
            end_date = start_date.add_days (1);
        }
    }

    public void icalcomponent_get_local_datetimes_new (ICal.Component component, out GLib.DateTime start_date, out GLib.DateTime end_date) {
        ICal.Time dt_start = component.get_dtstart ();
        ICal.Time dt_end = component.get_dtend ();

        if (dt_end.is_null_time ()) {
            // Null time should never be returned if there's a duration
            assert (component.get_duration ().is_null_duration ());

            dt_end = dt_start.clone ();
            if (dt_start.is_date ()) { // Implicitly ends 1 day after start
                dt_end.adjust (1, 0, 0, 0);
            }
            // Otherwise implicitly ends at start date and time: do nothing
        }

        start_date = Calendar.Util.icaltime_to_local_datetime (dt_start);
        end_date = Calendar.Util.icaltime_to_local_datetime (dt_end);
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
        icalcomponent_get_local_datetimes_new (component, out start_date, out end_date);

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
        icalcomponent_get_local_datetimes_new (component, out start, out end);

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
