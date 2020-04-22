/*-
 * Copyright (c) 2020 elementary, Inc. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Marco Betschart<elementary@marco.betschart.name>
 */

namespace Maya.Week.Util {

    internal const int MINUTES_PER_DAY = 1440;
    internal const int MAX_MINUTES = (7 * MINUTES_PER_DAY);
    internal const double dashed[] = { 5.0, 6.0 };
    internal const int COLUMN_PADDING = 6;

    internal double aligned (double x) {
        return Math.round (x) + 0.5;
    }

    /**
     * TODO: https://gitlab.gnome.org/GNOME/gnome-calendar/-/blob/master/src/utils/gcal-utils.c#L301
     */
    internal int get_first_weekday () {
        return 0;
    }


    /**
     * Retrieves the first day of the week @date is in, at 00:00
     * of the local timezone.
     *
     * This date is inclusive.
     */
    internal DateTime get_start_of_week (DateTime date) {
        var first_weekday = get_first_weekday ();
        var weekday = date.get_day_of_week () % 7;
        var n_days_after_week_start = (weekday - first_weekday) % 7;

        var start_of_week = date.add_days (-n_days_after_week_start);

        return new DateTime.local (
            start_of_week.get_year (),
            start_of_week.get_month (),
            start_of_week.get_day_of_month (),
            0, 0, 0);
    }


    /**
     * Retrieves the last day of the week @date is in, at 23:59:59
     * of the local timezone.
     *
     * Because this date is exclusive, it actually is start of the
     * next week.
     */
     internal DateTime get_end_of_week (DateTime date) {
         var week_start = get_start_of_week (date);
         return week_start.add_weeks (1);
     }

    internal int get_days_in_month (DateTime datetime) {
        DateMonth month;

        switch (datetime.get_month ()) {
            case 1:
                month = DateMonth.JANUARY;
                break;
            case 2:
                month = DateMonth.FEBRUARY;
                break;
            case 3:
                month = DateMonth.MARCH;
                break;
            case 4:
                month = DateMonth.APRIL;
                break;
            case 5:
                month = DateMonth.MAY;
                break;
            case 6:
                month = DateMonth.JUNE;
                break;
            case 7:
                month = DateMonth.JULY;
                break;
            case 8:
                month = DateMonth.AUGUST;
                break;
            case 9:
                month = DateMonth.SEPTEMBER;
                break;
            case 10:
                month = DateMonth.OCTOBER;
                break;
            case 11:
                month = DateMonth.NOVEMBER;
                break;
            case 12:
                month = DateMonth.DECEMBER;
                break;
            default:
                month = DateMonth.BAD_MONTH;
                break;
        }

        // TODO: Make DateYear dynamic: datetime.get_year ()
        // how do I convert int into ushort ...?!
        DateYear year = 2020;

        return month.get_days_in_month (year);
    }
}
