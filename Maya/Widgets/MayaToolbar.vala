//  
//  Copyright (C) 2011 Maxwell Barvian
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
using Gdk;

using Granite.Widgets;

using Maya;

namespace Maya.Widgets {

	public class MayaToolbar : Gtk.Toolbar {
	
		private MayaWindow window;
	
		public ToolButton add_button { get; private set; }
		public ToolButton edit_button { get; private set; }
		public ToolButton delete_button { get; private set; }
		
		public DateSwitcher month_switcher { get; private set; }
		public DateSwitcher year_switcher { get; private set; }
		
		public SearchBar search_bar { get; private set; }
		
		public AppMenu app_menu { get; private set; }
		
		public MayaToolbar (MayaWindow window) {
		
			this.window = window;
			
			// Toolbar properties
			get_style_context ().add_class ("primary-toolbar"); // compliant with elementary HIG
			
			// Initialize everything
			add_button = make_toolbutton (IconTheme.get_default ().has_icon ("event-new") ? "event-new" : "list-add",
					"Create a new event", false);
			edit_button = make_toolbutton ("gtk-edit", "Edit the selected event", false);
			delete_button = make_toolbutton ("edit-delete", "Delete the selected event", false);
			
			month_switcher = new DateSwitcher ();
			year_switcher = new DateSwitcher ();
			// Calculate the size of the month switcher
			/*var date = new DateTime.now_local ();
			int max_chars = 0;
			for (int month = 0; month < 12; month++) {
				int month_chars = date.format ("%B").length;
				if (month_chars > max_chars)
					max_chars = month_chars;
				date = date.add_months (1);
			}
			month_switcher.label.set_width_chars(20);
			debug ("max_chars = %i", max_chars);*/
			
			search_bar = new SearchBar ("Search for events...");
			
			app_menu = new AppMenu.from_stock (Stock.PROPERTIES, IconSize.MENU, "Menu", new MayaMenu (window));
			
			// Insert into appropriate positions
			insert (add_button, 0);
			insert (edit_button, 1);
			insert (delete_button, 2);
			
			insert (make_spacer (), 3);
			
			insert (make_toolitem_from_widget (Utilities.set_paddings (month_switcher, 5, 0, 5, 0)), 4);
			insert (make_toolitem_from_widget (Utilities.set_paddings (year_switcher, 5, 0, 5, 10)), 5);
			
			insert (make_spacer (), 6);
			
			insert (make_toolitem_from_widget (search_bar), 7);
			
			insert (app_menu, 8);
		}
		
		private ToolButton make_toolbutton (string icon_name, string tooltip_text, bool sensitive = true,  bool can_focus = false) {
			
			var toolbutton = new ToolButton (null, null);
			toolbutton.icon_name = icon_name;
			toolbutton.sensitive = sensitive;
			toolbutton.can_focus = can_focus;
			toolbutton.tooltip_text = tooltip_text;
			
			return toolbutton;
		}
		
		private ToolItem make_spacer () {
			
			var spacer = new ToolItem ();
			spacer.set_expand (true);
			
			return spacer;
		}
		
		private ToolItem make_toolitem_from_widget (Widget widget) {
		
			var toolitem = new ToolItem ();
			toolitem.add (widget);
			
			return toolitem;
		}
		
	}
	
}

