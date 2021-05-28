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

string get_glib_tzid (TimeZone tz, DateTime time) {
    var interval = tz.find_interval (GLib.TimeType.STANDARD, time.to_unix ());
    return tz.get_abbreviation (interval);
}

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
    var abbreviation = get_glib_tzid (util_timezone, time);
    var abbreviation_old = util_timezone.get_abbreviation (interval);
    assert (abbreviation == abbreviation_old);
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

/*
 *
 * Tests for icaltime functions
 *
 */

void test_icaltime_convert_to_local () {
    // Test converting between some timezones
    var str = "20191121T092000";
    var tz = ICal.Timezone.get_builtin_timezone ("Asia/Kathmandu");
    assert (tz != null);
    var icaltime = new ICal.Time.from_string (str);
    icaltime.set_timezone (tz);
    // Converted to America/Chicago should be 20191120T213500
    var converted = Calendar.Util.icaltime_convert_to_local (icaltime);
    debug (converted.as_ical_string ());
    assert (converted.as_ical_string () == "20191120T213500");

    // Test a floating time: should stay the same when converted
    icaltime = new ICal.Time.from_string (str);
    assert (icaltime.get_timezone () == null); // Double check that it's floating
    converted = Calendar.Util.icaltime_convert_to_local (icaltime);
    debug (converted.as_ical_string ());
    assert (converted.as_ical_string () == str);
    assert (converted.get_timezone () != null);

    // Test an all-day event
    str = "20191121";
    icaltime = new ICal.Time.from_string (str);
    assert (icaltime.is_date ());
    assert (icaltime.get_timezone () == null); // DATE types should be floating
    converted = Calendar.Util.icaltime_convert_to_local (icaltime);
    debug (converted.as_ical_string ());
    assert (converted.as_ical_string () == str);
    assert (converted.is_date ());
    assert (converted.get_timezone () == null);
}

void test_icaltime_to_local_datetime () {
    // Test converting between some timezones
    var str = "20191121T092000";
    var tz = ICal.Timezone.get_builtin_timezone ("Asia/Kathmandu");
    assert (tz != null);
    var icaltime = new ICal.Time.from_string (str);
    icaltime.set_timezone (tz);
    // Converted to America/Chicago should be 20191120T213500
    var converted_ical = Calendar.Util.icaltime_convert_to_local (icaltime);
    var converted_glib = Calendar.Util.icaltime_to_local_datetime (icaltime);
    debug ("ICalTime converted to local: %s", converted_ical.as_ical_string ());
    debug ("icaltime_to_local_datetime: %s", converted_glib.format ("%FT%T"));
    assert (converted_ical.as_ical_string () == "20191120T213500");
    assert (converted_glib.format ("%FT%T") == "2019-11-20T21:35:00");
    debug (@"glib timezone: $(get_glib_tzid (converted_glib.get_timezone (), converted_glib))");
    debug (converted_glib.to_local ().format ("%FT%T"));
    assert (converted_glib.to_local ().format ("%FT%T") == "2019-11-20T21:35:00");

    // Test a floating time: should stay the same when converted
    icaltime = new ICal.Time.from_string (str);
    assert (icaltime.get_timezone () == null); // Double check that it's floating
    converted_ical = Calendar.Util.icaltime_convert_to_local (icaltime);
    converted_glib = Calendar.Util.icaltime_to_local_datetime (icaltime);
    debug ("Floating ICalTime converted to local: %s", converted_ical.as_ical_string ());
    debug ("Floating icaltime_to_local_datetime: %s", converted_glib.format ("%FT%T"));
    assert (converted_ical.as_ical_string () == str);
    assert (converted_ical.get_timezone () != null);
    assert (converted_glib.format ("%FT%T") == "2019-11-21T09:20:00");
    assert (converted_glib.to_local ().format ("%FT%T") == "2019-11-21T09:20:00");

    // Test an all-day event
    str = "20191121";
    icaltime = new ICal.Time.from_string (str);
    assert (icaltime.is_date ());
    assert (icaltime.get_timezone () == null); // DATE types should be floating
    converted_ical = Calendar.Util.icaltime_convert_to_local (icaltime);
    converted_glib = Calendar.Util.icaltime_to_local_datetime (icaltime);
    debug ("DATE type ICalTime converted to local: %s", converted_ical.as_ical_string ());
    debug ("DATE type icaltime_to_local_datetime: %s", converted_glib.format ("%FT%T"));
    assert (converted_ical.as_ical_string () == str);
    assert (converted_ical.is_date ());
    assert (converted_ical.get_timezone () == null);
    assert (converted_glib.format ("%FT%T") == "2019-11-21T00:00:00");
    // assert (converted_glib.get_timezone () == null)
    assert (converted_glib.to_local ().format ("%FT%T") == "2019-11-21T00:00:00");
}

