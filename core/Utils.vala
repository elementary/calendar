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

    public int compare_events (E.CalComponent comp1, E.CalComponent comp2) {

        var date1 = Util.ical_to_date_time (comp1.get_icalcomponent ().get_dtstart ());
        var date2 = Util.ical_to_date_time (comp2.get_icalcomponent ().get_dtstart ());

        if (date1.compare (date2) != 0)
            return date1.compare(date2);

        // If they have the same date, sort them alphabetically
        var summary1 = comp1.get_summary ();
        var summary2 = comp2.get_summary ();

        if (summary1.value < summary2.value)
            return -1;
        if (summary1.value > summary2.value)
            return 1;
        return 0;
    }

    //--- Date and Time ---//


    /**
     * Converts two datetimes to one TimeType. The first contains the date,
     * its time settings are ignored. The second one contains the time itself.
     * XXX: We need to convert to UTC because of some bugs with the Google backend…
     */
    public iCal.TimeType date_time_to_ical (DateTime date, DateTime? time_local, string? timezone = E.Util.get_system_timezone_location ()) {
        var result = iCal.TimeType.from_day_of_year (date.get_day_of_year (), date.get_year ());
        if (time_local != null) {
            unowned iCal.Array<unowned iCal.TimeZone> tzs = iCal.TimeZone.get_builtin_timezones ();
            for (int i = 0; i<tzs.num_elements; i++) {
                unowned iCal.TimeZone tz = tzs.element_at (i);
                if (tz.get_display_name () == timezone) {
                    result.zone = tz;
                    break;
                }
            }

            result.is_date = 0;
            result.hour = time_local.get_hour ();
            result.minute = time_local.get_minute ();
            result.second = time_local.get_second ();
        } else {
            result.is_date = 1;
            result.hour = 0;
            result.minute = 0;
            result.second = 0;
        }

        return result;
    }

    /**
     * Converts the given TimeType to a DateTime.
     */
    public TimeZone timezone_from_ical (iCal.TimeType date) {
        var interval = date.zone.get_utc_offset (date, date.is_daylight);
        var hours = (interval / 3600);
        string hour_string = "-";
        if (hours >= 0) {
            hour_string = "+";
        }

        hours = hours.abs();
        if (hours > 9) {
            hour_string = "%s%d".printf (hour_string, hours);
        } else {
            hour_string = "%s0%d".printf (hour_string, hours);
        }

        var minutes = (interval.abs () % 3600)/60;
        if (minutes > 9) {
            hour_string = "%s:%d".printf (hour_string, minutes);
        } else {
            hour_string = "%s:0%d".printf (hour_string, minutes);
        }

        return new TimeZone (hour_string);
    }

    /**
     * Converts the given TimeType to a DateTime.
     * XXX : Track next versions of evolution in order to convert iCal.Timezone to GLib.TimeZone with a dedicated function…
     */
    public DateTime ical_to_date_time (iCal.TimeType date) {
        return new DateTime (timezone_from_ical (date), date.year, date.month,
            date.day, date.hour, date.minute, date.second);
    }

    public void get_local_datetimes_from_icalcomponent (iCal.Component comp, out DateTime start_date, out DateTime end_date) {
        iCal.TimeType dt_start = comp.get_dtstart ();
        iCal.TimeType dt_end = comp.get_dtend ();

        start_date = Util.ical_to_date_time (dt_start);
        end_date = Util.ical_to_date_time (dt_end);
    }

    public bool is_event_in_range (iCal.Component comp, Util.DateRange view_range) {
        var start = ical_to_date_time (comp.get_dtstart ());
        var end = ical_to_date_time (comp.get_dtend ());

        bool allday = is_all_day (start, end);
        if (allday) {
            end = end.add_days (-1);
            var interval = (new DateTime.now_local ()).get_utc_offset ();
            start = start.add (-interval);
            end = end.add (-interval);  
        }

        int c1 = start.compare (view_range.first);
        int c2 = start.compare (view_range.last);
        int c3 = end.compare (view_range.first);
        int c4 = end.compare (view_range.last);

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

    public Gee.Collection<DateRange> event_date_ranges (iCal.Component comp, Util.DateRange view_range) {
        var dateranges = new Gee.LinkedList<DateRange> ();

        var start = ical_to_date_time (comp.get_dtstart ());
        var end = ical_to_date_time (comp.get_dtend ());
        if (end == null) end = start;

        // All days events are stored in UTC time and should only being shown at one day.
        bool allday = is_all_day (start, end);
        if (allday) {
            end = end.add_days (-1);
        }

        start = strip_time (start);
        end = strip_time (end);
        dateranges.add (new Util.DateRange (start, end));

        // Search for recursive events.
        unowned iCal.Property property = comp.get_first_property (iCal.PropertyKind.RRULE);
        if (property != null) {
            var rrule = property.get_rrule ();
            switch (rrule.freq) {
                case (iCal.RecurrenceTypeFrequency.WEEKLY):
                    generate_week_reccurence (dateranges, view_range, rrule, start, end);
                    break;
                case (iCal.RecurrenceTypeFrequency.MONTHLY):
                    generate_month_reccurence (dateranges, view_range, rrule, start, end);
                    break;
                case (iCal.RecurrenceTypeFrequency.YEARLY):
                    generate_year_reccurence (dateranges, view_range, rrule, start, end);
                    break;
                default:
                    generate_day_reccurence (dateranges, view_range, rrule, start, end);
                    break;
            }
        }

        // EXDATEs elements are exceptions dates that should not appear.
        property = comp.get_first_property (iCal.PropertyKind.EXDATE);
        while (property != null) {
            var exdate = property.get_exdate ();
            var date = ical_to_date_time (exdate);
            dateranges.@foreach ((daterange) => {
                var first = daterange.first;
                var last = daterange.last;
                if (first.get_year () <= date.get_year () && last.get_year () >= date.get_year ()) {
                    if (first.get_day_of_year () <= date.get_day_of_year () && last.get_day_of_year () >= date.get_day_of_year ()) {
                        dateranges.remove (daterange);
                        return false;
                    }
                }

                return true;
            });

            property = comp.get_next_property (iCal.PropertyKind.EXDATE);
        }

        return dateranges;
    }

    private void generate_day_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                           iCal.RecurrenceType rrule, DateTime start, DateTime end) {
        if (rrule.until.is_null_time () == 0) {
            for (int i = 1; i <= (int)(rrule.until.day/rrule.interval); i++) {
                int n = i*rrule.interval;
                if (view_range.contains (start.add_days (n)) || view_range.contains (end.add_days (n)))
                    dateranges.add (new Util.DateRange (start.add_days (n), end.add_days (n)));
            }
        } else if (rrule.count > 0) {
            for (int i = 1; i<=rrule.count; i++) {
                int n = i*rrule.interval;
                if (view_range.contains (start.add_days (n)) || view_range.contains (end.add_days (n)))
                    dateranges.add (new Util.DateRange (start.add_days (n), end.add_days (n)));
            }
        } else {
            int i = 1;
            int n = i*rrule.interval;
            while (view_range.last.compare (start.add_days (n)) > 0) {
                dateranges.add (new Util.DateRange (start.add_days (n), end.add_days (n)));
                i++;
                n = i*rrule.interval;
            }
        }
    }

    private void generate_year_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                           iCal.RecurrenceType rrule, DateTime start, DateTime end) {
        if (rrule.until.is_null_time () == 0) {
            /*for (int i = 0; i <= rrule.until.year; i++) {
                int n = i*rrule.interval;
                if (view_range.contains (start.add_years (n)) || view_range.contains (end.add_years (n)))
                    dateranges.add (new Util.DateRange (start.add_years (n), end.add_years (n)));
            }*/
        } else if (rrule.count > 0) {
            for (int i = 1; i<=rrule.count; i++) {
                int n = i*rrule.interval;
                if (view_range.contains (start.add_years (n)) || view_range.contains (end.add_years (n)))
                    dateranges.add (new Util.DateRange (start.add_years (n), end.add_years (n)));
            }
        } else {
            int i = 1;
            int n = i*rrule.interval;
            bool is_null_time = rrule.until.is_null_time () == 1;
            var temp_start = start.add_years (n);
            while (view_range.last.compare (temp_start) > 0) {
                if (is_null_time == false) {
                    if (temp_start.get_year () > rrule.until.year)
                        break;
                    else if (temp_start.get_year () == rrule.until.year && temp_start.get_month () > rrule.until.month)
                        break;
                    else if (temp_start.get_year () == rrule.until.year && temp_start.get_month () == rrule.until.month &&temp_start.get_day_of_month () > rrule.until.day)
                        break;
                
                }
                dateranges.add (new Util.DateRange (temp_start, end.add_years (n)));
                i++;
                n = i*rrule.interval;
                temp_start = start.add_years (n);
            }
        }
    }

    private void generate_month_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                           iCal.RecurrenceType rrule, DateTime start, DateTime end) {
        // Computes month recurrences by day (for example: third friday of the month).
        for (int k = 0; k <= iCal.Size.BY_DAY; k++) {
            if (rrule.by_day[k] < iCal.Size.BY_DAY) {
                if (rrule.count > 0) {
                    for (int i = 1; i<=rrule.count; i++) {
                        int n = i*rrule.interval;
                        var start_ical_day = get_date_from_ical_day (start.add_months (n), rrule.by_day[k]);
                        int interval = start_ical_day.get_day_of_month () - start.get_day_of_month ();
                        dateranges.add (new Util.DateRange (start_ical_day, end.add_months (n).add_days (interval)));
                    }
                } else {
                    int i = 1;
                    bool is_null_time = rrule.until.is_null_time () == 1;
                    bool is_last = (rrule.by_day[k] < 0);
                    var start_ical_day = start;
                    var end_ical_day = end;
                    var days = end.get_day_of_month () - start.get_day_of_month ();
                    int start_week = (int)GLib.Math.ceil ((double)start.get_day_of_month () / 7);

                    // Loop through each individual month from the start and test to see if our event is in the month or not
                    while (view_range.last.compare (start_ical_day) > 0) {
                        if (is_null_time == false) {
                            if (start_ical_day.get_year () > rrule.until.year)
                                break;
                            else if (start_ical_day.get_year () == rrule.until.year && start_ical_day.get_month () > rrule.until.month)
                                break;
                            else if (start_ical_day.get_year () == rrule.until.year && start_ical_day.get_month () == rrule.until.month && start_ical_day.get_day_of_month () > rrule.until.day)
                                break;
                        }

                        var start_ical_day_new = get_date_from_ical_day (start.add_months (i), rrule.by_day[k]);
                        int month = start.add_months (i).get_month ();
                        int week = start_week;
                    
                        // If event repeats on a last day of the month, take us back a week if we move into a new month
                        if (is_last && start_ical_day_new.get_month () != month) {
                            start_ical_day_new = start_ical_day_new.add_weeks (-1);
                        }
                        
                        else if (!is_last) {
                            if (start_ical_day_new.get_day_of_month () <= 7 && start_ical_day_new.add_weeks (-1).get_month () == month) {
                                week = 2;
                            }
                            else {
                                week =  (int)GLib.Math.ceil ((double)start_ical_day_new.get_day_of_month () / 7);
                            }
                        }
                       
                        start_ical_day_new = start_ical_day_new.add_weeks (start_week - week);
                        if (start_ical_day_new.get_month () != month) {
                            start_ical_day = start.add_months (i);
                        }
                        else {
                            start_ical_day = start_ical_day_new;
                            end_ical_day = start_ical_day.add_days (days);
                            dateranges.add (new Util.DateRange (start_ical_day, end_ical_day));
                        }

                        i++;
                    }
                }
            } else {
                break;
            }
        }

        // Computes month recurrences by month day (for example: 4th of the month).
        if (rrule.by_month_day[0] < iCal.Size.BY_MONTHDAY) {
            if (rrule.count > 0) {
                for (int i = 1; i<=rrule.count; i++) {
                    int n = i*rrule.interval;
                    dateranges.add (new Util.DateRange (start.add_months (n), end.add_months (n)));
                }
            } else {
                int i = 1;
                int n = i*rrule.interval;
                bool is_null_time = rrule.until.is_null_time () == 1;
                var temp_start = start.add_months (n);
                while (view_range.last.compare (temp_start) > 0) {
                    if (is_null_time == false) {
                        if (temp_start.get_year () > rrule.until.year)
                            break;
                        else if (temp_start.get_year () == rrule.until.year && temp_start.get_month () > rrule.until.month)
                            break;
                        else if (temp_start.get_year () == rrule.until.year && temp_start.get_month () == rrule.until.month && temp_start.get_day_of_month () > rrule.until.day)
                            break;
                    
                    }

                    dateranges.add (new Util.DateRange (temp_start, end.add_months (n)));
                    i++;
                    n = i*rrule.interval;
                    temp_start = start.add_months (n);
                }
            }
        }
    }

    private void generate_week_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                           iCal.RecurrenceType rrule, DateTime start_, DateTime end_) {
        DateTime start = start_;
        DateTime end = end_;
        for (int k = 0; k <= iCal.Size.BY_DAY; k++) {
            if (rrule.by_day[k] > 7)
                break;

            int day_to_add = 0;
            switch (rrule.by_day[k]) {
                case 1:
                    day_to_add = 7 - start.get_day_of_week ();
                    break;
                case 2:
                    day_to_add = 1 - start.get_day_of_week ();
                    break;
                case 3:
                    day_to_add = 2 - start.get_day_of_week ();
                    break;
                case 4:
                    day_to_add = 3 - start.get_day_of_week ();
                    break;
                case 5:
                    day_to_add = 4 - start.get_day_of_week ();
                    break;
                case 6:
                    day_to_add = 5 - start.get_day_of_week ();
                    break;
                default:
                    day_to_add = 6 - start.get_day_of_week ();
                    break;
            }

            if (start.add_days (day_to_add).get_month () < start.get_month ())
                day_to_add = day_to_add + 7;

            start = start.add_days (day_to_add);
            end = end.add_days (day_to_add);

            if (rrule.count > 0) {
                for (int i = 1; i<=rrule.count; i++) {
                    int n = i*rrule.interval*7;
                    if (view_range.contains (start.add_days (n)) || view_range.contains (end.add_days (n)))
                        dateranges.add (new Util.DateRange (start.add_days (n), end.add_days (n)));
                }
            } else {
                int i = 1;
                int n = i*rrule.interval*7;
                bool is_null_time = rrule.until.is_null_time () == 1;
                var temp_start = start.add_days (n);
                while (view_range.last.compare (temp_start) > 0) {
                    if (is_null_time == false) {
                        if (temp_start.get_year () > rrule.until.year)
                            break;
                        else if (temp_start.get_year () == rrule.until.year) {
                            if (temp_start.get_month () > rrule.until.month)
                                break;
                            else if (temp_start.get_month () == rrule.until.month && temp_start.get_day_of_month () > rrule.until.day)
                                break;
                        }
                    }

                    dateranges.add (new Util.DateRange (temp_start, end.add_days (n)));
                    i++;
                    n = i*rrule.interval*7;
                    temp_start = start.add_days (n);
                }
            }
        }
    }

    public bool is_multiday_event (iCal.Component comp) {
        var start = ical_to_date_time (comp.get_dtstart ());
        var end = ical_to_date_time (comp.get_dtend ());

        bool allday = is_all_day (start, end);
        if (allday)
            end = end.add_days (-1);

        if (start.get_year () != end.get_year () || start.get_day_of_year () != end.get_day_of_year ())
            return true;

        return false;
    }

    /**
     * Say if an event lasts all day.
     */
    public bool is_all_day (DateTime dtstart, DateTime dtend) {
        var UTC_start = dtstart.to_timezone (new TimeZone.utc ());
        var timespan = dtend.difference (dtstart);
        if (timespan % GLib.TimeSpan.DAY == 0 && UTC_start.get_hour() == 0) {
            return true;
        } else {
            return false;
        }
    }

    public DateTime get_date_from_ical_day (DateTime date, short day) {
        int day_to_add = 0;
        switch (iCal.RecurrenceType.day_day_of_week (day)) {
            case iCal.RecurrenceTypeWeekday.SUNDAY:
                day_to_add = 7 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.MONDAY:
                day_to_add = 1 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.TUESDAY:
                day_to_add = 2 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.WEDNESDAY:
                day_to_add = 3 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.THURSDAY:
                day_to_add = 4 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.FRIDAY:
                day_to_add = 5 - date.get_day_of_week ();
                break;
            default:
                day_to_add = 6 - date.get_day_of_week ();
                break;
        }

        return date.add_days (day_to_add);
    }

    public DateTime get_start_of_month (owned DateTime? date = null) {

        if (date == null)
            date = new DateTime.now_local ();

        return new DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
    }

    public DateTime get_end_of_month (owned DateTime? date = null) {

        if (date == null)
            date = new DateTime.now_local ();

        return (new DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0)).add_months (1);
    }

    public DateTime strip_time (DateTime datetime) {
        return datetime.add_full (0, 0, 0, -datetime.get_hour (), -datetime.get_minute (), -datetime.get_second ());
    }

    /* Create a map interleaving DateRanges dr1 and dr2 */
    public Gee.Map<DateTime, DateTime> zip_date_ranges (DateRange dr1, DateRange dr2)
        requires (dr1.days == dr2.days) {

        var map = new Gee.TreeMap<DateTime, DateTime>(
            (GLib.CompareDataFunc<E.CalComponent>?) DateTime.compare,
            (Gee.EqualDataFunc<GLib.DateTime>?) datetime_equal_func);

        var i1 = dr1.iterator();
        var i2 = dr2.iterator();

        while (i1.next() && i2.next()) {
            map.set (i1.get(), i2.get());
        }

        return map;
    }

    /*
     * Gee Utility Functions
     */

    /* Interleaves the values of two collections into a Map */
    public void zip<F, G> (Gee.Iterable<F> iterable1, Gee.Iterable<G> iterable2, Gee.Map<F, G> map) {

        var i1 = iterable1.iterator();
        var i2 = iterable2.iterator();

        while (i1.next() && i2.next())
            map.set (i1, i2);
    }

    /* Constructs a new set with keys equal to the values of keymap */
    public void remap<K, V> (Gee.Map<K, K> keymap, Gee.Map<K, V> valmap, ref Gee.Map<K, V> remap) {

        foreach (K key in valmap) {

            var k = keymap [key];
            var v = valmap [key];

            remap.set (k, v);
        }
    }

    /* Computes hash value for string */
    public uint string_hash_func (string key) {
        return key.hash ();
    }

    /* Computes hash value for DateTime */
    public uint datetime_hash_func (DateTime key) {
        return key.hash ();
    }

    /* Computes hash value for E.CalComponent */
    public uint calcomponent_hash_func (E.CalComponent key) {
        unowned iCal.Component comp = key.get_icalcomponent ();
        string uid = comp.get_uid ();
        return uid.hash ();
    }

    /* Computes hash value for E.Source */
    public uint source_hash_func (E.Source key) {
        return key.dup_uid (). hash ();
    }

    /* Returns true if 'a' and 'b' are the same string */
    public bool string_equal_func (string a, string b) {
        return a == b;
    }

    /* Returns true if 'a' and 'b' are the same GLib.DateTime */
    public bool datetime_equal_func (DateTime a, DateTime b) {
        return a.equal (b);
    }

    /* Returns true if 'a' and 'b' are the same E.CalComponent */
    public bool calcomponent_equal_func (E.CalComponent a, E.CalComponent b) {
        unowned iCal.Component comp_a = a.get_icalcomponent ();
        unowned iCal.Component comp_b = b.get_icalcomponent ();
        return comp_a.get_uid () == comp_b.get_uid ();
    }

    /* Returns true if 'a' and 'b' are the same E.Source */
    public bool source_equal_func (E.Source a, E.Source b) {
        return a.dup_uid () == b.dup_uid ();
    }

    /*
     * TreeModel Utility Functions
     */

    public Gtk.TreePath? find_treemodel_object<T> (Gtk.TreeModel model, int column, T object, EqualFunc<T>? eqfunc=null) {
        Gtk.TreePath? path = null;
        model.foreach ((m, p, iter) => {
            Value gvalue;
            model.get_value (iter, column, out gvalue);

            T ovalue = gvalue.get_object ();

            if ((eqfunc == null && ovalue == object) 
                    || (eqfunc != null && eqfunc (ovalue, object))) {
                path = p;
                return true;
            }

            return false;
        });

        return path;
    }

    /*
     * Gtk Miscellaneous
     */

    public class Css {
        private static Gtk.CssProvider? _css_provider;
        // Retrieve global css provider
        public static unowned Gtk.CssProvider get_css_provider () {
            if (_css_provider == null) {
                _css_provider = new Gtk.CssProvider ();
                _css_provider.load_from_resource ("/org/pantheon/maya/default.css");
            }

            return _css_provider;
        }
    }

    public Gtk.Widget set_margins (Gtk.Widget widget, int top, int end, int bottom, int start) {
        widget.margin_top = top;
        widget.margin_end = end;
        widget.margin_bottom = bottom;
        widget.margin_start = start;
        return widget;
    }

    public Gtk.Alignment set_paddings (Gtk.Widget widget, int top, int right, int bottom, int left) {
        var alignment = new Gtk.Alignment (0.0f, 0.0f, 1.0f, 1.0f);
        alignment.top_padding = top;
        alignment.right_padding = right;
        alignment.bottom_padding = bottom;
        alignment.left_padding = left;
        alignment.add (widget);
        return alignment;
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

    public void save_temp_selected_calendars (){
        //TODO:Create the code !
    }

    public string get_hexa_color (Gdk.RGBA color) {
        return "#%02X%02X%02X".printf ((uint)(color.red*255), (uint)(color.green*255), (uint)(color.blue*255));
    }

}
