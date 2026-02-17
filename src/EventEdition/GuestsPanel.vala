/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2026 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Jaap Broekhuizen
 */

public class Maya.View.EventEdition.GuestsPanel : Gtk.Box {
    public ICal.Component component { get; construct; }

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

    public GuestsPanel (ICal.Component component) {
        Object (component: component);
    }

    construct {
        attendees = new Gee.ArrayList<unowned ICal.Property> ();

        guest_store = new Gtk.ListStore (2, typeof (string), typeof (string));

        load_contacts.begin ();

        var no_guests_label = new Gtk.Label (_("No Invitees"));
        no_guests_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        no_guests_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        no_guests_label.show ();

        guest_list = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true,
            selection_mode = NONE
        };
        guest_list.set_placeholder (no_guests_label);

        var guest_label = new Granite.HeaderLabel (_("Invitees")) {
            mnemonic_widget = guest_list
        };

        var guest_scrolledwindow = new Gtk.ScrolledWindow (null, null) {
            child = guest_list
        };

        var frame = new Gtk.Frame (null) {
            child = guest_scrolledwindow
        };

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

        guest_entry = new Gtk.SearchEntry () {
            hexpand = true,
            placeholder_text = _("Invite")
        };
        guest_entry.set_completion (guest_completion);
        guest_entry.activate.connect (() => {
            var attendee = new ICal.Property (ATTENDEE_PROPERTY);
            attendee.set_attendee (guest_entry.text);
            add_guest ((owned)attendee);
            guest_entry.delete_text (0, -1);
        });

        margin_start = 12;
        margin_end = 12;
        spacing = 6;
        orientation = VERTICAL;
        add (guest_label);
        add (guest_entry);
        add (frame);

        var property = component.get_first_property (ATTENDEE_PROPERTY);
        for (int i = 0; i < component.count_properties (ATTENDEE_PROPERTY); i++) {
            if (property.get_attendee () != null) {
                add_guest (property);
            }

            property = component.get_next_property (ATTENDEE_PROPERTY);
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
        // First, clear the guests
        for (int i = 0; i < component.count_properties (ATTENDEE_PROPERTY); i++) {
            ICal.Property remove_prop;
            if (i == 0) {
                remove_prop = component.get_first_property (ATTENDEE_PROPERTY);
            } else {
                remove_prop = component.get_next_property (ATTENDEE_PROPERTY);
            }

            ICal.Property found_prop = remove_prop;
            bool can_remove = true;
            foreach (unowned ICal.Property attendee in attendees) {
                if (attendee.get_uid () == remove_prop.get_uid ()) {
                    can_remove = false;
                    found_prop = attendee;
                }
            }

            if (can_remove == true) {
                component.remove_property (remove_prop);
            } else if (found_prop != remove_prop) {
                attendees.remove (found_prop);
            }
        }

        // Add the new guests
        foreach (unowned ICal.Property attendee in attendees) {
            component.add_property (attendee.clone ());
        }
    }

    private void add_guest (ICal.Property attendee) {
        var guest_element = new GuestGrid (attendee);

        var row = new Gtk.ListBoxRow () {
            child = guest_element
        };
        row.show_all ();

        guest_list.add (row);

        attendees.add (guest_element.attendee);

        guest_element.removed.connect (() => {
            attendees.remove (guest_element.attendee);
        });
    }

    private bool suggestion_selected (Gtk.TreeModel model, Gtk.TreeIter iter) {
        var attendee = new ICal.Property (ATTENDEE_PROPERTY);
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
