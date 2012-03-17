//
//  Copyright (C) 2011-2012 Maxwell Barvian
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

namespace Maya.View {

	public class MayaToolbar : Gtk.Toolbar {

		public Gtk.ToolButton button_add { get; private set; }
		public Gtk.ToolButton edit_button { get; private set; }
		public Gtk.ToolButton delete_button { get; private set; }

		public Widgets.DateSwitcher month_switcher { get; private set; }
		public Widgets.DateSwitcher year_switcher { get; private set; }

		public Granite.Widgets.SearchBar search_bar { get; private set; }

		public Gtk.ToolButton button_calendar_sources { get; private set; }

		public Granite.Widgets.AppMenu app_menu { get; private set; }
		public MayaMenu menu { get; private set; }

		public Widgets.ContractorButtonWithMenu contractor { get; private set; }

		public MayaToolbar (DateTime target) {

			// Toolbar properties
			get_style_context ().add_class ("primary-toolbar"); // compliant with elementary HIG

			// Initialize everything
			button_add = make_toolbutton (Gtk.IconTheme.get_default ().has_icon ("event-new") ? "event-new" : "list-add", _("Create a new event"));

			edit_button = make_toolbutton ("edit", _("Edit the selected event"), false);
			delete_button = make_toolbutton ("edit-delete", _("Delete the selected event"), false);

            button_calendar_sources = make_toolbutton ("gtk-index", _("Select calendars to display"), true);

			month_switcher = new Widgets.DateSwitcher (10);
			year_switcher = new Widgets.DateSwitcher (-1);
            set_switcher_date (target);

			search_bar = new Granite.Widgets.SearchBar (_("Search For Events.."));
            search_bar.sensitive = false;

			contractor = new Widgets.ContractorButtonWithMenu (_("Export or Share the default Calendar"));

            menu = new MayaMenu ();
			app_menu = new Granite.Widgets.AppMenu (menu);

			// Insert into appropriate positions
			insert (button_add, -1);
			insert (edit_button, -1);
			insert (delete_button, -1);

			insert (make_spacer (), -1);

			insert (make_toolitem_from_widget (Util.set_paddings (month_switcher, 5, 0, 5, 0)), -1);
			insert (make_toolitem_from_widget (Util.set_paddings (year_switcher, 5, 0, 5, 10)), -1);

			insert (make_spacer (), -1);

			insert (make_toolitem_from_widget (search_bar), -1);

			insert (button_calendar_sources, -1);

			insert (contractor, -1);

			insert (app_menu, -1);
		}

		private Gtk.ToolButton make_toolbutton (string icon_name, string tooltip_text, bool sensitive = true,  bool can_focus = false) {

			var toolbutton = new Gtk.ToolButton (null, null);
			toolbutton.icon_name = icon_name;
			toolbutton.sensitive = sensitive;
			toolbutton.can_focus = can_focus;
			toolbutton.tooltip_text = tooltip_text;

			return toolbutton;
		}

		private Gtk.ToolItem make_spacer () {

			var spacer = new Gtk.ToolItem ();
			spacer.set_expand (true);

			return spacer;
		}

		private Gtk.ToolItem make_toolitem_from_widget (Gtk.Widget widget) {

			var toolitem = new Gtk.ToolItem ();
			toolitem.add (widget);

			return toolitem;
		}

        public void set_switcher_date (DateTime date) {
            month_switcher.text = date.format ("%B");
            year_switcher.text = date.format ("%Y");
        }

	}

}