/*
 *
 * Tests for icalcomponent functions
 *
 */

// Test all-day event: the ICal.Time will be DATE_TYPE and contain no time info.
// This should start and end at midnight local time.
void test_datetimes_all_day () {
    var str = "BEGIN:VEVENT\n" +
              "SUMMARY:Stub event\n" +
              "UID:example@uid\n" +
              "DTSTART;TZID=America/Chicago:20191121\n" +
              "DTEND;TZID=America/Chicago:20191122\n" +
              "END:VEVENT\n";
    var event = new ICal.Component.from_string (str);
    var dtstart = event.get_dtstart ();
    assert (dtstart.is_date ());

    DateTime g_dtstart,g_dtend;
    Calendar.Util.icalcomponent_get_local_datetimes (event, out g_dtstart, out g_dtend);

    // Check the timezone
    var util_timezone = Calendar.Util.icaltime_get_timezone (dtstart);
    var abbreviation = get_glib_tzid (util_timezone, g_dtstart);
    debug (@"Resulting timezone: $abbreviation");
    assert (abbreviation == "CST");

    assert (g_dtstart.format ("%FT%T%z") == "2019-11-21T00:00:00-0600");
    assert (g_dtend.format ("%FT%T%z") == "2019-11-22T00:00:00-0600");
}

// Test an event with a time that is local.
// The resulting times should contain the same hour, minute, second as
// the input and should not be converted.
void test_datetimes_not_all_day_local () {
    var str = "BEGIN:VEVENT\n" +
              "SUMMARY:Stub event\n" +
              "UID:example@uid\n" +
              "DTSTART;TZID=America/Chicago:20191121T042000\n" +
              "DTEND;TZID=America/Chicago:20191122T042000\n" +
              "END:VEVENT\n";
    var event = new ICal.Component.from_string (str);
    var dtstart = event.get_dtstart ();
    assert (!dtstart.is_date ());

    DateTime g_dtstart,g_dtend;
    Calendar.Util.icalcomponent_get_local_datetimes (event, out g_dtstart, out g_dtend);

    // Check the timezone
    var util_timezone = Calendar.Util.icaltime_get_timezone (dtstart);
    var abbreviation = get_glib_tzid (util_timezone, g_dtstart);
    debug (@"Resulting timezone: $abbreviation");
    assert (abbreviation == "CST");

    assert (g_dtstart.format ("%FT%T%z") == "2019-11-21T04:20:00-0600");
    assert (g_dtend.format ("%FT%T%z") == "2019-11-22T04:20:00-0600");
}

// Test an event with a time that must be converted.
// These time values should be converted properly.
void test_datetimes_not_all_day_converted () {
    var str = "BEGIN:VEVENT\n" +
              "SUMMARY:Stub event\n" +
              "UID:example@uid\n" +
              "DTSTART;TZID=Asia/Kathmandu:20191121T042000\n" +
              "DTEND;TZID=Asia/Kathmandu:20191122T042000\n" +
              "END:VEVENT\n";
    var event = new ICal.Component.from_string (str);
    var dtstart = event.get_dtstart ();
    assert (!dtstart.is_date ());

    DateTime g_dtstart,g_dtend;
    Calendar.Util.icalcomponent_get_local_datetimes (event, out g_dtstart, out g_dtend);

    assert (g_dtstart.format ("%FT%T%z") == "2019-11-20T16:35:00-0600");
    assert (g_dtend.format ("%FT%T%z") == "2019-11-21T16:35:00-0600");
}

