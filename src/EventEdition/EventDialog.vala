// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright 2011-2021 elementary, Inc. (https://elementary.io)
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

namespace Maya.View {

public enum EventType {
    ADD,
    EDIT
}

public class EventDialog : Granite.Dialog {
        public E.Source? source { get; set; }
        public E.Source? original_source { get; private set; }
        public ECal.Component ecal { get; set; } // Set by InfoPanel if null
        public ECal.Component original_ecal { get; private set; }
        public DateTime date_time { get; set; }

        private ECal.ObjModType mod_type { get; private set; default = ECal.ObjModType.ALL; }
        private EventType event_type { get; private set; }

        private EventEdition.GuestsPanel guests_panel;
        private EventEdition.InfoPanel info_panel;
        private EventEdition.LocationPanel location_panel;
        private EventEdition.ReminderPanel reminder_panel;
        private EventEdition.RepeatPanel repeat_panel;

        public EventDialog (ECal.Component? ecal = null, DateTime? date_time = null, Gtk.Window parent) {
            this.deletable = false;
            this.modal = true;
            this.transient_for = parent;

            if (ecal != null) {
                original_source = ecal.get_data<E.Source> ("source");
            }

            this.ecal = ecal;
            this.date_time = date_time;

            original_ecal = Util.copy_ecal_component (ecal);

            if (date_time != null) {
                title = _("Add Event");
                event_type = EventType.ADD;
            } else {
                title = _("Edit Event");
                event_type = EventType.EDIT;
            }

            guests_panel = new EventEdition.GuestsPanel (ecal.get_icalcomponent ());
            info_panel = new EventEdition.InfoPanel (this);
            location_panel = new EventEdition.LocationPanel (this);
            reminder_panel = new EventEdition.ReminderPanel (this);
            repeat_panel = new EventEdition.RepeatPanel (this);

            var handler = new Maya.Services.EventParserHandler ();
            var parser = handler.get_parser (handler.get_locale ());
            if (handler.get_locale ().contains (parser.get_language ())) {
                // If there is handler for the current locale then...
                info_panel.nl_parsing_enabled = true;
                bool event_parsed = false;
                info_panel.parse_event.connect ((ev_str) => {
                    if (!event_parsed) {
                        var ev = parser.parse_source (ev_str);
                        info_panel.title = ev.title;

                        if (ev.date_parsed) {
                            info_panel.from_date = ev.from;
                            info_panel.to_date = ev.to;
                        }

                        if (ev.time_parsed) {
                            info_panel.from_time = ev.from;
                            info_panel.to_time = ev.to;
                        }

                        if (ev.all_day != null) {
                            info_panel.all_day = ev.all_day;
                        }

                        guests_panel.guests += ev.participants;

                        if (ev.location.length > 0) {
                            location_panel.location = ev.location;
                        }

                        event_parsed = true;
                    }
                    else
                        save_dialog ();
                });
            }

            var stack = new Gtk.Stack ();
            stack.add_titled (info_panel, "infopanel", _("General Informations"));
            stack.add_titled (location_panel, "locationpanel", _("Location"));
            stack.add_titled (guests_panel, "guestspanel", _("Invitees"));
            stack.add_titled (reminder_panel, "reminderpanel", _("Reminders"));
            ///Translators: The name of the repeat panel tab
            stack.add_titled (repeat_panel, "repeatpanel", C_("Section Header", "Repeat")); //vala-lint=space-before-paren

            stack.get_page (info_panel).set_property ("icon-name", "office-calendar-symbolic");
            stack.get_page (location_panel).set_property ("icon-name", "mark-location-symbolic");
            stack.get_page (guests_panel).set_property ("icon-name", "system-users-symbolic");
            stack.get_page (reminder_panel).set_property ("icon-name", "alarm-symbolic");
            stack.get_page (repeat_panel).set_property ("icon-name", "media-playlist-repeat-symbolic");

            var stack_switcher = new Gtk.StackSwitcher () {
                margin_end = 12,
                margin_start = 12,
                stack = stack
            };
            ((Gtk.BoxLayout) stack_switcher.layout_manager).homogeneous = true;

            var buttonbox = new Gtk.Box (HORIZONTAL, 6) {
                baseline_position = CENTER,
                margin_end = 12,
                margin_start = 12
            };

            if (date_time == null) {
                var delete_button = new Gtk.Button.with_label (_("Delete Event…")) {
                    halign = START,
                    hexpand = true
                };
                delete_button.add_css_class (Granite.CssClass.DESTRUCTIVE);
                delete_button.clicked.connect (remove_event);

                buttonbox.append (delete_button);
            }

            var create_button = new Gtk.Button ();
            create_button.add_css_class (Granite.CssClass.SUGGESTED);
            create_button.clicked.connect (save_dialog);

            if (date_time != null) {
                create_button.label = _("Create Event");
                create_button.sensitive = false;
            } else {
                create_button.label = _("Save Changes");
            }

            var cancel_button = new Gtk.Button.with_label (_("Cancel"));
            cancel_button.clicked.connect (() => {this.destroy ();});

            buttonbox.append (cancel_button);
            buttonbox.append (create_button);

            var button_sizegroup = new Gtk.SizeGroup (HORIZONTAL);
            button_sizegroup.add_widget (cancel_button);
            button_sizegroup.add_widget (create_button);

            var box = new Granite.Box (VERTICAL, DOUBLE);
            box.append (stack_switcher);
            box.append (stack);
            box.append (buttonbox);

            get_content_area ().append (box);

            info_panel.valid_event.connect ((is_valid) => {
                create_button.sensitive = is_valid;
            });

            stack.set_visible_child_name ("infopanel");
        }

        private void save_dialog () {
            info_panel.save ();
            location_panel.save ();
            guests_panel.save ();
            reminder_panel.save ();
            repeat_panel.save ();

            var calmodel = Calendar.EventStore.get_default ();
            if (event_type == EventType.ADD) {
                calmodel.add_event (source, ecal);
            } else {
                assert (original_source != null);

                if (original_source.dup_uid () == source.dup_uid ()) {
                    // Same source, just modify
                    calmodel.update_event (source, ecal, mod_type);
                } else {
                    // Different calendar remove and re-add
                    calmodel.remove_event (original_source, original_ecal, mod_type);
                    calmodel.add_event (source, ecal);
                }
            }

            this.destroy ();
        }

        private void remove_event () {
            assert (original_source != null);
            var delete_dialog = new Calendar.DeleteEventDialog (original_source, ecal, mod_type) {
                modal = true,
                transient_for = this
            };

            delete_dialog.response.connect ((response) => {
                if (response == Gtk.ResponseType.YES) {
                    close ();
                }
            });

            delete_dialog.present ();

        }
    }
}
