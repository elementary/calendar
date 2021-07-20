/*-
 * Copyright (c) 2021 elementary, Inc. (https://elementary.io)
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
 * Authored by: Gustavo Marques <pushstartocontinue@outlook.com>
 */

namespace Portal {
    const string DBUS_DESKTOP_PATH = "/org/freedesktop/portal/desktop";
    const string DBUS_DESKTOP_NAME = "org.freedesktop.portal.Desktop";
    Background? background = null;

    public static string generate_token () {
        return "%s_%i".printf (
            GLib.Application.get_default ().application_id.replace (".", "_"),
            Random.int_range (0, int32.MAX)
        );
    }

    [DBus (name = "org.freedesktop.portal.Background")]
    interface Background : Object {
        public abstract uint version { get; }

        public static Background @get () throws IOError, DBusError {
            if (background == null) {
                var connection = GLib.Application.get_default ().get_dbus_connection ();
                background = connection.get_proxy_sync<Background> (DBUS_DESKTOP_NAME, DBUS_DESKTOP_PATH);
            }

            return background;
        }

        public abstract ObjectPath request_background (string window_handle, HashTable<string, Variant> options) throws IOError, DBusError;
    }
}
