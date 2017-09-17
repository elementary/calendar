// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
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
 *              Corentin Noël <corentin@elementaryos.org>
 */

namespace Calendar.View {

    public class CalendarToolbar : Gtk.HeaderBar {
        
        // Signals
        public signal void on_search (string search);
        public signal void on_menu_today_toggled ();
        public signal void add_calendar_clicked ();
        
        // Toolbar items
        public Gtk.SearchEntry search_bar;
        Widgets.DateSwitcher month_switcher;
        Widgets.DateSwitcher year_switcher;
        Widgets.DynamicSpinner spinner;
        
        // Menu items
        View.SourceSelector source_selector;
        Gtk.ToggleButton button_calendar_sources;
        
        public CalendarToolbar () {
            show_close_button = true;

            var button_add = new Gtk.Button.from_icon_name ("appointment-new", Gtk.IconSize.LARGE_TOOLBAR);
            button_add.tooltip_text = _("Create a new event");

            var button_today = new Gtk.Button.from_icon_name ("calendar-go-today", Gtk.IconSize.LARGE_TOOLBAR);
            button_today.tooltip_text = _("Go to today's date");

            button_calendar_sources = new Gtk.ToggleButton ();
            button_calendar_sources.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
            button_calendar_sources.tooltip_text = _("Manage Calendars");

            source_selector = new View.SourceSelector ();
            source_selector.set_relative_to (button_calendar_sources);
            button_calendar_sources.bind_property ("active", source_selector, "visible", GLib.BindingFlags.BIDIRECTIONAL);

            month_switcher = new Widgets.DateSwitcher (10);
            year_switcher = new Widgets.DateSwitcher (-1);
            var calmodel = Model.CalendarModel.get_default ();
            set_switcher_date (calmodel.month_start);

            search_bar = new Gtk.SearchEntry ();
            search_bar.placeholder_text = _("Search Events");
            search_bar.sensitive = false;

            var contractor = new Widgets.ContractorButtonWithMenu (_("Export or Share the default Calendar"));

            var title_grid = new Gtk.Grid ();
            title_grid.column_spacing = 6;
            title_grid.add (button_today);
            title_grid.add (month_switcher);
            title_grid.add (year_switcher);

            spinner = new Widgets.DynamicSpinner ();

            pack_start (button_add);
            pack_start (spinner);
            set_custom_title (title_grid);
            pack_end (button_calendar_sources);
            //pack_end (search_bar);
            pack_end (contractor);

            // Connect to signals
            button_add.clicked.connect (() => add_calendar_clicked ());
            button_today.clicked.connect (() => { on_menu_today_toggled (); });
            search_bar.search_changed.connect (() => on_search (search_bar.text));
            month_switcher.left_clicked.connect (() => {Model.CalendarModel.get_default ().change_month (-1);});
            month_switcher.right_clicked.connect (() => {Model.CalendarModel.get_default ().change_month (1);});
            year_switcher.left_clicked.connect (() => {Model.CalendarModel.get_default ().change_year (-1);});
            year_switcher.right_clicked.connect (() => {Model.CalendarModel.get_default ().change_year (1);});
            button_calendar_sources.size_allocate.connect (button_size_allocate);
            calmodel.parameters_changed.connect (() => {
                set_switcher_date (calmodel.month_start);
            });
        }

        public void set_switcher_date (DateTime date) {
            month_switcher.text = date.format ("%B");
            year_switcher.text = date.format ("%Y");
        }
        
        void button_size_allocate (Gtk.Allocation allocation) {
            month_switcher.height_request = allocation.height;
            year_switcher.height_request = allocation.height;
        }
    }

}
