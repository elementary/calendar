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

using Gtk;
using Gdk;

using Granite;
using Granite.Services;

using Maya.Widgets;
using Maya.Services;

namespace Maya {

	public class Maya : Granite.Application {
		
		public static int main (string[] args) {
			var app = new Maya ();
			AppFactory.init (app);
			app.start (args);
			return app.run (args);
		}
		
		private MayaWindow window = null;
		
		public static CssProvider style_provider { get; private set; default = null; }
		
		public static GLib.Settings saved_state { get; private set; default = null; }
		
		public static GLib.Settings prefs { get; private set; default = null; }
		
		construct {
		
			// App info
			build_data_dir = Build.DATADIR;
			build_pkg_data_dir = Build.PKGDATADIR;
			build_release_name = Build.RELEASE_NAME;
			build_version = Build.VERSION;
			build_version_info = Build.VERSION_INFO;
			
			program_name = "Maya";
			exec_name = "maya";
			
			app_copyright = "2011";
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
				"Maxwell Barvian <mbarvian@gmail.com>"
			};
			about_artists = {
				"Daniel Foré <bunny@go-docky.com>"
			};
			about_translators = "";
			
			// Set up global css provider
			style_provider = new CssProvider ();
			try {
				style_provider.load_from_path (Build.PKGDATADIR + "/style/default.css");
			} catch (Error e) {
				warning ("Could not add css provider. Some widgets will not look as intended. %s", e.message);
			}
			
			// Set up settings
			saved_state = new GLib.Settings ("org.elementary.Maya.SavedState");
			prefs = new GLib.Settings ("org.elementary.Maya.Settings");
		}
		
		protected override void activate () {
			
			if (window != null) {
				window.present (); // present window if app is already open
				return;
			}
			
			window = new MayaWindow ();
			window.set_application (this);
			window.show_all ();
		}
	
	}
	
}

