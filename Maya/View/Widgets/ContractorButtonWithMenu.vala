//
//  Copyright (C) 2011-2012 Jaap Broekhuizen
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

using Maya.Services;

namespace Maya.View.Widgets {

    public class ContractorButtonWithMenu : Granite.Widgets.ToolButtonWithMenu {

        private Gtk.FileChooserDialog filechooser;

        public ContractorButtonWithMenu (string tooltiptext) {

            base (new Gtk.Image.from_icon_name ("document-export", Gtk.IconSize.MENU), tooltiptext, new Gtk.Menu());
            var services = Contractor.get_services ();

            foreach (var service in services) {
                Gtk.MenuItem item = new Gtk.MenuItem.with_label(service.get_display_name());
                item.activate.connect (activate_contract);
                menu.append (item);
            }
                Gtk.MenuItem item = new Gtk.MenuItem.with_label(_("Export Calendar..."));
                item.activate.connect (savecal);
                menu.append (item);

        }

        private void activate_contract () {
            /* creates a .ics file */
            Util.save_temp_selected_calendars ();

            string file_path = GLib.Environment.get_tmp_dir () + "/calendar.ics";
            File cal_file = File.new_for_path(file_path);

            Gtk.MenuItem menuitem = (Gtk.MenuItem) menu.get_active();
            string app_menu = menuitem.get_label();

            Contractor.execute_service_for_display_name (app_menu, cal_file);
        }

        private void savecal () {
            /* creates a .ics file */
            Util.save_temp_selected_calendars ();
            filechooser = new Gtk.FileChooserDialog (_("Export Calendar..."), null, Gtk.FileChooserAction.SAVE);
            var filter = new Gtk.FileFilter ();
            filter.add_mime_type("text/calendar");
            filechooser.set_current_name(_("calendar.ics"));
            filechooser.set_filter(filter);
            filechooser.add_button(Gtk.Stock.CANCEL, Gtk.ResponseType.CLOSE);
            filechooser.add_button(Gtk.Stock.SAVE, Gtk.ResponseType.APPLY);
            filechooser.response.connect (on_response);
            filechooser.show_all ();
            filechooser.run ();


        }

        private void on_response (Gtk.Dialog source, int response_id) {
            switch (response_id) {
            case Gtk.ResponseType.APPLY:
                var destination = filechooser.get_filename ();
                if (destination == null) {
                    destination = filechooser.get_current_folder();
                } else if (!destination.has_suffix(".ics")) {
                    destination += ".ics";
                }
                try {
                    GLib.Process.spawn_command_line_async ("mv " + GLib.Environment.get_tmp_dir () + "/calendar.ics " + destination);
                } catch (SpawnError e) {
                    warning (e.message);
                }
                filechooser.destroy ();
                break;
            case Gtk.ResponseType.CLOSE:
                filechooser.destroy ();
                break;
            }
        }
    }

}

