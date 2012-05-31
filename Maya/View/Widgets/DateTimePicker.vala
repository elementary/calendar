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

using Granite.Widgets;

namespace Maya.View.Widgets {

    public class DateTimePicker : Gtk.Grid {
    
        public DateTime date_time {
            owned get { return new DateTime.local (date_picker.date.get_year (), date_picker.date.get_month (),
                    date_picker.date.get_day_of_month (), time_picker.time.get_hour (), time_picker.time.get_minute (),
                    time_picker.time.get_second ()); }
        }
        
        public DatePicker date_picker { get; private set; }
        public TimePicker time_picker { get; private set; }
        
        public DateTimePicker () {
                
            date_picker = new DatePicker ();
            time_picker = new TimePicker ();
            
            // Grid properties
            set_column_spacing (10);
            set_column_homogeneous (false);
            
            attach (date_picker, 0, 0, 1, 1);
            attach (time_picker, 1, 0, 1, 1);
        }
        
    }
    
}

