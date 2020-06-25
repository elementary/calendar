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

    //--- GLib.DateTime Helpers ---//

    public GLib.DateTime datetime_get_start_of_month (owned GLib.DateTime? date = null) {
        if (date == null) {
            date = new GLib.DateTime.now_local ();
        }

        return new GLib.DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
    }

    public GLib.DateTime datetime_strip_time (GLib.DateTime datetime) {
        return datetime.add_full (0, 0, 0, -datetime.get_hour (), -datetime.get_minute (), -datetime.get_second ());
    }

    /**
     * Converts two datetimes to one TimeType. The first contains the date,
     * its time settings are ignored. The second one contains the time itself.
     */
    public ICal.Time datetimes_to_icaltime (GLib.DateTime date, GLib.DateTime? time_local, string? timezone = null) {
#if E_CAL_2_0
        var result = new ICal.Time.from_day_of_year (date.get_day_of_year (), date.get_year ());
#else
        var result = ICal.Time.from_day_of_year (date.get_day_of_year (), date.get_year ());
#endif
        if (time_local != null) {
            if (timezone != null) {
#if E_CAL_2_0
                result.set_timezone (ICal.Timezone.get_builtin_timezone (timezone));
#else
                result.zone = ICal.Timezone.get_builtin_timezone (timezone);
#endif
            } else {
#if E_CAL_2_0
                result.set_timezone (ECal.util_get_system_timezone ());
#else
                result.zone = ECal.Util.get_system_timezone ();
#endif
            }

#if E_CAL_2_0
            result.set_is_date (false);
            result.set_time (time_local.get_hour (), time_local.get_minute (), time_local.get_second ());
#else
            result._is_date = 0;
            result.hour = time_local.get_hour ();
            result.minute = time_local.get_minute ();
            result.second = time_local.get_second ();
#endif
        } else {
#if E_CAL_2_0
            result.set_is_date (true);
            result.set_time (0, 0, 0);
#else
            result._is_date = 1;
            result.hour = 0;
            result.minute = 0;
            result.second = 0;
#endif
        }

        return result;
    }

    /**
     * Say if an event lasts all day.
     */
    public bool datetime_is_all_day (GLib.DateTime dtstart, GLib.DateTime dtend) {
        var utc_start = dtstart.to_timezone (new TimeZone.utc ());
        var timespan = dtend.difference (dtstart);

        if (timespan % GLib.TimeSpan.DAY == 0 && utc_start.get_hour () == 0) {
            return true;
        } else {
            return false;
        }
    }

    //--- ICal.Time Helpers ---//

    /**
     * Converts the given ICal.Time to a DateTime.
     */
    public TimeZone icaltime_get_timezone (ICal.Time date) {
        int is_daylight;
        var interval = date.get_timezone ().get_utc_offset (null, out is_daylight);
        bool is_positive = interval >= 0;
        interval = interval.abs ();
        var hours = (interval / 3600);
        var minutes = (interval % 3600) / 60;
        var hour_string = "%s%02d:%02d".printf (is_positive ? "+" : "-", hours, minutes);

        return new TimeZone (hour_string);
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

    //--- E.Source Helpers ---//

    /* Returns true if 'a' and 'b' are the same E.Source */
    public bool source_equal_func (E.Source a, E.Source b) {
        return a.get_uid () == b.get_uid ();
    }

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
#if E_CAL_2_0
        unowned ICal.Timezone system_timezone = ECal.util_get_system_timezone ();
#else
        unowned ICal.Timezone system_timezone = ECal.Util.get_system_timezone ();
#endif
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

    //--- ICal.Component Helpers ---//

    public void icalcomponent_get_local_datetimes (ICal.Component component, out GLib.DateTime start_date, out GLib.DateTime end_date) {
        ICal.Time dt_start = component.get_dtstart ();
        ICal.Time dt_end = component.get_dtend ();
        start_date = Calendar.Util.icaltime_to_datetime (dt_start);

        if (!dt_end.is_null_time ()) {
            end_date = Calendar.Util.icaltime_to_datetime (dt_end);
        } else if (dt_start.is_date ()) {
            end_date = start_date;
        } else if (!component.get_duration ().is_null_duration ()) {
            end_date = Calendar.Util.icaltime_to_datetime (dt_start.add (component.get_duration ()));
        } else {
            end_date = start_date.add_days (1);
        }

        if (Calendar.Util.datetime_is_all_day (start_date, end_date)) {
            end_date = end_date.add_days (-1);
        }
    }

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

    public bool icalcomponent_is_multiday (ICal.Component comp) {
        GLib.DateTime start, end;
        icalcomponent_get_local_datetimes (comp, out start, out end);

        if (start.get_year () != end.get_year () || start.get_day_of_year () != end.get_day_of_year ())
            return true;

        return false;
    }
}
