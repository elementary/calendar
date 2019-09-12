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

namespace Maya.Settings {
    [DBus (name = "io.elementary.greeter.AccountsService")]
    interface Greeter.AccountsService : Object {
        public abstract string time_format { owned get; set; }
    }

    [DBus (name = "org.freedesktop.Accounts")]
    interface FDO.Accounts : Object {
        public abstract string find_user_by_name (string username) throws GLib.Error;
    }

    public class TimeFormatHolder : Object {
        private static TimeFormatHolder instance;
        public static unowned TimeFormatHolder get_instance () {
            if (instance == null) {
                instance = new TimeFormatHolder ();
            }

            return instance;
        }

        public bool is_12h { get; private set; default = false; }
        private Greeter.AccountsService? greeter_act = null;

        construct {
            try {
                var accounts_service = GLib.Bus.get_proxy_sync<FDO.Accounts> (GLib.BusType.SYSTEM,
                                                                "org.freedesktop.Accounts",
                                                                "/org/freedesktop/Accounts");
                var user_path = accounts_service.find_user_by_name (GLib.Environment.get_user_name ());
                greeter_act = GLib.Bus.get_proxy_sync (GLib.BusType.SYSTEM,
                                                       "org.freedesktop.Accounts",
                                                       user_path,
                                                       GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
                is_12h = greeter_act.time_format == "12h" ? true : false;
            } catch (Error e) {
                critical (e.message);
                var setting = new GLib.Settings ("org.gnome.desktop.interface");
                GLib.Variant? clockformat = setting.get_user_value ("clock-format");
                if (clockformat != null) {
                    is_12h = clockformat.get_string ().contains ("12h");
                }
            }
        }
    }

    public string TimeFormat () {
        return Granite.DateTime.get_default_time_format (TimeFormatHolder.get_instance ().is_12h);
    }

}

