// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2017 elementary LLC (https://elementary.io)
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

namespace Calendar.View {

public enum EventType {
    ADD,
    EDIT
}

public class EventDialog : Gtk.Dialog {
        public E.Source? source { get; set; }
        public E.Source? original_source { get; private set; }
        public E.CalComponent ecal { get; set; }
        public DateTime date_time { get; set; }

        /**
         * A boolean indicating whether we can edit the current event.
         */
        public bool can_edit = true;

        private E.CalObjModType mod_type { get; private set; default = E.CalObjModType.ALL; }
        private EventType event_type { get; private set; }

        /**
         * The different widgets in the dialog.
         */
        private Gtk.Stack stack;
        private Granite.Widgets.ModeButton mode_button;

        private EventEdition.GuestsPanel guests_panel;
        private EventEdition.InfoPanel info_panel;
        private EventEdition.LocationPanel location_panel;
        private EventEdition.ReminderPanel reminder_panel;
        private EventEdition.RepeatPanel repeat_panel;

        public EventDialog (E.CalComponent? ecal = null, DateTime? date_time = null) {
            this.deletable = false;

            if (ecal != null)
                original_source = ecal.get_data<E.Source> ("source");
            this.date_time = date_time;

            this.ecal = ecal;

            if (date_time != null) {
                title = _("Add Event");
                event_type = EventType.ADD;
            } else {
                title = _("Edit Event");
                event_type = EventType.EDIT;
            }

            // Dialog properties
            window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
            type_hint = Gdk.WindowTypeHint.DIALOG;

            // Build dialog
            build_dialog (date_time != null);
        }

        //--- Public Methods ---//

