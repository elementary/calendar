/*
 * Copyright 2011-2018 elementary, Inc. (https://elementary.io)
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

public class Maya.View.EventEdition.GuestGrid : Gtk.Grid {
    public signal void removed ();
    public iCal.Property attendee;
    private Folks.Individual individual;
    private Gtk.Label name_label;
    private Gtk.Label mail_label;
    private ContactImage icon_image;

    public GuestGrid (iCal.Property attendee) {
        this.attendee = new iCal.Property.clone (attendee);
        row_spacing = 6;
        column_spacing = 12;
        individual = null;

        set_margin_bottom (6);
        set_margin_end (6);
        set_margin_start (6);

        string status = "";
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
                    status = "";
                    break;
            }
        }

        var status_label = new Gtk.Label ("");
        status_label.set_markup (status);
        status_label.justify = Gtk.Justification.RIGHT;
        icon_image = new ContactImage (Gtk.IconSize.DIALOG);

        var mail = attendee.get_attendee ().replace ("mailto:", "");

        name_label = new Gtk.Label ("");
        ((Gtk.Misc) name_label).xalign = 0.0f;
        set_name_label (mail.split ("@", 2)[0]);

        mail_label = new Gtk.Label ("");
        mail_label.hexpand = true;
        ((Gtk.Misc) mail_label).xalign = 0.0f;
        set_mail_label (mail);

        var remove_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON);
        remove_button.relief = Gtk.ReliefStyle.NONE;
        remove_button.clicked.connect (() => {removed (); hide (); destroy ();});
        var remove_grid = new Gtk.Grid ();
        remove_grid.add (remove_button);
        remove_grid.valign = Gtk.Align.CENTER;

        get_contact_by_mail.begin (attendee.get_attendee ().replace ("mailto:", ""));

        attach (icon_image, 0, 0, 1, 4);
        attach (name_label, 1, 1, 1, 1);
        attach (mail_label, 1, 2, 1, 1);
        attach (status_label, 2, 1, 1, 2);
        attach (remove_grid, 3, 1, 1, 2);
    }

    private async void get_contact_by_mail (string mail_address) {
        Folks.IndividualAggregator aggregator = Folks.IndividualAggregator.dup ();
        if (aggregator.is_prepared) {
            Gee.MapIterator <string, Folks.Individual> map_iterator;
            map_iterator = aggregator.individuals.map_iterator ();

            while (map_iterator.next ()) {
                foreach (var address in map_iterator.get_value ().email_addresses) {
                    if(address.value == mail_address) {
                        individual = map_iterator.get_value ();
                        if (individual != null) {
                            icon_image.add_contact (individual);
                            if (individual.full_name != null && individual.full_name != "") {
                                set_name_label (individual.full_name);
                                set_mail_label (attendee.get_attendee ());
                            }
                        }
                    }
                }
            }
        } else {
            aggregator.notify["is-quiescent"].connect (() => {
                get_contact_by_mail.begin (mail_address);
            });

            try {
                yield aggregator.prepare ();
            } catch (Error e) {
                critical (e.message);
            }
        }
    }

    private void set_name_label (string name) {
        name_label.set_markup ("<b><big>%s</big></b>".printf (Markup.escape_text (name)));
    }

    private void set_mail_label (string mail) {
        mail_label.set_markup ("<b><span color=\'darkgrey\'>%s</span></b>".printf (Markup.escape_text (mail)));
    }
}
