/*
 Copyright (C) 2011 Christian Dywan <christian@twotoasts.de>

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 See the file COPYING for the full license text.
*/

namespace Maya.View.Widgets {
    public class GuestEntry : FlowBox {
        public Granite.Widgets.HintedEntry entry;
        bool invalidated = true;
        string real_text;
        string hintedentry_text;
        public string text { get { return get_real_text (); } }
        public bool empty { get; private set; default = true; }

        unowned string get_real_text () {
            if (invalidated) {
                real_text = "";
                foreach (var button in get_children ())
                    real_text += "," + button.tooltip_text;
                if (real_text.has_prefix (","))
                    real_text = real_text.substring (1, -1);
                real_text += entry.text;
                if (real_text.has_suffix (","))
                    real_text = real_text.slice (0, -1);
            }
            return real_text;
        }

        public Gee.ArrayList<string> get_addresses () {
            Gee.ArrayList<string> result = new Gee.ArrayList<string> ();

            foreach (var button in get_children ()) {
                if (button.tooltip_text != null)
                    result.add (button.tooltip_text);
            }

            return result;
        }

        public GuestEntry (string? tooltext_entry) {
            hintedentry_text = tooltext_entry;
            entry = new Granite.Widgets.HintedEntry (hintedentry_text);
            entry.show ();
            add (entry);
            var completion = new Gtk.EntryCompletion ();
            completion.model = new Gtk.ListStore (1, typeof (string));
            completion.text_column = 0;
            completion.set_match_func (match_function);
            completion.match_selected.connect (match_selected);
            completion.inline_completion = true;
            completion.inline_selection = true;
            entry.set_completion (completion);
            entry.changed.connect (changed);
            entry.key_press_event.connect ((widget, event) => {
                if (event.keyval == Gdk.keyval_from_name ("Return")) {
                    entry.text = entry.text + ",";
                    buttonize_text ();
                }
                return false;
            });
            entry.focus_out_event.connect ((widget, event) => {
                if (entry.text == "")
                    return false;
                entry.text = entry.text + ",";
                buttonize_text ();
                return false;
            });
            entry.backspace.connect ((entry) => {
                var model = entry.get_completion ().model as Gtk.ListStore;
                model.clear ();

                if (entry.get_position () == 0 && get_children ().nth_data (1) != null) {
                    var last_button = get_children ().last ().prev.data;
                    string address = last_button.get_tooltip_text ();
                    last_button.destroy ();
                    entry.text = entry.text + (entry.text != "" ? "," : "") + address;
                    entry.set_position (-1);
                }
            });
            entry.delete_from_cursor.connect ((entry, type, count) => {
                var model = entry.get_completion ().model as Gtk.ListStore;
                model.clear ();
            });

        }

        bool match_function (Gtk.EntryCompletion completion, string key,
            Gtk.TreeIter iter) {

            var model = completion.model as Gtk.ListStore;
            string? contact;
            model.get (iter, 0, out contact);
            if (contact == null)
                return false;
            string? normalized = contact.normalize (-1, NormalizeMode.ALL);
            if (normalized != null) {
                string? casefolded = normalized.casefold (-1);
                if (casefolded != null)
                    return key in casefolded;
            }
            return false;
        }

        public void add_address (string address) {
            if (address == "")
                return;

            var content_grid = new Gtk.Grid();
            var label = new Gtk.Label (Contact.name_from_string (address));
            content_grid.attach (label, 0, 0, 1, 1);
            var icon = new Gtk.Image.from_stock (Gtk.Stock.CLOSE, Gtk.IconSize.MENU);
            content_grid.attach (icon, 1, 0, 1, 1);
            var button = new Gtk.Button ();
            button.add (content_grid);
            button.set_tooltip_text (address);
            button.clicked.connect ((button) => {
                button.destroy ();
            });
            button.key_press_event.connect ((button, event) => {
                if (event.keyval == Gdk.keyval_from_name ("Delete"))
                    button.destroy ();
                else if (event.keyval == Gdk.keyval_from_name ("BackSpace")) {
                    entry.text = "," + button.tooltip_text;
                    button.destroy ();
                }
                return false;
            });
            button.destroy.connect ((button) => {
                invalidated = true;
                entry.grab_focus ();
                if (get_children ().nth_data (1) == null)
                    empty = true;
            });
            button.show_all ();
            add (button);
            reorder_child (entry, -1);
            empty = false;
        }

        bool match_selected (Gtk.EntryCompletion completion, Gtk.TreeModel model,
            Gtk.TreeIter iter) {

            string address;
            model.get (iter, completion.text_column, out address);

            entry.text = "";
            add_address (address);
            entry.grab_focus ();
            return true;
        }

        void buttonize_text () {
            string[] addresses = entry.text.split (",");
            entry.text = "";
            foreach (string address in addresses)
                add_address (address);
        }

        void changed (Gtk.Editable editable) {
            invalidated = true;
            /* Turn proper address into button when appending a comma */
            if (entry.text.has_suffix (",")) {
                buttonize_text ();
                return;
            }

            if (entry.text.length < 3)
                return;
            var model = entry.get_completion ().model as Gtk.ListStore;
            if (model.iter_n_children (null) > 0)
                return;
            autocomplete (entry.text, model);
        }

        async void autocomplete (string input, Gtk.ListStore model) {
            var client = new Maya.Services.Dexter ();
            string[] contacts = client.autocomplete_contact (input);
            foreach (string contact in contacts) {
                Gtk.TreeIter iter;
                model.append (out iter);
                model.set (iter, 0, contact);
            }
        }
    }
}
