/*
 * Copyright 2011-2020 elementary, Inc. (https://elementary.io)
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
 * Authored by: Maxwell Barvian
 */

public class Calendar.Widgets.ConnectivityInfoBar : Gtk.InfoBar {
    private GLib.NetworkMonitor network_monitor;
    private Gtk.Label info_label;

    public ConnectivityInfoBar () {
        Object (
            message_type: Gtk.MessageType.WARNING,
            revealed : false,
            show_close_button : false
        );
    }

    construct {
        unowned string title = _("Network Not Available.");
        unowned string details = _("Connect to the Internet to see additional details and new events from online calendars.");

        info_label = new Gtk.Label ("<b>%s</b> %s".printf (title, details));
        info_label.use_markup = true;
        info_label.wrap = true;

        get_content_area ().add (info_label);
        add_button (_("Network Settings…"), Gtk.ResponseType.ACCEPT);

        network_monitor = GLib.NetworkMonitor.get_default ();
        network_monitor.network_changed.connect (() => {
            bool available = network_monitor.get_network_available ();

            if (available && network_monitor.get_connectivity () == GLib.NetworkConnectivity.FULL) {
                set_revealed (false);
            } else {
                set_revealed (true);
            }
        });

        response.connect ((response_id) => {
            switch (response_id) {
                case Gtk.ResponseType.ACCEPT:
                    try {
                        AppInfo.launch_default_for_uri ("settings://network", null);
                    } catch (GLib.Error e) {
                        critical (e.message);
                    }
                    break;
                default:
                    assert_not_reached ();
            }
        });
    }
}