void test_local_datetimes () {
    // DATE-type times: should start and end at midnight
    var str = "BEGIN:VEVENT\n" +
              "SUMMARY:Stub event\n" +
              "UID:example@uid\n" +
              "DTSTART;TZID=Asia/Kathmandu:20191121\n" +
              "DTEND;TZID=Asia/Kathmandu:20191122\n" +
              "END:VEVENT\n";
    var event = new ICal.Component.from_string (str);
    var dtstart = event.get_dtstart ();
    assert (dtstart.is_date ());
    DateTime g_dtstart,g_dtend;
    Calendar.Util.icalcomponent_get_local_datetimes (event, out g_dtstart, out g_dtend);
    debug (@"Start: $g_dtstart; End: $g_dtend");
    assert (Calendar.Util.datetime_is_all_day (g_dtstart, g_dtend));
    assert (g_dtstart.format ("%FT%T%z") == "2019-11-21T00:00:00-0600");
    assert (g_dtend.format ("%FT%T%z") == "2019-11-22T00:00:00-0600");

    // DATE-TIME-type times: should be converted to local timezone
    str = "BEGIN:VEVENT\n" +
              "SUMMARY:Stub event\n" +
              "UID:example@uid\n" +
              "DTSTART;TZID=Asia/Kathmandu:20191121T092000\n" +
              "DTEND;TZID=Asia/Kathmandu:20191122T183500\n" +
              "END:VEVENT\n";
    event = new ICal.Component.from_string (str);
    dtstart = event.get_dtstart ();
    Calendar.Util.icalcomponent_get_local_datetimes (event, out g_dtstart, out g_dtend);
    debug (@"Start: $g_dtstart; End: $g_dtend");
    assert (g_dtstart.format ("%FT%T%z") == "2019-11-20T21:35:00-0600");
    assert (g_dtend.format ("%FT%T%z") == "2019-11-22T06:50:00-0600");

    // No DTEND field for DATE-type DTSTART: implicitly 1 day long
    str = "BEGIN:VEVENT\n" +
              "SUMMARY:Stub event\n" +
              "UID:example@uid\n" +
              "DTSTART;TZID=Asia/Kathmandu:20191121\n" +
              "END:VEVENT\n";
    event = new ICal.Component.from_string (str);
    dtstart = event.get_dtstart ();
    Calendar.Util.icalcomponent_get_local_datetimes (event, out g_dtstart, out g_dtend);
    debug (@"Start: $g_dtstart; End: $g_dtend");
    assert (Calendar.Util.datetime_is_all_day (g_dtstart, g_dtend));
    assert (g_dtstart.format ("%FT%T%z") == "2019-11-21T00:00:00-0600");
    assert (g_dtend.format ("%FT%T%z") == "2019-11-22T00:00:00-0600");

    // No DTEND field for non-DATE-type DTSTART: ends at same time as start
    str = "BEGIN:VEVENT\n" +
              "SUMMARY:Stub event\n" +
              "UID:example@uid\n" +
              "DTSTART;TZID=Asia/Kathmandu:20191121T092000\n" +
              "END:VEVENT\n";
    event = new ICal.Component.from_string (str);
    dtstart = event.get_dtstart ();
    Calendar.Util.icalcomponent_get_local_datetimes (event, out g_dtstart, out g_dtend);
    debug (@"Start: $g_dtstart; End: $(g_dtend.format ("%FT%T%z"))");
    assert (g_dtstart.format ("%FT%T%z") == "2019-11-20T21:35:00-0600");
    assert (g_dtend.format ("%FT%T%z") == "2019-11-20T21:35:00-0600");
}

/*
 *
 * Tests for DateRange class
 *
 */

/** Basic test of DateRange.to_list: does it return only dates within the range?
 */
