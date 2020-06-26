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

    /* Returns true if 'a' and 'b' are the same GLib.DateTime */
    public bool datetime_equal_func (GLib.DateTime a, GLib.DateTime b) {
        return a.equal (b);
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
}
