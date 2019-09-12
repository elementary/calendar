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
    public ICal.Property attendee;
    private Folks.Individual individual;
    private Gtk.Label name_label;
    private Gtk.Label mail_label;
    private Granite.Widgets.Avatar avatar;

    public GuestGrid (ICal.Property attendee) {
        this.attendee = attendee.clone ();
        individual = null;

        var status_label = new Gtk.Label ("");
        status_label.justify = Gtk.Justification.RIGHT;

        var status_label_context = status_label.get_style_context ();
        status_label_context.add_class (Granite.STYLE_CLASS_H4_LABEL);

        unowned ICal.Parameter parameter = attendee.get_first_parameter (ICal.ParameterKind.PARTSTAT_PARAMETER);
        if (parameter != null) {
            switch (parameter.get_partstat ()) {
                case ICal.ParameterPartstat.ACCEPTED:
                    status_label.label = _("Accepted");
                    status_label_context.add_class ("success");
                    break;
                case ICal.ParameterPartstat.DECLINED:
                    status_label.label = _("Declined");
                    status_label_context.add_class (Gtk.STYLE_CLASS_ERROR);
                    break;
                case ICal.ParameterPartstat.TENTATIVE:
                    status_label.label = _("Maybe");
                    status_label_context.add_class (Gtk.STYLE_CLASS_ERROR);
                    break;
                default:
                    break;
            }
        }

        avatar = new Granite.Widgets.Avatar.with_default_icon (32);

        var mail = attendee.get_attendee ().replace ("mailto:", "");

        name_label = new Gtk.Label (Markup.escape_text (mail.split ("@", 2)[0]));
        name_label.xalign = 0;

        mail_label = new Gtk.Label (Markup.escape_text (mail));
        mail_label.hexpand = true;
        mail_label.xalign = 0;

        var remove_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON);
        remove_button.relief = Gtk.ReliefStyle.NONE;
        remove_button.valign = Gtk.Align.CENTER;

        get_contact_by_mail.begin (attendee.get_attendee ().replace ("mailto:", ""));

        column_spacing = 12;
        margin = 6;
        attach (avatar, 0, 0, 1, 4);
        attach (name_label, 1, 1, 1, 1);
        attach (mail_label, 1, 2, 1, 1);
        attach (status_label, 2, 1, 1, 2);
        attach (remove_button, 3, 1, 1, 2);

        remove_button.clicked.connect (() => {
            removed ();
            hide ();
            destroy ();
        });
    }

    private async void get_contact_by_mail (string mail_address) {
        Folks.IndividualAggregator aggregator = Folks.IndividualAggregator.dup ();
        if (aggregator.is_prepared) {
            Gee.MapIterator <string, Folks.Individual> map_iterator;
            map_iterator = aggregator.individuals.map_iterator ();

            while (map_iterator.next ()) {
                foreach (var address in map_iterator.get_value ().email_addresses) {
                    if (address.value == mail_address) {
                        individual = map_iterator.get_value ();
                        if (individual != null) {
                            try {
                                individual.avatar.load (32, null);
                                avatar = new Granite.Widgets.Avatar.from_file (individual.avatar.to_string (), 32);
                            } catch (Error e) {
                                critical (e.message);
                            }
                            if (individual.full_name != null && individual.full_name != "") {
                                name_label.label = Markup.escape_text (individual.full_name);
                                mail_label.label = Markup.escape_text (attendee.get_attendee ());
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
}
