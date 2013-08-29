//
//  Copyright (C) 2011-2012 Jaap Broekhuizen
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

#if USE_GRANITE_DECORATED_WINDOW
public class Maya.View.SourceDialog : Granite.Widgets.LightWindow {
#else
public class Maya.View.SourceDialog : Gtk.Window {
#endif

    public EventType event_type { get; private set; default=EventType.EDIT;}

    public SourceDialog (Gtk.Window window, E.Source? source = null, bool? add_source = false) {
        if (add_source == true) {
            event_type = EventType.ADD;
        }
        
        
        
    }

    //--- Public Methods ---//
}
