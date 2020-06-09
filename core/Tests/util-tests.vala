void test_no_timezone () {
    var test_date = new GLib.DateTime.utc (2019, 11, 21, 4, 20, 0);
    var iso_string = test_date.format ("%FT%T");
    debug ("\t" + iso_string + "\n"); // 2019-11-21T04:20:00
    var test_ical = new ICal.Time.from_string (iso_string);
    debug ("\t" + test_ical.as_ical_string () + "\n"); // 20191121T042000
    // Should have null timezone
    assert (test_ical.get_timezone () == null);

    var util_timezone = Maya.Util.timezone_from_ical (test_ical);
    var abbreviation = util_timezone.get_abbreviation (0);
    debug ("\t" + abbreviation + "\n");
    assert (abbreviation == "UTC");
}

// Test that we recognize an actual UTC timezone
void test_utc () {
    var test_date = new GLib.DateTime.utc (2019, 11, 21, 4, 20, 0);
    var iso_string = test_date.format ("%FT%TZ");
    debug ("\t" + iso_string + "\n"); // 2019-11-21T04:20:00Z
    var test_ical = new ICal.Time.from_string (iso_string);
    debug ("\t" + test_ical.as_ical_string () + "\n"); // 20191121T042000Z

    // Should not have null timezone
    assert (test_ical.get_timezone () != null);

    GLib.TimeZone? util_timezone = Maya.Util.timezone_from_ical (test_ical);
    assert (util_timezone != null);
    var abbreviation = util_timezone.get_abbreviation (0);
    debug ("\t" + abbreviation + "\n");
    assert (abbreviation == "UTC");
}

// Test identifying a standard hour timezone (UTC offset is a complete hour)
void test_hour_offset () {
    var test_date = new GLib.DateTime.utc (2019, 11, 21, 9, 20, 0);
    var iso_string = test_date.format ("%FT%TZ");
    var test_ical = new ICal.Time.from_string (iso_string);
    assert (!test_ical.is_null_time ());
    var gtz = new GLib.TimeZone ("America/New_York");
    assert (gtz != null);
    var interval = gtz.find_interval (GLib.TimeType.STANDARD, test_date.to_unix ());

    unowned ICal.Timezone ical_tz = ICal.Timezone.get_builtin_timezone ("America/New_York");
    debug (ical_tz.get_display_name ());
    test_ical = test_ical.convert_to_zone (ical_tz);
    GLib.TimeZone? util_timezone = Maya.Util.timezone_from_ical (test_ical);
    assert (util_timezone != null);
    var test_interval = util_timezone.find_interval (GLib.TimeType.STANDARD, test_date.to_unix ());
    // assert (test_interval == interval);
    assert (util_timezone.get_offset (test_interval) == gtz.get_offset (interval));
    assert (util_timezone.get_abbreviation (test_interval) == "EST");
}

// Test identifying a timezone with a UTC offset of a half hour
void test_half_hour_offset () {
    var test_date = new GLib.DateTime.utc (2019, 11, 20, 18, 50, 0);
    var iso_string = test_date.format ("%FT%TZ");
    debug ("\n\tUTC time: " + iso_string + "\n");
    var test_ical = new ICal.Time.from_string (iso_string);
    assert (!test_ical.is_null_time ());
    var gtz = new GLib.TimeZone ("Australia/Darwin");
    assert (gtz != null);
    var interval = gtz.find_interval (GLib.TimeType.STANDARD, test_date.to_unix ());
    debug ("\tTimezone offset for ACST: " + (gtz.get_offset (interval) / 60.0 / 60).to_string () + "\n");

    var converted_gtime = test_date.to_timezone (gtz);
    debug ("\tTime in ACST: " + converted_gtime.format ("%FT%T%z") + "\n");
    assert (converted_gtime.format ("%FT%T%z") == "2019-11-21T04:20:00+0930");

    unowned ICal.Timezone ical_tz = ICal.Timezone.get_builtin_timezone ("Australia/Darwin");
    test_ical = test_ical.convert_to_zone (ical_tz);
    GLib.TimeZone? util_timezone = Maya.Util.timezone_from_ical (test_ical);
    assert (util_timezone != null);
    var test_interval = util_timezone.find_interval (GLib.TimeType.STANDARD, test_date.to_unix ());
    assert (test_interval == interval);
    assert (util_timezone.get_offset (test_interval) == gtz.get_offset (interval));
    assert (util_timezone.get_abbreviation (test_interval) == "ACST");
}

// Test identifying a timezone with a UTC offset of 45 minutes
void test_45_minute_offset () {
    var test_date = new GLib.DateTime.utc (2019, 11, 20, 22, 35, 0);
    var iso_string = test_date.format ("%FT%TZ");
    debug ("\n\tUTC time: " + iso_string + "\n");
    var test_ical = new ICal.Time.from_string (iso_string);
    assert (!test_ical.is_null_time ());
    var gtz = new GLib.TimeZone ("Asia/Kathmandu"); // UTC offset: +05:45
    assert (gtz != null);
    var interval = gtz.find_interval (GLib.TimeType.STANDARD, test_date.to_unix ());
    debug ("\tTimezone offset for Nepal Time: " + (gtz.get_offset (interval) / 60.0 / 60).to_string () + "\n");

    var converted_gtime = test_date.to_timezone (gtz);
    debug ("\tTime in Nepal Time: " + converted_gtime.format ("%FT%T%z") + "\n");
    assert (converted_gtime.format ("%FT%T%z") == "2019-11-21T04:20:00+0545");

    unowned ICal.Timezone ical_tz = ICal.Timezone.get_builtin_timezone ("Asia/Kathmandu");
    test_ical = test_ical.convert_to_zone (ical_tz);
    GLib.TimeZone? util_timezone = Maya.Util.timezone_from_ical (test_ical);
    assert (util_timezone != null);
    var test_interval = util_timezone.find_interval (GLib.TimeType.STANDARD, test_date.to_unix ());
    assert (test_interval == interval);
    assert (util_timezone.get_offset (test_interval) == gtz.get_offset (interval));
    assert (util_timezone.get_abbreviation (test_interval) == "+0545");
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

    var util_timezone = Maya.Util.timezone_from_ical (dtstart);
    var abbreviation = util_timezone.get_abbreviation (0);
    debug ("\t" + abbreviation + "\n");
    assert (abbreviation == "UTC");

    DateTime g_dtstart,g_dtend;
    Maya.Util.get_local_datetimes_from_icalcomponent (event, out g_dtstart, out g_dtend);
    assert (g_dtstart.format ("%FT%T%z") == "2019-11-21T00:00:00+0000");
    assert (g_dtend.format ("%FT%T%z") == "2019-11-21T00:00:00+0000");
}

void add_timezone_tests () {
    Test.add_func ("/Utils/TimeZone/no_timezone", test_no_timezone);
    Test.add_func ("/Utils/TimeZone/all_day", test_all_day);
    Test.add_func ("/Utils/TimeZone/utc", test_utc);
    Test.add_func ("/Utils/TimeZone/hour_offset", test_hour_offset);
    Test.add_func ("/Utils/TimeZone/half_hour_offset", test_half_hour_offset);
    Test.add_func ("/Utils/TimeZone/45_minute_offset", test_45_minute_offset);
}

int main (string[] args) {
    Test.init (ref args);
    add_timezone_tests ();
    return Test.run ();
}