        void build_dialog (bool add_event) {
            var grid = new Gtk.Grid ();
            grid.row_spacing = 6;
            grid.column_spacing = 12;
            stack = new Gtk.Stack ();
            guests_panel = new EventEdition.GuestsPanel (this);
            info_panel = new EventEdition.InfoPanel (this);
            location_panel = new EventEdition.LocationPanel (this);
            reminder_panel = new EventEdition.ReminderPanel (this);
            repeat_panel = new EventEdition.RepeatPanel (this);

            mode_button = new Granite.Widgets.ModeButton ();
            var info_icon = new Gtk.Image.from_icon_name ("office-calendar-symbolic", Gtk.IconSize.BUTTON);
            info_icon.tooltip_text = _("General Informations");
            mode_button.append (info_icon);
            var location_icon = new Gtk.Image.from_icon_name ("mark-location-symbolic", Gtk.IconSize.BUTTON);
            location_icon.tooltip_text = _("Location");
            mode_button.append (location_icon);
            var guests_icon = new Gtk.Image.from_icon_name ("system-users-symbolic", Gtk.IconSize.BUTTON);
            guests_icon.tooltip_text = _("Guests");
            mode_button.append (guests_icon);
            var reminder_icon = new Gtk.Image.from_icon_name ("alarm-symbolic", Gtk.IconSize.BUTTON);
            reminder_icon.tooltip_text = _("Reminders");
            mode_button.append (reminder_icon);
            var repeat_icon = new Gtk.Image.from_icon_name ("media-playlist-repeat-symbolic", Gtk.IconSize.BUTTON);
            repeat_icon.tooltip_text = _("Repeat");
            mode_button.append (repeat_icon);
            mode_button.selected = 0;
            mode_button.mode_changed.connect ((widget) => {
                switch (mode_button.selected) {
                    case 0:
                        stack.set_visible_child_name ("infopanel");
                        break;
                    case 1:
                        stack.set_visible_child_name ("locationpanel");
                        break;
                    case 2:
                        stack.set_visible_child_name ("guestspanel");
                        break;
                    case 3:
                        stack.set_visible_child_name ("reminderpanel");
                        break;
                    case 4:
                        stack.set_visible_child_name ("repeatpanel");
                        break;
                }
            });

            var handler = new Calendar.Services.EventParserHandler ();
            var parser = handler.get_parser (handler.get_locale ());
            if (handler.get_locale ().contains (parser.get_language ())) {
                // If there is handler for the current locale then...
                info_panel.nl_parsing_enabled = true;
                bool event_parsed = false;
                info_panel.parse_event.connect ((ev_str) => {
                    if (!event_parsed) {
                        var ev = parser.parse_source (ev_str);
                        info_panel.title = ev.title;
                        info_panel.from_date = ev.from;
                        info_panel.to_date = ev.to;
                        info_panel.from_time = ev.from;
                        info_panel.to_time = ev.to;
                        info_panel.all_day = ev.all_day;
                        guests_panel.guests = ev.participants;
                        location_panel.location = ev.location;
                        event_parsed = true;
                    }
                    else
                        save_dialog ();
                });
            }

            stack.add_named (info_panel, "infopanel");
            stack.add_named (location_panel, "locationpanel");
            stack.add_named (guests_panel, "guestspanel");
            stack.add_named (reminder_panel, "reminderpanel");
            stack.add_named (repeat_panel, "repeatpanel");

            var buttonbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            buttonbox.margin_top = 6;
            buttonbox.margin_end = 12;
            buttonbox.margin_start = 12;
            buttonbox.spacing = 6;

            buttonbox.baseline_position = Gtk.BaselinePosition.CENTER;
            buttonbox.set_layout (Gtk.ButtonBoxStyle.END);

            if (add_event == false) {
                var delete_button = new Gtk.Button.with_label (_("Delete Event"));
                delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                delete_button.clicked.connect (remove_event);
                buttonbox.add (delete_button);
                buttonbox.set_child_secondary (delete_button, true);
                buttonbox.set_child_non_homogeneous (delete_button, true);
            }

            Gtk.Button create_button = new Gtk.Button ();
            create_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            create_button.clicked.connect (save_dialog);
            if (add_event == true) {
                create_button.label = _("Create Event");
                create_button.sensitive = false;
            } else {
                create_button.label = _("Save Changes");
            }

            Gtk.Button cancel_button = new Gtk.Button.with_label (_("Cancel"));
            cancel_button.clicked.connect (() => {this.destroy ();});

            buttonbox.add (cancel_button);
            buttonbox.add (create_button);

            var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            top_box.set_center_widget (mode_button);

            grid.attach (top_box, 0, 0, 1, 1);
            grid.attach (stack, 0, 1, 1, 1);
            grid.attach (buttonbox, 0, 2, 1, 1);

            ((Gtk.Container)get_content_area ()).add (grid);

            info_panel.valid_event.connect ((is_valid) => {
                create_button.sensitive = is_valid;
            });

            show_all ();
            stack.set_visible_child_name ("infopanel");
        }

        public static Gtk.Label make_label (string text) {
            var label = new Gtk.Label ("<span weight='bold'>%s</span>".printf (text));
            label.use_markup = true;
            label.set_alignment (0.0f, 0.5f);
            return label;
        }

        private void save_dialog () {
            info_panel.save ();
            location_panel.save ();
            guests_panel.save ();
            reminder_panel.save ();
            repeat_panel.save ();

            var calmodel = Model.CalendarModel.get_default ();
            if (event_type == EventType.ADD)
                calmodel.add_event (source, ecal);
            else {
                assert (original_source != null);

                if (original_source.dup_uid () == source.dup_uid ()) {
                    // Same uids, just modify
                    calmodel.update_event (source, ecal, mod_type);
                } else {
                    // Different calendar, remove and readd
                    calmodel.remove_event (original_source, ecal, mod_type);
                    calmodel.add_event (source, ecal);
                }
            }

            this.destroy ();
        }

        private void remove_event () {
            var calmodel = Model.CalendarModel.get_default ();
            calmodel.remove_event (original_source, ecal, mod_type);
            this.destroy ();
        }
    }
}
