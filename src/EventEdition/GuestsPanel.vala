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
    private Gtk.EntryCompletion guest_completion;
    private Gtk.Grid guest_grid;
    private int guest_grid_id = 0;
    private Gee.ArrayList<unowned iCal.Property> attendees;
    private ContactLookup contact_lookup;
    private Gtk.ListStore guest_store;

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
        
        contact_lookup = new ContactLookup ();
        contact_lookup.contacts_loaded.connect((contacts) => apply_contact_store_model (contacts));
        
        guest_completion = new Gtk.EntryCompletion ();
        guest_entry.set_completion (guest_completion);
        
        guest_store = new Gtk.ListStore(2, typeof (string), typeof (string));
        guest_completion.set_model (guest_store);
        guest_completion.set_text_column (0);
        guest_completion.set_text_column (1);
        
        guest_completion.match_selected.connect ((model, iter) => suggestion_selected (model, iter));

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
     * Add the contacts to the EntryCompletion model.
     */
    private void apply_contact_store_model (Gee.Map<string, Folks.Individual> contacts) {        
        Gtk.TreeIter contact;
        Gee.MapIterator<string, Folks.Individual> map_iterator;
        
        map_iterator = contacts.map_iterator ();
        
        while (map_iterator.next ()) {
        
            foreach (var address in map_iterator.get_value ().email_addresses) {
                guest_store.append (out contact);
                guest_store.set (contact, 0, map_iterator.get_value ().full_name, 1, address.value, address);
            }
        }
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
    
        
    private bool suggestion_selected (Gtk.TreeModel model, Gtk.TreeIter iter) {
        var attendee = new iCal.Property (iCal.PropertyKind.ATTENDEE);
        Value selected_value;
        
        model.get_value (iter, 1, out selected_value);
        attendee.set_attendee ((string)selected_value);
        add_attendee ((owned)attendee);
        return true;
    }
}


//TODO split and remove class 
public class Maya.View.EventEdition.ContactLookup {

    private Folks.IndividualAggregator aggregator;
    public bool ready;
    
    public signal void contacts_loaded (Gee.Map<string, Folks.Individual> contacts);
    public signal void contact_found (Folks.Individual contact);
    
    public ContactLookup () {
        aggregator = Folks.IndividualAggregator.dup ();
        
        aggregator.notify["is-quiescent"].connect (() => {
            contacts_loaded (get_contacts ());
        });
        
        ready = false;
        aggregator.prepare ();
    }
    
    public Gee.Map<string, Folks.Individual> get_contacts () {
        return aggregator.individuals;
    }
    
    public async Folks.Individual get_individual_for_mail (string mail_address) {
        Gee.MapIterator <string, Folks.Individual> map_iterator;
        
        map_iterator = aggregator.individuals.map_iterator ();
        
        while (map_iterator.next ()) {
            foreach (var address in map_iterator.get_value ().email_addresses) {
                if(address.value == mail_address) {
                    return map_iterator.get_value ();
                }
            }
        }
        
        return null;
    }
    
    public async GLib.LoadableIcon? get_image_for_mail (string mail_address) {     
        Gee.MapIterator<string, Folks.Individual> map_iterator;
        
        map_iterator = aggregator.individuals.map_iterator ();
        
        while (map_iterator.next ()) {
            
            foreach (var address in map_iterator.get_value ().email_addresses) {
                if (address.value == mail_address) {
                    if(map_iterator.get_value ().avatar != null) {
                        return map_iterator.get_value ().avatar;
                        }
                }   
            }
        }
        
        return null;
    }
}


public class Maya.View.EventEdition.GuestGrid : Gtk.Grid {
    public signal void removed ();
    public iCal.Property attendee;
    private Folks.Individual individual;

    public GuestGrid (iCal.Property attendee) {
        this.attendee = new iCal.Property.clone (attendee);
        row_spacing = 6;
        column_spacing = 12;
        individual = null;

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
        
        icon_image.draw.connect ((cr) => {
            try {
                var width = get_allocated_width ();
                var height = get_allocated_height ();
                int size = (int) double.min (width, height);
                var img_pixbuf = Gtk.IconTheme.get_default ().load_icon ("avatar-default", size, Gtk.IconLookupFlags.GENERIC_FALLBACK);
//                var img_pixbuf = icon_image.get_pixbuf ();
                cr.set_operator (Cairo.Operator.OVER);
                var x = (width-size)/2;
                var y = (height-size)/2;
                Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, x, y, size, size, size/2);
                Gdk.cairo_set_source_pixbuf (cr, img_pixbuf, x, y);
                cr.fill_preserve ();
                cr.set_line_width (0);
                cr.set_source_rgba (0, 0, 0, 0.3);
                cr.stroke ();
            } catch (Error e) {
                critical (e.message);
                return false;
            } 
            
            icon_image.show ();
            warning ("drawed");
            
            return true;
        });
        
        var contact_lookup = new ContactLookup();
        
        var mail = attendee.get_attendee ().replace ("mailto:", "");

        var name_label = new Gtk.Label ("");
        name_label.xalign = 0;
        name_label.set_markup ("<b><big>%s</big></b>".printf (Markup.escape_text (mail.split ("@", 2)[0])));

        var mail_label = new Gtk.Label ("");
        mail_label.hexpand = true;
        mail_label.xalign = 0;
        mail_label.set_markup ("<b><span color=\'darkgrey\'>%s</span></b>".printf (Markup.escape_text (mail)));

        var remove_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON);
        remove_button.relief = Gtk.ReliefStyle.NONE;
        remove_button.clicked.connect (() => {removed (); hide (); destroy ();});
        var remove_grid = new Gtk.Grid ();
        remove_grid.add (remove_button);
        remove_grid.valign = Gtk.Align.CENTER;

        contact_lookup.get_individual_for_mail.begin (attendee.get_attendee ().replace ("mailto:", ""), (obj, res) => {
            individual = contact_lookup.get_individual_for_mail.end (res);
            if (individual != null) {
                if (individual.avatar != null) {
                    icon_image.set_from_gicon (individual.avatar, Gtk.IconSize.DIALOG);
                }
                
                if (individual.full_name != null) {
                    name_label.set_text (individual.full_name);
                    mail_label.set_text (attendee.get_attendee ());
                }
            }
        });
        
        attach (icon_image, 0, 0, 1, 4);
        attach (name_label, 1, 1, 1, 1);
        attach (mail_label, 1, 2, 1, 1); 
        attach (status_label, 2, 1, 1, 2);
        attach (remove_grid, 3, 1, 1, 2);
    }
}