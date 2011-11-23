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

}