void test_daterange_to_list () {
    var start_time = new DateTime.local (2019, 11, 20, 0, 0, 0);
    var end_time = new DateTime.local (2019, 11, 22, 23, 59, 59);
    var range = new Calendar.Util.DateRange (start_time, end_time);
    var list = range.to_list ();
    var days_contained = 3;
    assert (list.size == days_contained);
    assert (start_time.compare (list.get (0)) == 0);
    assert (end_time.compare (list.get (list.size - 1).add_days (1)) < 0);
}

// Test that the is_event_in_range function works with all day events,
// which have no built-in time component from libical
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
    debug (@"Event: start $event_start; end $event_end");

    // A range that shouldn't include the event, but just barely (within
    // timezone offset)
    var start_time = new DateTime.local (2019, 11, 20, 0, 0, 0);
    var end_time = new DateTime.local (2019, 11, 20, 23, 59, 59);
    var range = new Calendar.Util.DateRange (start_time, end_time);
    // assert (!Calendar.Util.icalcomponent_is_in_range (event, range));
    // A range the should include the event
    end_time = new DateTime.local (2019, 11, 21, 0, 0, 1);
    range = new Calendar.Util.DateRange (start_time, end_time);
    // assert (Calendar.Util.icalcomponent_is_in_range (event, range));

    // A range that shouldn't include the event end, but just barely (within
    // timezone offset)
    start_time = new DateTime.local (2019, 11, 22, 0, 0, 1);
    end_time = new DateTime.local (2019, 11, 22, 12, 0, 0);
    range = new Calendar.Util.DateRange (start_time, end_time);
    assert (!Calendar.Util.icalcomponent_is_in_range (event, range));
    // A range the should include the event
    start_time = new DateTime.local (2019, 11, 21, 23, 59, 59);
    range = new Calendar.Util.DateRange (start_time, end_time);
    assert (Calendar.Util.icalcomponent_is_in_range (event, range));
}

