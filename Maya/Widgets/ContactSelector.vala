//  
//  Copyright (C) 2011 Jaap Broekhuizen
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

    public struct Contact {
        string name;
        string email_adress;
    }

	public class ContactSelector : Granite.Widgets.HintedEntry {
	
	    private List<Contact?> contacts;
	    
	    private Dexter dexter;
	    
		public ContactSelector (string hint_string) {
		    
		    base (hint_string);
		   
		    dexter = new Dexter ();
		
		    // Signals and callbacks
		    changed.connect (on_change);
		}
		
		private void on_change () {
		    
		    string text = get_text ();
		    string[] matches = dexter.autocomplete_contact (text);
		    
		    if (text != "" && matches.length == 1) {
		        print (matches[0] + "\n");
		        set_text (matches[0]);
		    }
		}
		
		
	}
	
}

