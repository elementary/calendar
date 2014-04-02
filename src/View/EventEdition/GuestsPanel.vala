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

// TODO: Use Folks to get contact informations such as name and picture.

public class Maya.View.EventEdition.GuestsPanel : Gtk.Grid {
    private EventDialog parent_dialog;
    private Gtk.Entry guest_entry;
    private Gtk.Grid guest_grid;
    private int guest_grid_id = 0;
    private Gee.ArrayList<unowned iCal.Property> attendees;

    private enum COLUMNS {
        ICON = 0,
        NAME,
        STATUS,
        N_COLUMNS;
    }

    public GuestsPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;
        attendees = new Gee.ArrayList<unowned iCal.Property> ();

        margin_left = 12;
        margin_right = 12;
        set_row_spacing (6);
        set_column_spacing (12);
        set_sensitive (parent_dialog.can_edit);

        var guest_label = Maya.View.EventDialog.make_label (_("Participants:"));

        guest_entry = new Gtk.SearchEntry ();
        guest_entry.placeholder_text = _("Invite…");
        guest_entry.hexpand = true;
        guest_entry.activate.connect (() => {
            var attendee = new iCal.Property (iCal.PropertyKind.ATTENDEE);
            attendee.set_attendee (guest_entry.text);
            add_attendee ((owned)attendee);
        });

        guest_grid = new Gtk.Grid ();
        var guest_scrolledwindow = new Gtk.ScrolledWindow (null, null);
        guest_scrolledwindow.add_with_viewport (guest_grid);
        guest_scrolledwindow.expand = true;

        var fake_grid_l = new Gtk.Grid ();
        fake_grid_l.hexpand = true;
        guest_grid.attach (fake_grid_l, 0, 0, 1, 1);

        var fake_grid_r = new Gtk.Grid ();
        fake_grid_r.hexpand = true;
        guest_grid.attach (fake_grid_r, 2, 0, 1, 1);

        attach (guest_label, 0, 0, 1, 1);
        attach (guest_entry, 0, 1, 1, 1);
        attach (guest_scrolledwindow, 0, 2, 1, 1);

        if (parent_dialog.ecal != null) {
            unowned iCal.Component comp = parent_dialog.ecal.get_icalcomponent ();
            // Load the guests
            int count = comp.count_properties (iCal.PropertyKind.ATTENDEE);

            unowned iCal.Property property = comp.get_first_property (iCal.PropertyKind.ATTENDEE);
            for (int i = 0; i < count; i++) {

                if (property.get_attendee () != null)
                    add_attendee (property);

                property = comp.get_next_property (iCal.PropertyKind.ATTENDEE);
            }
        }

        show_all ();
    }

    /**
     * Save the values in the dialog into the component.
     */
    public void save () {
        unowned iCal.Component comp = parent_dialog.ecal.get_icalcomponent ();
        // Save the guests
        // First, clear the guests
        int count = comp.count_properties (iCal.PropertyKind.ATTENDEE);

        for (int i = 0; i < count; i++) {
            unowned iCal.Property remove_prop;
            if (i == 0) {
                remove_prop = comp.get_first_property (iCal.PropertyKind.ATTENDEE);
            } else {
                remove_prop = comp.get_next_property (iCal.PropertyKind.ATTENDEE);
            }

            unowned iCal.Property found_prop = remove_prop;
            bool can_remove = true;
            foreach (unowned iCal.Property attendee in attendees) {
                if (attendee.get_uid () == remove_prop.get_uid ()) {
                    can_remove = false;
                    found_prop = attendee;
                }
            }

            if (can_remove == true) {
                comp.remove_property (remove_prop);
            } else if (found_prop != remove_prop) {
                attendees.remove (found_prop);
            }
        }

        // Add the new guests
        foreach (unowned iCal.Property attendee in attendees) {
            var clone = new iCal.Property.clone (attendee);
            comp.add_property (clone);
        }
    }

    private void add_attendee (iCal.Property attendee) {
        var guest_element = new GuestGrid (attendee);
        guest_grid.attach (guest_element, 1, guest_grid_id, 1, 1);
        guest_grid_id++;
        attendees.add (guest_element.attendee);
        guest_element.removed.connect (() => {
            attendees.remove (guest_element.attendee);
        });
        guest_element.show_all ();
    }
}

public class Maya.View.EventEdition.GuestGrid : Gtk.Grid {
    public signal void removed ();
    public iCal.Property attendee;

    public GuestGrid (iCal.Property attendee) {
        this.attendee = new iCal.Property.clone (attendee);
        row_spacing = 6;
        column_spacing = 12;

        string status = "<b><span color=\'darkgrey\'>%s</span></b>".printf (_("Pending"));
        unowned iCal.Parameter parameter = attendee.get_first_parameter (iCal.ParameterKind.PARTSTAT);
        if (parameter != null) {
            switch (parameter.get_partstat ()) {
                case iCal.ParameterPartStat.ACCEPTED:
                    status = "<b><span color=\'green\'>%s</span></b>".printf (_("Accepted"));
                    break;
                case iCal.ParameterPartStat.DECLINED:
                    status = "<b><span color=\'red\'>%s</span></b>".printf (_("Declined"));
                    break;
                default:
                    status = "<b><span color=\'darkgrey\'>%s</span></b>".printf (_("Pending"));
                    break;
            }
        }

        var status_label = new Gtk.Label ("");
        status_label.set_markup (status);
        status_label.justify = Gtk.Justification.RIGHT;

        var icon_image = new Gtk.Image.from_icon_name ("avatar-default", Gtk.IconSize.DIALOG);
        
        var mail = attendee.get_attendee ().replace ("mailto:", "");

        var name_label = new Gtk.Label ("");
        name_label.xalign = 0;
        name_label.set_markup ("<b><big>%s</big></b>".printf (GLib.Markup.escape_text (mail.split ("@", 2)[0])));

        var mail_label = new Gtk.Label ("");
        mail_label.hexpand = true;
        mail_label.xalign = 0;
        mail_label.set_markup ("<b><span color=\'darkgrey\'>%s</span></b>".printf (GLib.Markup.escape_text (mail)));

        var remove_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON);
        remove_button.relief = Gtk.ReliefStyle.NONE;
        remove_button.clicked.connect (() => {removed (); hide (); destroy ();});
        var remove_grid = new Gtk.Grid ();
        remove_grid.add (remove_button);
        remove_grid.valign = Gtk.Align.CENTER;

        attach (icon_image, 0, 0, 1, 4);
        attach (name_label, 1, 1, 1, 2/*1*/);
        //attach (mail_label, 1, 2, 1, 1); Once Folks is enabled, separate email and name !
        attach (status_label, 2, 1, 1, 2);
        attach (remove_grid, 3, 1, 1, 2);
    }
}