// Test that the is_event_in_range function works with events that aren't
// all day and contain time information
void test_daterange_not_all_day () {
    var str = "BEGIN:VEVENT\n" +
              "SUMMARY:Stub event\n" +
              "UID:example@uid\n" +
              "DTSTART;TZID=America/Chicago:20191121T042000\n" +
              "DTEND;TZID=America/Chicago:20191122T042000\n" +
              "END:VEVENT\n";
    var event = new ICal.Component.from_string (str);

    // A range that shouldn't include the event, but just barely (within
    // timezone offset)
    var start_time = new DateTime.local (2019, 11, 20, 0, 0, 0);
    var end_time = new DateTime.local (2019, 11, 21, 4, 19, 59);
    var range = new Calendar.Util.DateRange (start_time, end_time);
    assert (!Calendar.Util.icalcomponent_is_in_range (event, range));
    // A range the should include the event
    end_time = new DateTime.local (2019, 11, 21, 4, 20, 1);
    range = new Calendar.Util.DateRange (start_time, end_time);
    assert (Calendar.Util.icalcomponent_is_in_range (event, range));
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

void test_datetimes_to_icaltime () {
    // Test floating timezone
    var date = new DateTime.utc (2019, 11, 21, 9, 20, 0);
    var time = new DateTime.utc (2019, 11, 21, 9, 20, 0);
    var test_icaltime = Calendar.Util.datetimes_to_icaltime (date, time, null);
    assert (test_icaltime.as_ical_string () == "20191121T092000");
    assert (test_icaltime.get_tzid () == null);

    // Check that system_timezone is what we want
    var system_tz = Calendar.TimeManager.get_default ().system_timezone;
    var system_tzid = system_tz.get_tzid ();
    assert (system_tzid == "America/Chicago" | system_tzid == "/freeassociation.sourceforge.net/America/Chicago");
    // Test implicit timezone
    date = new DateTime.utc (2019, 11, 21, 9, 20, 0);
    time = new DateTime.utc (2019, 11, 21, 9, 20, 0);
    test_icaltime = Calendar.Util.datetimes_to_icaltime (date, time);
    assert (test_icaltime.as_ical_string () == "20191121T092000");
    assert (test_icaltime.get_tzid () != null);
    assert (test_icaltime.get_tzid () == system_tzid );

    // Test explicit timezone
    date = new DateTime.utc (2019, 11, 21, 9, 20, 0);
    time = new DateTime.utc (2019, 11, 21, 9, 20, 0);
    var tz = ICal.Timezone.get_builtin_timezone ("Asia/Tokyo");
    debug (tz.get_tzid ());
    test_icaltime = Calendar.Util.datetimes_to_icaltime (date, time, tz);
    assert (test_icaltime.as_ical_string () == "20191121T092000");
    assert (test_icaltime.get_tzid () != null);
    assert (test_icaltime.get_tzid () == "Asia/Tokyo" || test_icaltime.get_tzid () == "/freeassociation.sourceforge.net/Asia/Tokyo");

    // Test that date and time are independent
    date = new DateTime.utc (2019, 11, 21, 0, 0, 0);
    time = new DateTime.utc (2397, 4, 13, 9, 20, 0);
    tz = ICal.Timezone.get_builtin_timezone ("Asia/Tokyo");
    debug (tz.get_tzid ());
    test_icaltime = Calendar.Util.datetimes_to_icaltime (date, time, tz);
    assert (test_icaltime.as_ical_string () == "20191121T092000");
    assert (test_icaltime.get_tzid () != null);
    assert (test_icaltime.get_tzid () == "Asia/Tokyo" || test_icaltime.get_tzid () == "/freeassociation.sourceforge.net/Asia/Tokyo");
}


void add_timezone_tests () {
    Test.add_func ("/Utils/TimeZone/floating", test_floating);
    Test.add_func ("/Utils/TimeZone/utc", test_utc);
    Test.add_func ("/Utils/TimeZone/hour_offset", test_hour_offset);
    Test.add_func ("/Utils/TimeZone/half_hour_offset", test_half_hour_offset);
    Test.add_func ("/Utils/TimeZone/45_minute_offset", test_45_minute_offset);
}

void add_icaltime_tests () {
    Test.add_func ("/Utils/ICalTime/convert_to_local", test_icaltime_convert_to_local);
    Test.add_func ("/Utils/ICalTime/icaltime_as_local_datetime", test_icaltime_to_local_datetime);
    Test.add_func ("/Utils/ICalTime/get_local_datetimes", test_local_datetimes);
}

void add_icalcomponent_tests () {
    Test.add_func ("/Utils/ICalComponent/all_day", test_datetimes_all_day);
    Test.add_func ("/Utils/ICalComponent/not_all_day_local", test_datetimes_not_all_day_local);
    Test.add_func ("/Utils/ICalComponent/not_all_day_converted", test_datetimes_not_all_day_converted);
}

void add_daterange_tests () {
    Test.add_func ("/Utils/DateRange/to_list", test_daterange_to_list);
    Test.add_func ("/Utils/DateRange/all_day", test_daterange_all_day);
    Test.add_func ("/Utils/DateRange/not_all_day", test_daterange_not_all_day);
}

void add_datetime_tests () {
    Test.add_func ("/Utils/DateTime/is_all_day_false", test_is_all_day_false);
    Test.add_func ("/Utils/DateTime/is_all_day_true", test_is_all_day_true);
    Test.add_func ("/Utils/DateTime/datetimes_to_icaltime", test_datetimes_to_icaltime);
}

int main (string[] args) {
    print ("\n");
    var original_tz = Environment.get_variable ("TZ");
    Environment.set_variable ("TZ", "America/Chicago", true);
    print ("Setting $TZ environment variable: " + Environment.get_variable ("TZ") + "\n");
    ICal.Timezone tz = ICal.Timezone.get_builtin_timezone ("America/Chicago");
    Calendar.TimeManager.setup_test (tz);
    print ("Setting up TimeManager with system timezone America/Chicago");
    print ("Starting utils tests:\n");

    Test.init (ref args);
    add_timezone_tests ();
    add_icaltime_tests ();
    add_icalcomponent_tests ();
    add_daterange_tests ();
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
