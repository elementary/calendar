/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2026 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Jaap Broekhuizen
 */

public class Maya.View.EventEdition.GuestGrid : Gtk.Grid {
    public signal void removed ();

    public ICal.Property attendee { get; construct; }

    private const int ICON_SIZE = 32;

    private Gtk.Label mail_label;
    private Gtk.Label name_label;
    private Adw.Avatar avatar;

    public GuestGrid (ICal.Property attendee) {
        Object (attendee: attendee.clone ());
    }

    construct {
        var status_label = new Gtk.Label ("") {
            justify = RIGHT
        };
        status_label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);

        var mail = attendee.get_attendee ().replace ("mailto:", "");

        name_label = new Gtk.Label (Markup.escape_text (mail.split ("@", 2)[0])) {
            ellipsize = MIDDLE,
            xalign = 0
        };

        mail_label = new Gtk.Label (Markup.escape_text (mail)) {
            ellipsize = MIDDLE,
            hexpand = true,
            xalign = 0
        };

        var remove_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic") {
            has_frame = false,
            valign = CENTER
        };

        avatar = new Adw.Avatar (ICON_SIZE, name_label.label, true);

        column_spacing = 12;
        margin_top = 6;
        margin_end = 6;
        margin_bottom = 6;
        margin_start = 6;
        attach (avatar, 0, 0, 1, 4);
        attach (name_label, 1, 1);
        attach (mail_label, 1, 2);
        attach (status_label, 2, 1, 1, 2);
        attach (remove_button, 3, 1, 1, 2);

        get_contact_by_mail.begin (attendee.get_attendee ().replace ("mailto:", ""));

        var parameter = attendee.get_first_parameter (ICal.ParameterKind.PARTSTAT_PARAMETER);
        if (parameter != null) {
            switch (parameter.get_partstat ()) {
                case ICal.ParameterPartstat.ACCEPTED:
                    status_label.label = _("Accepted");
                    status_label.add_css_class (Granite.CssClass.SUCCESS);
                    break;
                case ICal.ParameterPartstat.DECLINED:
                    status_label.label = _("Declined");
                    status_label.add_css_class (Granite.CssClass.ERROR);
                    break;
                case ICal.ParameterPartstat.TENTATIVE:
                    status_label.label = _("Maybe");
                    status_label.add_css_class (Granite.CssClass.WARNING);
                    break;
                default:
                    break;
            }
        }

        remove_button.clicked.connect (() => {
            removed ();
            hide ();
            destroy ();
        });
    }

    private async void get_contact_by_mail (string mail_address) {
        var aggregator = Folks.IndividualAggregator.dup ();
        if (!aggregator.is_prepared) {
            aggregator.notify["is-quiescent"].connect (() => {
                get_contact_by_mail.begin (mail_address);
            });

            try {
                yield aggregator.prepare ();
            } catch (Error e) {
                critical (e.message);
            }

            return;
        }

        var map_iterator = aggregator.individuals.map_iterator ();
        while (map_iterator.next ()) {
            foreach (var address in map_iterator.get_value ().email_addresses) {
                if (address.value != mail_address) {
                    continue;
                }

                var individual = map_iterator.get_value ();
                if (individual == null) {
                    continue;
                }

                avatar.text = individual.display_name;

                if (individual.avatar != null) {
                    try {
                        individual.avatar.load (ICON_SIZE, null);
                        var avatar_image = new Gtk.Image.from_file (individual.avatar.to_string ()) {
                            width_request = avatar.size,
                            height_request = avatar.size
                        };

                        avatar.set_custom_image (new Gtk.WidgetPaintable (avatar_image));
                    } catch (Error e) {
                        critical (e.message);
                    }
                }

                if (individual.full_name != null && individual.full_name != "") {
                    name_label.label = Markup.escape_text (individual.full_name);
                    mail_label.label = Markup.escape_text (attendee.get_attendee ().replace ("mailto:", ""));
                }
            }
        }
    }
}
