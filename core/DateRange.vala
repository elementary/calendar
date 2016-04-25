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

namespace Maya.Util {
    /* Iterator of DateRange objects */
    public class DateIterator : Object, Gee.Traversable<DateTime>, Gee.Iterator<DateTime> {
        DateTime current;
        DateRange range;

        public bool valid { get {return true;} }
        public bool read_only { get {return false;} }

        public DateIterator (DateRange range) {
            this.range = range;
            this.current = range.first.add_days (-1);
        }

        public bool @foreach (Gee.ForallFunc<DateTime> f) {
            var element = range.first;

            while (element.compare (range.last) < 0) {
                if (f (element) == false) {
                    return false;
                }

                element = element.add_days (1);
            }

            return true;
        }

        public bool next () {
            if (! has_next ())
                return false;
            current = this.current.add_days (1);
            return true;
        }

        public bool has_next() {
            return current.compare(range.last) < 0;
        }

        public bool first () {
            current = range.first;
            return true;
        }

        public new DateTime get () {
            return current;
        }

        public void remove() {
            assert_not_reached();
        }
    }

    /* Represents date range from 'first' to 'last' inclusive */
    public class DateRange : Object, Gee.Traversable<DateTime>, Gee.Iterable<DateTime> {
        public DateTime first { get; private set; }
        public DateTime last { get; private set; }
        public bool @foreach (Gee.ForallFunc<DateTime> f) {
            foreach (var date in this) {
                if (f (date) == false) {
                    return false;
                }
            }

            return true;
        }

        public int64 days {
            get { return last.difference (first) / GLib.TimeSpan.DAY; }
        }

        public DateRange (DateTime first, DateTime last) {
            this.first = first;
            this.last = last;
        }

        public DateRange.copy (DateRange date_range) {
            this (date_range.first, date_range.last);
        }

        public bool equals (DateRange other) {
            return (first==other.first && last==other.last);
        }

        public Type element_type {
            get { return typeof(DateTime); }
        }

        public Gee.Iterator<DateTime> iterator () {
            return new DateIterator (this);
        }

        public bool contains (DateTime time) {
            return (first.compare (time) < 1) && (last.compare (time) > -1);
        }

        public Gee.SortedSet<DateTime> to_set() {

            var @set = new Gee.TreeSet<DateTime> ((GLib.CompareDataFunc<GLib.DateTime>?) DateTime.compare);

            foreach (var date in this)
                set.add (date);

            return @set;
        }

        public Gee.List<DateTime> to_list () {
            var list = new Gee.ArrayList<DateTime> ((Gee.EqualDataFunc<GLib.DateTime>?) datetime_equal_func);
            foreach (var date in this)
                list.add (date);

            return list;
        }
    }
}
