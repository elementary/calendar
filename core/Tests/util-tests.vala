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

/*
 *
 * Tests for timezone functions
 *
 */

void test_timezone_expected (DateTime time, ICal.Time ical,
    bool icalzone_is_null, GLib.TimeZone asserted_zone, string asserted_abbreviation) {


    debug (@"Testing time: $(ical.as_ical_string ())");
    if (icalzone_is_null) {
        assert (ical.get_timezone () == null);
        assert (ical.get_tzid () == null);
    } else {
        assert (ical.get_timezone () != null);
        assert (ical.get_tzid () != null);
    }

    var util_timezone = Calendar.Util.icaltime_get_timezone (ical);
    var interval = util_timezone.find_interval (GLib.TimeType.STANDARD, time.to_unix ());
    var abbreviation = util_timezone.get_abbreviation (interval);
    debug (@"Resulting GLib.TimeZone: $abbreviation");
    assert (abbreviation == asserted_abbreviation);
    assert (util_timezone.get_offset (interval) == asserted_zone.get_offset (interval));
}

void test_floating () {
    var test_date = new GLib.DateTime.local (2019, 11, 21, 4, 20, 0);
    var iso_string = test_date.format ("%FT%T");
    var ical = new ICal.Time.from_string (iso_string);
    var asserted_zone = new GLib.TimeZone.local ();
    test_timezone_expected (test_date, ical, true, asserted_zone, "CST");
}

// Test that we recognize a UTC timezone
void test_utc () {
    var test_date = new GLib.DateTime.utc (2019, 11, 21, 4, 20, 0);
    var iso_string = test_date.format ("%FT%TZ");
    var ical = new ICal.Time.from_string (iso_string);
    var asserted_zone = new GLib.TimeZone.utc ();
    test_timezone_expected (test_date, ical, false, asserted_zone, "UTC");
}

void test_sample_offsets (string tzid, string abbreviation) {
    // Setup basic time info
    var test_date = new GLib.DateTime.utc (2019, 11, 21, 9, 20, 0);
    var iso_string = test_date.format ("%FT%TZ");
    var asserted_zone = new GLib.TimeZone (tzid);
    unowned ICal.Timezone ical_tz = ICal.Timezone.get_builtin_timezone (tzid);
    assert (ical_tz != null);

    // Convert to a timezone to test
    var ical = new ICal.Time.from_string (iso_string).convert_to_zone (ical_tz);
    var converted_gtime = test_date.to_timezone (asserted_zone);

    test_timezone_expected (converted_gtime, ical, false, asserted_zone, abbreviation);
}

// Test identifying a standard hour timezone (UTC offset is a complete hour)
void test_hour_offset () {
    test_sample_offsets ("America/New_York", "EST");
}

// Test identifying a timezone with a UTC offset of a half hour
void test_half_hour_offset () {
    test_sample_offsets ("Australia/Darwin", "ACST");
}

// Test identifying a timezone with a UTC offset of 45 minutes
void test_45_minute_offset () {
    test_sample_offsets ("Asia/Kathmandu", "+0545");
}

// Test all-day event: the ICal.Time will be DATE_TYPE and contain no type info.
// Should keep this in UTC.
// Also make sure that it starts and ends at the proper times (midnight).
void test_all_day () {
    var str = "BEGIN:VEVENT\n" +
              "SUMMARY:Stub event\n" +
              "UID:example@uid\n" +
              "DTSTART;TZID=America/Chicago:20191121\n" +
              "DTEND;TZID=America/Chicago:20191122\n" +
              "END:VEVENT\n";
    var event = new ICal.Component.from_string (str);
    var dtstart = event.get_dtstart ();
    assert (dtstart.is_date ());
    debug ("\t" + dtstart.as_ical_string () + "\n"); // 20191121

    var util_timezone = Calendar.Util.icaltime_get_timezone (dtstart);
    var abbreviation = util_timezone.get_abbreviation (0);
    debug ("\t" + abbreviation + "\n");

    DateTime g_dtstart,g_dtend;
    Calendar.Util.icalcomponent_get_local_datetimes (event, out g_dtstart, out g_dtend);
    assert (g_dtstart.format ("%FT%T%z") == "2019-11-21T00:00:00-0600");
    assert (g_dtend.format ("%FT%T%z") == "2019-11-21T00:00:00-0600");
}

