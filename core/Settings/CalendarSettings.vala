//
//  Copyright (C) 2011-2012 Maxwell Barvian
//
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

namespace Calendar.Settings {
    public enum Weekday {
        SUNDAY = 0,
        MONDAY,
        TUESDAY,
        WEDNESDAY,
        THURSDAY,
        FRIDAY,
        SATURDAY
    }

    public class CalendarSettings : Granite.Services.Settings {
        private static Settings.CalendarSettings? global_settings = null;

        public static CalendarSettings get_default () {
            if (global_settings == null)
                global_settings = new CalendarSettings ();
            return global_settings;
        }

        public string[] plugins_disabled { get; set; }

        private CalendarSettings () {
            base ("io.elementary.calendar.settings");
        }

    }

}
