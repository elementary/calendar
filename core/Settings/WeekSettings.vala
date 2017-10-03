/*-
 * Copyright (c) 2011-2017 Maya Developers (http://launchpad.net/maya)
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
 * Authored by: Alexander Hale
 */
 
namespace Maya.Settings {
    public class WeekSettings : Granite.Services.Settings {
        private static WeekSettings? instance = null;

        public bool show_weeks{ get; set; }

        public WeekSettings () {
            base ("org.pantheon.desktop.wingpanel.indicators.datetime");
        }

        public static WeekSettings get_default () {
            if (instance == null) {
                instance = new WeekSettings ();
            }

            return instance;
        }
    }
}
