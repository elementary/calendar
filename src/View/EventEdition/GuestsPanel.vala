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

public class Maya.View.EventEdition.GuestsPanel : Gtk.Grid {
    private EventDialog parent_dialog;
    private Maya.View.Widgets.GuestEntry guest_entry;
    public GuestsPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;

        margin_left = 12;
        margin_right = 12;
        set_row_spacing (6);
        set_column_spacing (12);
        set_sensitive (parent_dialog.can_edit);

        var guest_label = Maya.View.EventDialog.make_label (_("Participants:"));
        guest_entry = new Maya.View.Widgets.GuestEntry (_("Name or Email Address"));
        guest_entry.check_resize ();

        attach (guest_label, 0, 0, 1, 1);
        attach (guest_entry, 0, 1, 1, 1);
        var fake_grid = new Gtk.Grid ();
        fake_grid.expand = true;
        attach (fake_grid, 0, 2, 1, 1);

        if (parent_dialog.ecal != null) {
            unowned iCal.Component comp = parent_dialog.ecal.get_icalcomponent ();
            // Load the guests
            int count = comp.count_properties (iCal.PropertyKind.ATTENDEE);

            unowned iCal.Property property = comp.get_first_property (iCal.PropertyKind.ATTENDEE);
            for (int i = 0; i < count; i++) {

                if (property.get_attendee () != null)
                    guest_entry.add_address (property.get_attendee ());

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
            unowned iCal.Property remove_prop = comp.get_first_property (iCal.PropertyKind.ATTENDEE);

            comp.remove_property (remove_prop);
        }

        // Add the new guests
        Gee.ArrayList<string> addresses = guest_entry.get_addresses ();
        foreach (string address in addresses) {
            var property = new iCal.Property (iCal.PropertyKind.ATTENDEE);
            property.set_attendee (address);
            comp.add_property (property);
        }
        
        
    }
}