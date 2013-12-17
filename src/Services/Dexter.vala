//
//  Copyright (C) 2011-2012 Christian Dywan <christian@twotoasts.de>
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

namespace Maya.Services {

	[DBus (name = "org.elementary.dexterserver")]
	interface DexterService : Object {
		public abstract void edit_contact (string name, string email_address) throws IOError;
		public abstract string get_name (string email_address) throws IOError;
		public abstract string[] autocomplete_contact (string keywords) throws IOError;
		public abstract void show_window () throws IOError;
	}

	public class Dexter : Object {

		DexterService? service = null;

		public Dexter () {

			try {
				service = Bus.get_proxy_sync (BusType.SESSION,
											  "org.elementary.dexterserver",
											  "/org/elementary/dexterserver");

				/* Ensure Dexter is running, ignore errors, without is fine */
				Process.spawn_async (null, { "dexter-server" }, null,
					SpawnFlags.SEARCH_PATH
				  | SpawnFlags.STDOUT_TO_DEV_NULL
				  | SpawnFlags.STDERR_TO_DEV_NULL,
					null, null);
			} catch (GLib.Error error) {  }
		}

		public void edit_contact (string name, string email_address) {

			try {
				if (service == null)
					throw new GLib.IOError.FAILED ("Service unavailable");
				service.edit_contact (name, email_address);
			} catch (GLib.Error error) {
				Granite.Services.System.execute_command ("dexter");
			}
		}

		public string? get_name (string email_address) {

			try {
				if (service == null)
					throw new GLib.IOError.FAILED ("Service unavailable");
				string name = service.get_name (email_address);
				return name != "" ? name : null;
			} catch (GLib.Error error) {
				return null;
			}
		}

		public string[] autocomplete_contact (string keywords) {

			try {
				if (service == null)
					throw new GLib.IOError.FAILED ("Service unavailable");
				return service.autocomplete_contact (keywords);
			} catch (GLib.Error error) {
				return {};
			}
		}

		public void show_window () {

			try {
				if (service == null)
					throw new GLib.IOError.FAILED ("Service unavailable");
				service.show_window ();
			} catch (GLib.Error error) {
				Granite.Services.System.execute_command ("dexter");
			}
		}

	}

}

