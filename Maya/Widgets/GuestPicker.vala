//  
//  Copyright (C) 2011 Christian Dywan <christian@twotoasts.de>
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

using Gtk;

using Granite.Widgets;

using Maya.Services;

namespace Maya.Widgets {

	public class GuestPicker : FlowBox {
	
		Dexter dexter;

		public Gtk.Entry entry;
		bool invalidated = true;
		string real_text;
		public string text {
			get { return get_real_text (); }
		}
		
		public bool empty { get; protected set; default = true; }

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

		public GuestPicker () {
		
			dexter = new Dexter ();
			entry = new Entry ();
			
			var completion = new EntryCompletion ();
			completion.model = new ListStore (1, typeof (string));
			completion.text_column = 0;
			completion.set_match_func (match_function);
			completion.match_selected.connect (match_selected);
			completion.inline_completion = true;
			completion.inline_selection = true;
			entry.set_completion (completion);
			
			add (entry);
			
			// Signals and callbacks
			entry.changed.connect (on_changed);
			entry.focus_out_event.connect ((widget, event) => {
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
				}
			});
			entry.delete_from_cursor.connect ((entry, type, count) => {
				var model = entry.get_completion ().model as Gtk.ListStore;
				model.clear ();
			});
		}

		protected virtual bool match_function (EntryCompletion completion, string key, TreeIter iter) {

			var model = completion.model as ListStore;
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

		protected virtual void add_address (string address) {
		
			if (address == "")
				return;
			/* Don't turn invalid addresses into buttons */
			if (!address.contains ("@") || address.has_suffix ("@")) {
				entry.text = entry.text + (entry.text != "" ? "," : "") + address;
				return;
			}

			string[] parsed = parse_address (address);
			var box = new Gtk.HBox (false, 0);
			var label = new Gtk.Label (parsed[0]);
			box.pack_start (label, true, false, 0);
			var icon = new Gtk.Image.from_stock (Gtk.Stock.CLOSE, Gtk.IconSize.MENU);
			box.pack_end (icon, false, false, 0);
			var button = new Gtk.Button ();
			button.add (box);
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
			add (button);
			reorder_child (entry, -1);
			button.show_all ();
			empty = false;
		}

		protected virtual bool match_selected (EntryCompletion completion, TreeModel model, TreeIter iter) {

			string address;
			model.get (iter, completion.text_column, out address);
			
			entry.text = "";
			add_address (address);
			entry.grab_focus ();
			return true;
		}

		protected virtual void buttonize_text () {
		
			if (entry.text.index_of_char ('@') != -1) {
				string[] addresses = entry.text.split (",");
				entry.text = "";
				foreach (string address in addresses)
					add_address (address);
			}
		}
		
		protected virtual string[] parse_address (string address)
			ensures (result[0] != null && result[1] != null) {
			
			if (address.length < 1) {
				critical ("parse_address: assertion '!address.length < 1' failed");
				return { address, address };
			}

			if (!(">" in address && "<" in address))
				return { address, address };

			long greater = address.length - 1;
			while (address[greater] != '>')
				greater--;
			long lower = greater;
			while (address[lower] != '<')
				lower--;

			string recipient = address.slice (lower + 1, greater);
			if (recipient.has_prefix ("mailto:"))
				recipient = recipient.substring (7, -1);
			if (lower == 0)
				return { recipient, recipient };
			/* TODO: Parse multiple addresses */
			if (">" in recipient)
				return { recipient, recipient };

			/* Remove double or single quotes around the name */
			long first = address.has_prefix ("'") || address.has_prefix ("\"") ? 1 : 0;
			return { address.substring (first, lower - 1)
				.replace ("\\\"", "`")
				.replace ("' ", "").replace ("\"", "").chomp (), recipient };
		}

		protected virtual void on_changed (Editable editable) {
		
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
			string[] contacts = dexter.autocomplete_contact (entry.text);
			foreach (string contact in contacts) {
				Gtk.TreeIter iter;
				model.append (out iter);
				model.set (iter, 0, contact);
			}
		}
		
	}
	
}

