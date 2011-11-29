namespace Maya {

public class DateIterator : Object, Gee.Iterator<DateTime> {

    DateTime current;
    DateRange range;

    public DateIterator (DateRange range) {
        this.range = range;
        this.current = range.first.add_days (-1);
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
public class DateRange : Object, Gee.Iterable<DateTime> {

    public DateTime first { get; private set; }
    public DateTime last { get; private set; }

    public DateRange (DateTime first, DateTime last) {
        assert (first.compare(last)==-1);
        this.first = first;
        this.last = last;
    }

    public Type element_type {
        get { return typeof(DateTime); }
    }

    public Gee.Iterator<DateTime> iterator () {
        return new DateIterator (this);
    }
}

public DateTime convert_to_datetime (E.CalComponentDateTime dt) {

    iCal.icaltimetype* idt = dt.value;
    var tz = new TimeZone (dt.tzid);

    return new DateTime(tz, idt->year, idt->month, idt->day, idt->hour, idt->minute, idt->second);
}


/* Computes hash value for E.Source */
public uint source_hash_func (E.Source key) {
    return str_hash (key.peek_uid());
}

/* Computes hash value for E.SourceGroup */
public uint source_group_hash_func (E.SourceGroup key) {
    return str_hash (key.peek_uid());
}

/* Returns true if 'a' and 'b' are the same E.SourceGroup */
public bool source_group_equal_func (E.SourceGroup a, E.SourceGroup b) {
    return a.peek_uid() == b.peek_uid();
}

/* Returns true if 'a' and 'b' are the same E.Source */
public bool source_equal_func (E.Source a, E.Source b) {
    return a.peek_uid() == b.peek_uid();
}

public Gtk.TreePath? find_treemodel_object<T> (Gtk.TreeModel model, int column, T object, EqualFunc<T>? eqfunc=null) {

    Gtk.TreePath? path = null;

    model.foreach( (m, p, iter) => {
        
        Value gvalue;
        model.get_value (iter, column, out gvalue);

        T ovalue = gvalue.get_object();

        if (   (eqfunc == null && ovalue == object)
            || (eqfunc != null && eqfunc(ovalue, object))) {
            path = p;
            return true;
        }

        return false;
    });

    return path;
}

}