// Test that the is_event_in_range function works with all day events, which are
// in UTC instead of local time
void test_daterange_all_day () {
    var str = "BEGIN:VEVENT\n" +
              "SUMMARY:Stub event\n" +
              "UID:example@uid\n" +
              "DTSTART;TZID=America/Chicago:20191121\n" +
              "DTEND;TZID=America/Chicago:20191122\n" +
              "END:VEVENT\n";
    var event = new ICal.Component.from_string (str);

    GLib.DateTime event_start, event_end;
    Calendar.Util.icalcomponent_get_local_datetimes (event, out event_start, out event_end);
    debug (@"Start: $event_start; End: $event_end");

    // A range that shouldn't include the event, but just barely (within
    // timezone offset)
    var start_time = new DateTime.local (2019, 11, 20, 0, 0, 0);
    var end_time = new DateTime.local (2019, 11, 20, 23, 59, 59);
    var range = new Calendar.Util.DateRange (start_time, end_time);
    assert (!Calendar.Util.icalcomponent_is_in_range (event, range));
    // A range the should include the event
    end_time = new DateTime.local (2019, 11, 21, 0, 0, 1);
    range = new Calendar.Util.DateRange (start_time, end_time);
    assert (Calendar.Util.icalcomponent_is_in_range (event, range));
}

/** Test that we properly identify all-day events */
void test_is_all_day_true () {
    var str = "BEGIN:VEVENT\n" +
              "SUMMARY:Stub event\n" +
              "UID:example@uid\n" +
              "DTSTART;TZID=America/Chicago:20191121\n" +
              "DTEND;TZID=America/Chicago:20191122\n" +
              "END:VEVENT\n";
    var event = new ICal.Component.from_string (str);
    assert (event.get_dtstart ().is_date ());
    assert (event.get_dtend ().is_date ());

    GLib.DateTime dtstart, dtend;
    Calendar.Util.icalcomponent_get_local_datetimes (event, out dtstart, out dtend);
    assert (Calendar.Util.datetime_is_all_day (dtstart, dtend));
}

/*
 *
 * Tests for DateTime
 *
 */

/** Test that we properly identify non-all-day events */
void test_is_all_day_false () {
    var str = "BEGIN:VEVENT\n" +
              "SUMMARY:Stub event\n" +
              "UID:example@uid\n" +
              "DTSTART;TZID=America/Chicago:20191121\n" +
              "DTEND;TZID=America/Chicago:20191122\n" +
              "END:VEVENT\n";
    var event = new ICal.Component.from_string (str);
    assert (event.get_dtstart ().is_date ());
    assert (event.get_dtend ().is_date ());

    GLib.DateTime dtstart, dtend;
    Calendar.Util.icalcomponent_get_local_datetimes (event, out dtstart, out dtend);
    assert (Calendar.Util.datetime_is_all_day (dtstart, dtend));
}

void add_timezone_tests () {
    Test.add_func ("/Utils/TimeZone/floating", test_floating);
    Test.add_func ("/Utils/TimeZone/all_day", test_all_day);
    Test.add_func ("/Utils/TimeZone/utc", test_utc);
    Test.add_func ("/Utils/TimeZone/hour_offset", test_hour_offset);
    Test.add_func ("/Utils/TimeZone/half_hour_offset", test_half_hour_offset);
    Test.add_func ("/Utils/TimeZone/45_minute_offset", test_45_minute_offset);

    Test.add_func ("/Utils/DateRange/all_day", test_daterange_all_day);
}

void add_datetime_tests () {
    Test.add_func ("/Utils/DateTime/is_all_day_false", test_is_all_day_false);
    Test.add_func ("/Utils/DateTime/is_all_day_true", test_is_all_day_true);
}

int main (string[] args) {
    print ("\n");
    var original_tz = Environment.get_variable ("TZ");
    Environment.set_variable ("TZ", "America/Chicago", true);
    print ("Setting $TZ environment variable: " + Environment.get_variable ("TZ") + "\n");
    print ("Starting utils tests:\n");

    Test.init (ref args);
    add_timezone_tests ();
    add_datetime_tests ();
    var result = Test.run ();

    if (original_tz != null) {
        Environment.set_variable ("TZ", original_tz, true);
    } else {
        Environment.unset_variable ("TZ");
    }
    print ("Resetting $TZ environment variable after testing\n");
    return result;
}
