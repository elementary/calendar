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

public class Maya.View.EventEdition.ReminderPanel : Gtk.Grid {
    private EventDialog parent_dialog;
    private Gtk.Grid reminder_grid;
    private Gee.ArrayList<ReminderGrid> reminders;
    private Gtk.Label no_reminder_label;

    public ReminderPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;
        expand = true;
        row_spacing = 6;
        column_spacing = 12;
        sensitive = parent_dialog.can_edit;

        var reminder_label = Maya.View.EventDialog.make_label (_("Reminders:"));
        reminder_label.margin_left = 12;

        no_reminder_label = new Gtk.Label (_("No Reminders."));
        no_reminder_label.hexpand = true;

        reminders = new Gee.ArrayList<ReminderGrid> ();

        reminder_grid = new Gtk.Grid ();
        reminder_grid.row_spacing = 6;
        reminder_grid.column_spacing = 12;
        reminder_grid.orientation = Gtk.Orientation.VERTICAL;
        reminder_grid.expand = true;
        reminder_grid.add (no_reminder_label);
        var add_reminder_button = new Gtk.Button.with_label (_("Add Reminder"));
        add_reminder_button.clicked.connect (() => {
            add_reminder ();
        });
        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.add (add_reminder_button);

        var fake_grid_left = new Gtk.Grid ();
        fake_grid_left.hexpand = true;
        var fake_grid_right = new Gtk.Grid ();
        fake_grid_right.hexpand = true;

        var main_grid = new Gtk.Grid ();
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add_with_viewport (main_grid);
        scrolled.expand = true;

        main_grid.attach (fake_grid_left, 0, 0, 1, 1);
        main_grid.attach (fake_grid_right, 2, 0, 1, 1);
        main_grid.attach (reminder_grid, 1, 0, 1, 1);

        attach (reminder_label, 0, 0, 1, 1);
        attach (scrolled, 0, 1, 1, 1);
        attach (button_box, 0, 2, 1, 1);
    }
    
    private void add_reminder () {
        var reminder = new ReminderGrid ();
        reminders.add (reminder);
        reminder_grid.add (reminder);
        reminder.show_all ();
        reminder.removed.connect (() => {
            reminders.remove (reminder);
            if (reminders.is_empty == true) {
                no_reminder_label.no_show_all = false;
                no_reminder_label.show ();
            }
        });
        no_reminder_label.no_show_all = true;
        no_reminder_label.hide ();
    }

    /**
     * Save the values in the dialog into the component.
     */
    public void save () {

        unowned iCal.Component comp = parent_dialog.ecal.get_icalcomponent ();
        
        // First, clear the reminders
        int count = comp.count_properties (iCal.PropertyKind.ACTION);

        for (int i = 0; i < count; i++) {
            unowned iCal.Property remove_prop = comp.get_first_property (iCal.PropertyKind.ACTION);

            comp.remove_property (remove_prop);
        }

        // Add the comment
        /*foreach (var reminder in reminders) {
            var property = new iCal.Property (iCal.PropertyKind.ACTION);
            property.set_action (Reminder.get_ical_property_action (reminder.type));
            comp.add_property (property);
        }*/
    }
}

public class Maya.View.EventEdition.ReminderGrid : Gtk.Grid {
    public signal void removed ();

    Gtk.ComboBoxText choice;
    Gtk.ComboBoxText time;
    Gtk.Entry email_entry;

    public ReminderGrid () {
        row_spacing = 6;
        column_spacing = 12;

        time = new Gtk.ComboBoxText ();
        time.append_text (_("0 minutes"));
        time.append_text (_("1 minutes"));
        time.append_text (_("5 minutes"));
        time.append_text (_("10 minutes"));
        time.append_text (_("15 minutes"));
        time.append_text (_("20 minutes"));
        time.append_text (_("25 minutes"));
        time.append_text (_("30 minutes"));
        time.append_text (_("45 minutes"));
        time.append_text (_("1 hour"));
        time.append_text (_("2 hours"));
        time.append_text (_("3 hours"));
        time.append_text (_("12 hours"));
        time.append_text (_("24 hours"));
        time.append_text (_("2 days"));
        time.append_text (_("1 week"));
        time.active = 3;

        choice = new Gtk.ComboBoxText ();
        choice.append_text (_("Notification"));
        choice.append_text (_("Email"));
        choice.active = 0;
        choice.hexpand = true;
        choice.changed.connect (() => {
            if (choice.active == 1) {
                email_entry.no_show_all = false;
                choice.hexpand = false;
                email_entry.show ();
            } else {
                email_entry.no_show_all = true;
                email_entry.hide ();
                choice.hexpand = true;
            }
        });

        email_entry = new Gtk.Entry ();
        email_entry.placeholder_text = _("john@doe.com");
        email_entry.no_show_all = true;
        email_entry.hexpand = true;
        
        var remove_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON);
        remove_button.relief = Gtk.ReliefStyle.NONE;
        remove_button.clicked.connect (() => {removed (); hide (); destroy ();});

        attach (time, 0, 0, 1, 1);
        attach (choice, 1, 0, 1, 1);
        attach (email_entry, 2, 0, 1, 1);
        attach (remove_button, 3, 0, 1, 1);
    }
}