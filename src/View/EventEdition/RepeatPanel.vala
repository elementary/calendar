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

public class Maya.View.EventEdition.RepeatPanel : Gtk.Grid {
    private EventDialog parent_dialog;
    private Gtk.Switch repeat_switch;
    private Gtk.ComboBoxText repeat_combobox;
    private Gtk.ComboBoxText ends_combobox;
    private Gtk.Grid week_grid;
    private Gtk.Grid month_grid;
    private Gtk.SpinButton every_entry;

    public RepeatPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;
        margin_left = 12;
        margin_right = 12;
        row_spacing = 6;
        column_spacing = 12;
        sensitive = parent_dialog.can_edit;

        var reminder_label = Maya.View.EventDialog.make_label (_("Repeat:"));

        repeat_switch = new Gtk.Switch ();

        repeat_combobox = new Gtk.ComboBoxText ();
        repeat_combobox.append_text (_("Daily"));
        repeat_combobox.append_text (_("Weekly"));
        repeat_combobox.append_text (_("Monthly"));
        repeat_combobox.append_text (_("Yearly"));
        repeat_combobox.active = 1;
        repeat_combobox.hexpand = true;

        var repeat_grid = new Gtk.Grid ();
        repeat_grid.row_spacing = 6;
        repeat_grid.column_spacing = 12;
        repeat_grid.orientation = Gtk.Orientation.HORIZONTAL;
        repeat_grid.add (repeat_switch);
        repeat_grid.add (repeat_combobox);

        var every_label = Maya.View.EventDialog.make_label (_("Every:"));

        every_entry = new Gtk.SpinButton.with_range (1, 99, 1);
        every_entry.hexpand = true;

        var every_unit_label = new Gtk.Label (_("Week"));

        var every_grid = new Gtk.Grid ();
        every_grid.row_spacing = 6;
        every_grid.column_spacing = 12;
        every_grid.orientation = Gtk.Orientation.HORIZONTAL;
        every_grid.add (every_entry);
        every_grid.add (every_unit_label);

        var ends_label = Maya.View.EventDialog.make_label (_("Ends:"));

        ends_combobox = new Gtk.ComboBoxText ();
        ends_combobox.append_text (_("Never"));
        ends_combobox.append_text (_("Until"));
        ends_combobox.append_text (_("After"));
        ends_combobox.hexpand = true;
        ends_combobox.active = 0;

        create_week_grid ();

        var ends_grid = new Gtk.Grid ();
        ends_grid.row_spacing = 6;
        ends_grid.column_spacing = 12;
        ends_grid.orientation = Gtk.Orientation.HORIZONTAL;
        ends_grid.add (ends_combobox);

        var fake_grid_left = new Gtk.Grid ();
        fake_grid_left.hexpand = true;
        var fake_grid_right = new Gtk.Grid ();
        fake_grid_right.hexpand = true;

        attach (fake_grid_left, 0, 0, 1, 1);
        attach (fake_grid_right, 2, 0, 1, 1);
        attach (reminder_label, 1, 0, 1, 1);
        attach (repeat_grid, 1, 1, 1, 1);
        attach (every_label, 1, 2, 1, 1);
        attach (every_grid, 1, 3, 1, 1);
        attach (week_grid, 1, 4, 1, 1);
        attach (ends_label, 1, 5, 1, 1);
        attach (ends_grid, 1, 6, 1, 1);
    }

    private void create_week_grid () {
        week_grid = new Gtk.Grid ();
        week_grid.column_homogeneous = true;
        var mon_button = new Gtk.ToggleButton.with_label (_("Mon"));
        var tue_button = new Gtk.ToggleButton.with_label (_("Tue"));
        var wed_button = new Gtk.ToggleButton.with_label (_("Wed"));
        var thu_button = new Gtk.ToggleButton.with_label (_("Thu"));
        var fri_button = new Gtk.ToggleButton.with_label (_("Fri"));
        var sat_button = new Gtk.ToggleButton.with_label (_("Sat"));
        var sun_button = new Gtk.ToggleButton.with_label (_("Sun"));
        week_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        week_grid.get_style_context ().add_class ("raised");
        switch (Maya.Model.CalendarModel.get_default ().week_starts_on) {
            case Settings.Weekday.TUESDAY:
                week_grid.add (thu_button);
                week_grid.add (fri_button);
                week_grid.add (sat_button);
                week_grid.add (sun_button);
                week_grid.add (mon_button);
                week_grid.add (tue_button);
                week_grid.add (wed_button);
                break;
            case Settings.Weekday.WEDNESDAY:
                week_grid.add (wed_button);
                week_grid.add (thu_button);
                week_grid.add (fri_button);
                week_grid.add (sat_button);
                week_grid.add (sun_button);
                week_grid.add (mon_button);
                week_grid.add (tue_button);
                break;
            case Settings.Weekday.THURSDAY:
                week_grid.add (thu_button);
                week_grid.add (fri_button);
                week_grid.add (sat_button);
                week_grid.add (sun_button);
                week_grid.add (mon_button);
                week_grid.add (tue_button);
                week_grid.add (wed_button);
                break;
            case Settings.Weekday.FRIDAY:
                week_grid.add (fri_button);
                week_grid.add (sat_button);
                week_grid.add (sun_button);
                week_grid.add (mon_button);
                week_grid.add (tue_button);
                week_grid.add (wed_button);
                week_grid.add (thu_button);
                break;
            case Settings.Weekday.SATURDAY:
                week_grid.add (sat_button);
                week_grid.add (sun_button);
                week_grid.add (mon_button);
                week_grid.add (tue_button);
                week_grid.add (wed_button);
                week_grid.add (thu_button);
                week_grid.add (fri_button);
                break;
            case Settings.Weekday.SUNDAY:
                week_grid.add (sun_button);
                week_grid.add (mon_button);
                week_grid.add (tue_button);
                week_grid.add (wed_button);
                week_grid.add (thu_button);
                week_grid.add (fri_button);
                week_grid.add (sat_button);
                break;
            default:
                week_grid.add (mon_button);
                week_grid.add (tue_button);
                week_grid.add (wed_button);
                week_grid.add (thu_button);
                week_grid.add (fri_button);
                week_grid.add (sat_button);
                week_grid.add (sun_button);
                break;
        }
    }
    
    /**
     * Save the values in the dialog into the component.
     */
    public void save () {
        
    }
}