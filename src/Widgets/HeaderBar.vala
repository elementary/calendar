/*-
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
 * Authored by: Maxwell Barvian <maxwell@elementary.io>
 *              Corentin Noël <corentin@elementary.io>
 */

public class Calendar.Widgets.HeaderBar : Hdy.HeaderBar {
    public signal void on_search (string search);

    public Gtk.SearchEntry search_bar;
    private Calendar.Widgets.DateSwitcher month_switcher;
    private Calendar.Widgets.DateSwitcher year_switcher;

    public HeaderBar () {
        Object (show_close_button: true);
    }

    construct {
        var application_instance = ((Gtk.Application) GLib.Application.get_default ());

        var button_today = new Gtk.Button.from_icon_name ("calendar-go-today", Gtk.IconSize.LARGE_TOOLBAR);
        button_today.action_name = Maya.MainWindow.ACTION_PREFIX + Maya.MainWindow.ACTION_SHOW_TODAY;
        button_today.tooltip_markup = Granite.markup_accel_tooltip (
            application_instance.get_accels_for_action (button_today.action_name),
            _("Go to today's date")
        );

        month_switcher = new Calendar.Widgets.DateSwitcher (10) {
            valign = Gtk.Align.CENTER
        };
        year_switcher = new Calendar.Widgets.DateSwitcher (-1) {
            valign = Gtk.Align.CENTER
        };

        var button_add = new Gtk.Button.from_icon_name ("appointment-new", Gtk.IconSize.LARGE_TOOLBAR) {
            action_name = Maya.MainWindow.ACTION_PREFIX + Maya.MainWindow.ACTION_NEW_EVENT
        };
        button_add.tooltip_markup = Granite.markup_accel_tooltip (
            application_instance.get_accels_for_action (button_add.action_name),
            _("Create a new event")
        );

        var calmodel = Calendar.EventStore.get_default ();
        set_switcher_date (calmodel.month_start);

        var title_grid = new Gtk.Grid ();
        title_grid.column_spacing = 6;
        title_grid.add (button_today);
        title_grid.add (month_switcher);
        title_grid.add (year_switcher);

        var spinner = new Maya.View.Widgets.DynamicSpinner ();

        pack_start (spinner);
        pack_end (button_add);
        set_custom_title (title_grid);
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        month_switcher.left_clicked.connect (() => Calendar.EventStore.get_default ().change_month (-1));
        month_switcher.right_clicked.connect (() => Calendar.EventStore.get_default ().change_month (1));
        year_switcher.left_clicked.connect (() => Calendar.EventStore.get_default ().change_year (-1));
        year_switcher.right_clicked.connect (() => Calendar.EventStore.get_default ().change_year (1));
        calmodel.parameters_changed.connect (() => {
            set_switcher_date (calmodel.month_start);
        });
    }

    public void set_switcher_date (DateTime date) {
        month_switcher.text = date.format ("%OB");
        year_switcher.text = date.format ("%Y");
    }
}
