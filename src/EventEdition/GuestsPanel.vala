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
 * Authored by: Jaap Broekhuizen
 */

public class Maya.View.EventEdition.GuestsPanel : Gtk.Grid {
    private EventDialog parent_dialog;
    private Gtk.Entry guest_entry;
    private Gtk.EntryCompletion guest_completion;
    private Gtk.ListBox guest_list;
    private Gee.ArrayList<unowned ICal.Property> attendees;
    private Gtk.ListStore guest_store;

    public string guests {
        get { return guest_entry.get_text (); }
        set { guest_entry.set_text (value); }
    }

    private enum COLUMNS {
        ICON = 0,
        NAME,
        STATUS,
        N_COLUMNS;
    }

    public GuestsPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;
        attendees = new Gee.ArrayList<unowned ICal.Property> ();

        margin_start = 12;
        margin_end = 12;
        row_spacing = 6;
        set_sensitive (parent_dialog.can_edit);
        orientation = Gtk.Orientation.VERTICAL;

        guest_store = new Gtk.ListStore (2, typeof (string), typeof (string));

        var guest_label = new Granite.HeaderLabel (_("Participants:"));

        load_contacts.begin ();

        var no_guests_label = new Gtk.Label ("");
        no_guests_label.set_markup (_("No Participants"));
        no_guests_label.sensitive = false;
        no_guests_label.show ();

        guest_list = new Gtk.ListBox ();
        guest_list.set_selection_mode (Gtk.SelectionMode.NONE);
        guest_list.set_placeholder (no_guests_label);

        var guest_scrolledwindow = new Gtk.ScrolledWindow (null, null);
        guest_scrolledwindow.add (guest_list);
        guest_scrolledwindow.expand = true;

        var frame = new Gtk.Frame (null);
        frame.add (guest_scrolledwindow);

        guest_completion = new Gtk.EntryCompletion ();
        guest_completion.set_minimum_key_length (3);
        guest_completion.set_model (guest_store);
        guest_completion.set_text_column (0);
        guest_completion.set_text_column (1);
        guest_completion.match_selected.connect ((model, iter) => suggestion_selected (model, iter));
        guest_completion.set_match_func ((completion, key, iter) => {
            Value val1, val2;
            Gtk.ListStore model = (Gtk.ListStore)completion.get_model ();

            model.get_value (iter, 0, out val1);
            model.get_value (iter, 1, out val2);

            if (val1.get_string ().casefold (-1).contains (key) || val2.get_string ().casefold (-1).contains (key)) {
                return true;
            }

            return false;
        });

        guest_entry = new Gtk.SearchEntry ();
        guest_entry.placeholder_text = _("Invite");
        guest_entry.hexpand = true;
        guest_entry.set_completion (guest_completion);
        guest_entry.activate.connect (() => {
            var attendee = new ICal.Property (ICal.PropertyKind.ATTENDEE_PROPERTY);
            attendee.set_attendee (guest_entry.text);
            add_guest ((owned)attendee);
            guest_entry.delete_text (0, -1);
        });

        add (guest_label);
        add (guest_entry);
        add (frame);

        if (parent_dialog.ecal != null) {
            unowned ICal.Component comp = parent_dialog.ecal.get_icalcomponent ();
            // Load the guests
            int count = comp.count_properties (ICal.PropertyKind.ATTENDEE_PROPERTY);

#if E_CAL_2_0
            ICal.Property property;
#else
            unowned ICal.Property property;
#endif
            property = comp.get_first_property (ICal.PropertyKind.ATTENDEE_PROPERTY);
            for (int i = 0; i < count; i++) {
                if (property.get_attendee () != null)
                    add_guest (property);

                property = comp.get_next_property (ICal.PropertyKind.ATTENDEE_PROPERTY);
            }
        }

        show_all ();
    }

    /**
     * Add the contacts to the EntryCompletion model.
     */
    private void apply_contact_store_model (Gee.Map<string, Folks.Individual> contacts) {
        Gtk.TreeIter contact;
        var map_iterator = contacts.map_iterator ();
        while (map_iterator.next ()) {
            foreach (var address in map_iterator.get_value ().email_addresses) {
                guest_store.append (out contact);
                guest_store.set (contact, 0, map_iterator.get_value ().full_name, 1, address.value);
            }
        }
    }

    /**
     * Save the values in the dialog into the component.
     */
    public void save () {
        unowned ICal.Component comp = parent_dialog.ecal.get_icalcomponent ();
        // Save the guests
        // First, clear the guests
        int count = comp.count_properties (ICal.PropertyKind.ATTENDEE_PROPERTY);

        for (int i = 0; i < count; i++) {
#if E_CAL_2_0
            ICal.Property remove_prop;
#else
            unowned ICal.Property remove_prop;
#endif
            if (i == 0) {
                remove_prop = comp.get_first_property (ICal.PropertyKind.ATTENDEE_PROPERTY);
            } else {
                remove_prop = comp.get_next_property (ICal.PropertyKind.ATTENDEE_PROPERTY);
            }

#if E_CAL_2_0
            ICal.Property found_prop = remove_prop;
#else
            unowned ICal.Property found_prop = remove_prop;
#endif
            bool can_remove = true;
            foreach (unowned ICal.Property attendee in attendees) {
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
        foreach (unowned ICal.Property attendee in attendees) {
            comp.add_property (attendee.clone ());
        }
    }

    private void add_guest (ICal.Property attendee) {
        var row = new Gtk.ListBoxRow ();
        var guest_element = new GuestGrid (attendee);
        row.add (guest_element);
        guest_list.add (row);

        attendees.add (guest_element.attendee);
        guest_element.removed.connect (() => {
            attendees.remove (guest_element.attendee);
        });

        row.show_all ();
    }

    private bool suggestion_selected (Gtk.TreeModel model, Gtk.TreeIter iter) {
        var attendee = new ICal.Property (ICal.PropertyKind.ATTENDEE_PROPERTY);
        Value selected_value;

        model.get_value (iter, 1, out selected_value);
        attendee.set_attendee (selected_value.get_string ());
        add_guest ((owned)attendee);
        guest_entry.delete_text (0, -1);
        return true;
    }

    private async void load_contacts () {
        var aggregator = Folks.IndividualAggregator.dup ();

        if (aggregator.is_prepared) {
            apply_contact_store_model (aggregator.individuals);
        } else {
            aggregator.notify["is-quiescent"].connect (() => {
                load_contacts.begin ();
            });

            aggregator.prepare.begin ();
        }
    }
}
