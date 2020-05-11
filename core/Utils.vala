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

namespace Maya.Util {

    public int compare_events (ECal.Component comp1, ECal.Component comp2) {
        var res = comp1.get_icalcomponent ().get_dtstart ().compare (comp2.get_icalcomponent ().get_dtstart ());
        if (res != 0)
            return res;

        // If they have the same date, sort them alphabetically
        return comp1.get_summary ().get_value ().collate (comp2.get_summary ().get_value ());
    }

    //--- Date and Time ---//


    /**
     * Converts two datetimes to one TimeType. The first contains the date,
     * its time settings are ignored. The second one contains the time itself.
     */
    public ICal.Time date_time_to_ical (DateTime date, DateTime? time_local, string? timezone = null) {
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
     * Gets the timezone of the given TimeType as a GLib.TimeZone.
     */
    private TimeZone timezone_from_ical (ICal.Time date) {
        // Special case: return default UTC time zone for all-day events
        if (date.is_date ()) {
            debug ("Given date is 'DATE' type, not 'DATE_TIME': Using timezone UTC");
            return new TimeZone.utc ();
        }

        // Otherwise, get timezone from ICal
        unowned ICal.Timezone? timezone = null;
        var tzid = date.get_tzid ();
        // First, try using the tzid property
        if (tzid != null) {
            unowned ICal.Timezone? tzid_zone;
            if (tzid.has_prefix ("/freeassociation.sourceforge.net/")) {
                // TZID has prefix "/freeassociation.sourceforge.net/",
                // indicating a libical TZID.
                tzid_zone = ICal.Timezone.get_builtin_timezone_from_tzid (tzid);
            } else {
                // TZID does not have libical prefix, indicating an Olson
                // standard city name.
                tzid_zone = ICal.Timezone.get_builtin_timezone (tzid);
            }
            if (tzid_zone != null) {
                timezone = tzid_zone;
            } else {
                debug ("Error parsing timezone from TZID: trying fallback");
            }
        }
        // If tzid fails, try date.get_timezone ()
        if (timezone == null && date.get_timezone () != null) {
            timezone = date.get_timezone ();
        }
        // If nothing else works (timezone is still null), default to UTC
        if (timezone == null) {
            debug ("Date has no timezone info: defaulting to UTC");
            return new TimeZone.utc ();
        }

        // Get UTC offset and format for GLib.TimeZone constructor
        int is_daylight;
        int interval = timezone.get_utc_offset (date, out is_daylight);
        bool is_positive = interval >= 0;
        interval = interval.abs ();
        var hours = (interval / 3600);
        var minutes = (interval % 3600) / 60;
        var hour_string = "%s%02d:%02d".printf (is_positive ? "+" : "-", hours, minutes);

        return new TimeZone (hour_string);
    }

    /**
     * Converts the given TimeType to a DateTime.
     * XXX : Track next versions of evolution in order to convert ICal.Timezone to GLib.TimeZone with a dedicated function…
     */
    public DateTime ical_to_date_time (ICal.Time date) {
#if E_CAL_2_0
        int year, month, day, hour, minute, second;
        date.get_date (out year, out month, out day);
        date.get_time (out hour, out minute, out second);
        return new DateTime (timezone_from_ical (date), year, month,
            day, hour, minute, second);
#else
        return new DateTime (timezone_from_ical (date), date.year, date.month,
            date.day, date.hour, date.minute, date.second);
#endif
    }

    public void get_local_datetimes_from_icalcomponent (ICal.Component comp, out DateTime start_date, out DateTime end_date) {
        ICal.Time dt_start = comp.get_dtstart ();
        ICal.Time dt_end = comp.get_dtend ();

        if (dt_start.is_date ()) {
            // Don't convert timezone for date with only day info, leave it at midnight UTC
            start_date = Util.ical_to_date_time (dt_start);
        } else {
            start_date = Util.ical_to_date_time (dt_start).to_local ();
        }

        if (!dt_end.is_null_time ()) {
            if (dt_end.is_date ()) {
                // Don't convert timezone for date with only day info, leave it at midnight UTC
                end_date = Util.ical_to_date_time (dt_end);
            } else {
                end_date = Util.ical_to_date_time (dt_end).to_local ();
            }
        } else if (dt_start.is_date ()) {
            end_date = start_date;
        } else if (!comp.get_duration ().is_null_duration ()) {
            end_date = Util.ical_to_date_time (dt_start.add (comp.get_duration ())).to_local ();
        } else {
            end_date = start_date.add_days (1);
        }

        if (is_all_day (start_date, end_date)) {
            end_date = end_date.add_days (-1);
        }
    }

    public bool is_event_in_range (ICal.Component comp, Util.DateRange view_range) {
        DateTime start, end;
        get_local_datetimes_from_icalcomponent (comp, out start, out end);

        int c1 = start.compare (view_range.first_dt);
        int c2 = start.compare (view_range.last_dt);
        int c3 = end.compare (view_range.first_dt);
        int c4 = end.compare (view_range.last_dt);

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

    public bool is_multiday_event (ICal.Component comp) {
        DateTime start, end;
        get_local_datetimes_from_icalcomponent (comp, out start, out end);

        if (start.get_year () != end.get_year () || start.get_day_of_year () != end.get_day_of_year ())
            return true;

        return false;
    }

    /**
     * Say if an event lasts all day.
     */
    public bool is_all_day (DateTime dtstart, DateTime dtend) {
        var utc_start = dtstart.to_timezone (new TimeZone.utc ());
        var timespan = dtend.difference (dtstart);
        if (timespan % GLib.TimeSpan.DAY == 0 && utc_start.get_hour () == 0) {
            return true;
        } else {
            return false;
        }
    }

    public DateTime get_start_of_month (owned DateTime? date = null) {
        if (date == null)
            date = new DateTime.now_local ();

        return new DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
    }

    public DateTime strip_time (DateTime datetime) {
        return datetime.add_full (0, 0, 0, -datetime.get_hour (), -datetime.get_minute (), -datetime.get_second ());
    }

    /*
     * Gee Utility Functions
     */

    /* Computes hash value for E.Source */
    private uint source_hash_func (E.Source key) {
        return key.dup_uid (). hash ();
    }

    /* Returns true if 'a' and 'b' are the same GLib.DateTime */
    private bool datetime_equal_func (DateTime a, DateTime b) {
        return a.equal (b);
    }

    /* Returns true if 'a' and 'b' are the same ECal.Component */
    private bool calcomponent_equal_func (ECal.Component a, ECal.Component b) {
        return a.get_id ().equal (b.get_id ());
    }

    public int calcomponent_compare_func (ECal.Component? a, ECal.Component? b) {
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

    public bool calcomp_is_on_day (ECal.Component comp, GLib.DateTime day) {
#if E_CAL_2_0
        unowned ICal.Timezone system_timezone = ECal.util_get_system_timezone ();
#else
        unowned ICal.Timezone system_timezone = ECal.Util.get_system_timezone ();
#endif

        var stripped_time = new DateTime.local (day.get_year (), day.get_month (), day.get_day_of_month (), 0, 0, 0);

        var selected_date_unix = stripped_time.to_unix ();
        var selected_date_unix_next = stripped_time.add_days (1).to_unix ();

        /* We want to be relative to the local timezone */
        unowned ICal.Component? icomp = comp.get_icalcomponent ();
        ICal.Time? start_time = icomp.get_dtstart ();
        ICal.Time? end_time = icomp.get_dtend ();
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

    /* Returns true if 'a' and 'b' are the same E.Source */
    private bool source_equal_func (E.Source a, E.Source b) {
        return a.get_uid () == b.get_uid ();
    }

    /*
     * E.Source Utils
     */
    public string get_source_location (E.Source source) {
        var registry = Maya.Model.CalendarModel.get_default ().registry;
        string parent_uid = source.parent;
        E.Source parent_source = source;
        while (parent_source != null) {
            parent_uid = parent_source.parent;

            if (parent_source.has_extension (E.SOURCE_EXTENSION_AUTHENTICATION)) {
                var collection = (E.SourceAuthentication)parent_source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
                if (collection.user != null) {
                    return collection.user;
                }
            }

            if (parent_source.has_extension (E.SOURCE_EXTENSION_COLLECTION)) {
                var collection = (E.SourceCollection)parent_source.get_extension (E.SOURCE_EXTENSION_COLLECTION);
                if (collection.identity != null) {
                    return collection.identity;
                }
            }

            if (parent_uid == null)
                break;

            parent_source = registry.ref_source (parent_uid);
        }

        return _("On this computer");
    }

    /*
     * ical Exportation
     */

    public void save_temp_selected_calendars () {
        var calmodel = Model.CalendarModel.get_default ();
        var events = calmodel.get_events ();
        var builder = new StringBuilder ();
        builder.append ("BEGIN:VCALENDAR\n");
        builder.append ("VERSION:2.0\n");
        foreach (ECal.Component event in events) {
            builder.append (event.get_as_string ());
        }
        builder.append ("END:VCALENDAR");

        string file_path = GLib.Environment.get_tmp_dir () + "/calendar.ics";
        try {
            var file = File.new_for_path (file_path);
            file.replace_contents (builder.data, null, false, FileCreateFlags.REPLACE_DESTINATION, null);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }
}
