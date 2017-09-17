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
 * Authored by: Maxwell Barvian
 */

using Gtk;

namespace Calendar.Widgets {

	public class Utilities {
	
		public static Widget set_margins (Widget widget, int top, int right, int bottom, int left) {
			
			widget.margin_top = top;
			widget.margin_right = right;
			widget.margin_bottom = bottom;
			widget.margin_left = left;
			
			return widget;
		}
		
		public static Alignment set_paddings (Widget widget, int top, int right, int bottom, int left) {
		
			var alignment = new Gtk.Alignment (0.0f, 0.0f, 1.0f, 1.0f);
			alignment.top_padding = top;
			alignment.right_padding = right;
			alignment.bottom_padding = bottom;
			alignment.left_padding = left;
		
			alignment.add (widget);
			return alignment;
		}
		
	}
	
}

