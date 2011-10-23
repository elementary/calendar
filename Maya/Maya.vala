//
//  Copyright (C) 2011 Maxwell Barvian
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

using Granite;
using Granite.Services;

using Maya.Widgets;
using Maya.Services;
using Maya.Dialogs;

namespace Maya {

	public class MayaApp : Granite.Application {

		construct {

			// App info
			build_data_dir = Build.DATADIR;
			build_pkg_data_dir = Build.PKGDATADIR;
			build_release_name = Build.RELEASE_NAME;
			build_version = Build.VERSION;
			build_version_info = Build.VERSION_INFO;

			program_name = "Maya";
			exec_name = "maya";

			app_years = "2011";
			application_id = "net.launchpad.maya";
			app_icon = "office-calendar";
			app_launcher = "maya.desktop";

			main_url = "https://launchpad.net/maya";
			bug_url = "https://bugs.launchpad.net/maya";
			help_url = "https://answers.launchpad.net/maya";
			translate_url = "https://translations.launchpad.net/maya";

			about_authors = {
				"Maxwell Barvian <maxwell@elementaryos.org>",
				"Jaap Broekhuizen <jaapz.b@gmail.com>",
				"Avi Romanoff <aviromanoff@gmail.com>",
				"Allen Lowe <lallenlowe@gmail.com>"
			};
			about_documenters = {
				"Maxwell Barvian <maxwell@elementaryos.org>"
			};
			about_artists = {
				"Daniel Foré <bunny@go-docky.com>"
			};
			about_translators = "";
            about_license_type = Gtk.License.GPL_3_0;
		}

		private static bool ADD = false;

		private const OptionEntry[] entries = {
			{ "add-event", 'a', 0, OptionArg.NONE, out ADD, "Just show an add event dialog", null },
			{ null }
		};

		protected override void activate () {

			if (get_windows () != null) {
				get_windows ().data.present (); // present window if app is already running
			    return;
			}

			if (ADD) {
			    (new AddEvent.without_parent (this)).show_all ();
			} else {
			    var window = new MayaWindow (this);
			    window.set_application (this);
			    window.show_all ();
			}
		}

		public static int main (string[] args) {

		    var context = new OptionContext("Calendar");
            context.add_main_entries(entries, "maya");
            context.add_group(Gtk.get_option_group(true));

            try {
                context.parse(ref args);
            } catch(Error e) {
                print(e.message + "\n");
            }

            Gtk.init(ref args);


            return new MayaApp ().run (args);
		}


	}

}

