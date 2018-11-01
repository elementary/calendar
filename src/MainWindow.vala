// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2017 elementary LLC. (https://elementary.io)
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
 * Authored by: Maxwell Barvian <maxwell@elementary.io>
 *              Corentin Noël <corentin@elementary.io>
 */

public class Maya.MainWindow : Gtk.ApplicationWindow {
    public View.CalendarView calview;

    private uint configure_id;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            height_request: 400,
            icon_name: "office-calendar",
            width_request: 625
        );
    }

    construct {
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/io/elementary/calendar");

        var headerbar = new View.HeaderBar ();

        var infobar_label = new Gtk.Label (null);
        infobar_label.show ();

        var infobar = new Gtk.InfoBar ();
        infobar.message_type = Gtk.MessageType.ERROR;
        infobar.no_show_all = true;
        infobar.show_close_button = true;
        infobar.get_content_area ().add (infobar_label);

        var sidebar = new View.AgendaView ();
        sidebar.no_show_all = true;
        sidebar.width_request = 160;
        sidebar.show ();

        calview = new View.CalendarView ();
        calview.vexpand = true;

        var hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        hpaned.pack1 (calview, true, false);
        hpaned.pack2 (sidebar, true, false);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (infobar);
        grid.add (hpaned);

        add (grid);
        set_titlebar (headerbar);

        calview.on_event_add.connect ((date) => on_tb_add_clicked (date));
        calview.edition_request.connect (on_modified);
        calview.selection_changed.connect ((date) => sidebar.set_selected_date (date));

        headerbar.add_calendar_clicked.connect (() => on_tb_add_clicked (calview.selected_date));
        headerbar.on_menu_today_toggled.connect (on_menu_today_toggled);

        infobar.response.connect ((id) => infobar.hide ());

        sidebar.event_removed.connect (on_remove);
        sidebar.event_modified.connect (on_modified);

        Maya.Application.saved_state.bind ("hpaned-position", hpaned, "position", GLib.SettingsBindFlags.DEFAULT);

        Model.CalendarModel.get_default ().error_received.connect ((message) => {
            Idle.add (() => {
                infobar_label.label = message;
                infobar.show ();
                return false;
            });
        });
    }

    public void on_tb_add_clicked (DateTime dt) {
        var dialog = new Maya.View.EventDialog (null, dt);
        dialog.transient_for = this;
        dialog.show_all ();
    }

    private void on_menu_today_toggled () {
        calview.today ();
    }

    private void on_remove (E.CalComponent comp) {
        Model.CalendarModel.get_default ().remove_event (comp.get_data<E.Source> ("source"), comp, E.CalObjModType.THIS);
    }

    private void on_modified (E.CalComponent comp) {
        var dialog = new Maya.View.EventDialog (comp, null);
        dialog.transient_for = this;
        dialog.present ();
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            GLib.Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;

            var saved_state = Settings.SavedState.get_default ();

            if (is_maximized) {
                saved_state.window_state = Settings.WindowState.MAXIMIZED;
            } else {
                saved_state.window_state = Settings.WindowState.NORMAL;

                int width, height;
                get_size (out width, out height);
                saved_state.window_width = width;
                saved_state.window_height = height;
            }

            return false;
        });

        return base.configure_event (event);
    }
}
