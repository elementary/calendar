// Create a testing subclass so we can access protected members and create
// multiple instances
class TestStore : Calendar.EventStore {
}

/**  Test interacting with nl_langinfo in Vala
 *
 * Interaction with POSIX NLTime (specifically nl_langinfo in C) in Vala is
 * hacky. Include a test to make sure that it still works the same, especially
 * since it depends very specifically on implementations of nl_langinfo and Vala
 * string handling, so could be prone to Vala changes.
 *
 * This test ensures that the values from nl_langinfo stay the same, and should
 * error out if Vala issues show up.
 */
void test_posix_nl_langinfo () {
    // Test en_GB (English, Great Britain), where the week starts on Monday
    // and week_1stday is 19971130 (Sunday)
    var localestr = "en_GB.utf8";
    var setstr = Intl.setlocale (LocaleCategory.TIME, localestr);
    assert (setstr != null);
    assert (setstr == localestr);
    uint week_day1 = (uint) Posix.NLTime.WEEK_1STDAY.to_string ();
    int first_weekday = Posix.NLTime.FIRST_WEEKDAY.to_string ().data[0];
    if (week_day1 != 19971130 || first_weekday != 2) {
        print ("\n\tRegion %s has unexpected LC_TIME values. Skipping direct nl_langinfo test.\n", localestr);
        Test.skip ();
    }

    // Test en_US (English, United States), where the week starts on Sunday
    //  and week_1stday is 19971130 (Sunday)
    localestr = "en_US.utf8";
    setstr = Intl.setlocale (LocaleCategory.TIME, localestr);
    assert (setstr != null);
    assert (setstr == localestr);
    week_day1 = (uint) Posix.NLTime.WEEK_1STDAY.to_string ();
    first_weekday = Posix.NLTime.FIRST_WEEKDAY.to_string ().data[0];
    if (week_day1 != 19971130 || first_weekday != 1) {
        print ("\n\tRegion %s has unexpected LC_TIME values. Skipping direct nl_langinfo test.\n", localestr);
        Test.skip ();
    }

    // Test ar_AE (Arabic, UAE), where the week starts on "Saturday"
    //  and week_1stday is 19971130 (Sunday)
    localestr = "ar_AE.utf8";
    setstr = Intl.setlocale (LocaleCategory.TIME, localestr);
    assert (setstr != null);
    assert (setstr == localestr);
    week_day1 = (uint) Posix.NLTime.WEEK_1STDAY.to_string ();
    first_weekday = Posix.NLTime.FIRST_WEEKDAY.to_string ().data[0];
    if (week_day1 != 19971130 || first_weekday != 7) {
        print ("\n\tRegion %s has unexpected LC_TIME values. Skipping direct nl_langinfo test.\n", localestr);
        Test.skip ();
    }
}

/** Test the get_week_start function in Calendar.EventStore
 */
void test_week_start () {
    // Test en_GB (English, Great Britain), where the week starts on Monday
    // and week_1stday is 19971130 (Sunday)
    var localestr = "en_GB.utf8";
    var setstr = Intl.setlocale (LocaleCategory.TIME, localestr);
    assert_nonnull (setstr);
    assert (setstr == localestr);
    var store = new TestStore ();
    var week_start = store.week_starts_on;
    assert (week_start == DateWeekday.MONDAY);

    // Test en_US (English, United States), where the week starts on Sunday
    //  and week_1stday is 19971130 (Sunday)
    localestr = "en_US.utf8";
    setstr = Intl.setlocale (LocaleCategory.TIME, localestr);
    assert_nonnull (setstr);
    assert (setstr == localestr);
    store = new TestStore ();
    week_start = store.week_starts_on;
    assert (week_start == DateWeekday.SUNDAY);

    // Test ar_AE (Arabic, UAE), where the week starts on "Saturday"
    //  and week_1stday is 19971130 (Sunday)
    localestr = "ar_AE.utf8";
    setstr = Intl.setlocale (LocaleCategory.TIME, localestr);
    assert_nonnull (setstr);
    assert (setstr == localestr);
    store = new TestStore ();
    week_start = store.week_starts_on;
    assert (week_start == DateWeekday.SATURDAY);
}

void test_ranges () {
    // EventStore.data_range depends on week start, so set en_GB (Monday)
    var localestr = "en_GB.utf8";
    var setstr = Intl.setlocale (LocaleCategory.TIME, localestr);
    assert_nonnull (setstr);
    assert (setstr == localestr);

    var store = new TestStore ();
    store.month_start = new GLib.DateTime.local (2020,11,1,0,0,0);
    var month_start = new GLib.DateTime.local (2020,11,1,12,13,45);
    var month_end = new GLib.DateTime.local (2020,11,30,12,13,45);
    // Test in range
    assert (month_start.compare (store.month_range.first_dt) >= 0);
    assert (month_end.compare (store.month_range.last_dt) <= 0);
    // Test out of range
    month_start = month_start.add_days (-1);
    month_end = month_end.add_days (1);
    assert (month_start.compare (store.month_range.first_dt) < 0);
    assert (month_end.compare (store.month_range.last_dt) > 0);

    var data_start = new GLib.DateTime.local (2020,10,26,12,13,45);
    var data_end = new GLib.DateTime.local (2020,12,6,12,13,45);
    assert (data_start.compare (store.data_range.first_dt) >= 0);
    assert (data_end.compare (store.data_range.last_dt) <= 0);
    // Test out of range
    data_start = data_start.add_days (-1);
    data_end = new GLib.DateTime.local (2020,12,7,0,0,1);
    assert (data_start.compare (store.data_range.first_dt) < 0);
    assert (data_end.compare (store.data_range.last_dt) > 0);
}

void add_locale_tests () {
    Test.add_func ("/EventStore/Locale/nl_langinfo", test_posix_nl_langinfo);
    Test.add_func ("/EventStore/Locale/week_start", test_week_start);
}

void add_range_tests () {
    Test.add_func ("/EventStore/Range/ranges", test_ranges);
}

int main (string[] args) {
    Test.init (ref args);
    add_locale_tests ();
    add_range_tests ();
    return Test.run ();
}
