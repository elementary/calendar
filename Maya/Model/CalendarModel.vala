namespace Maya.Model {

public class CalendarModel : Object {

    /* Target date is the date used to determine the start date of the
     * calendar. This does not have to be the first day of the month but can be
     * any date that is desired. */
    public DateTime target { get; set; }

    /* Usually Monday=1 or Sunday=7 */
    public Settings.Weekday week_starts_on { get; set; }

    /* The start and end dates for this model. The start date is in the same
     * week as target date. The only way to change the date ranges is to change
     * the target date, num_weeks, or week_starts_on. */
    public DateTime cal_date_start { get; private set; }
    public DateTime cal_date_end { get; private set; }

    /* The number of weeks to show in this model */
    public int num_weeks { get; set; default = 5; }

    /* The events for a source have been loaded and stored */
    public signal void source_loaded (E.Source source);

    /* The target or week_starts_on have been changed */
    public signal void parameters_changed ();

    Gee.Map<E.Source, E.CalClient> source_client;
    Gee.Map<E.Source, Gee.Set<E.CalComponent>> source_events;

    // more signals to be implemented
    //public signal void events_added();
    //public signal void events_modified();
    //public signal void events_removed();

    public CalendarModel (Gee.Collection<E.Source> sources, DateTime target, Settings.Weekday week_starts_on) {

        this.target = target;
        this.week_starts_on = week_starts_on;

        source_client = new Gee.HashMap<E.Source, E.CalClient> ();
        source_events = new Gee.HashMap<E.Source, Gee.Set<E.CalComponent>> ();
        
        // create clients for each source
        foreach (var source in sources) {

            var client = new E.CalClient(source, E.CalClientSourceType.EVENTS);
            source_client.set (source, client);
        }

        set_date_ranges ();
        load_events ();

        notify["target"].connect (set_date_ranges);
        notify["num_weeks"].connect (set_date_ranges);
        notify["week_starts_on"].connect (set_date_ranges);
    }

    public Gee.Set<E.CalComponent> get_events (E.Source source) {
        return (source_events.get(source) as Gee.AbstractSet<E.CalComponent>).read_only_view;
    }

    void set_date_ranges () {

        int dow = target.get_day_of_week(); 
        int wso = (int) week_starts_on;
        int offset = 0;

        if (wso < dow)
            offset = dow - wso;
        else if (wso > wso)
            offset = 7 + dow - wso;

        cal_date_start = target.add_days (-offset);
        cal_date_end = cal_date_start.add_weeks(num_weeks-1).add_days(6);

        debug(@"Date ranges set (f:$cal_date_start <= t:$target <= l:$cal_date_end)");

        parameters_changed ();
        load_events ();
    }

    void load_events () {
        
        var iso_first = E.isodate_from_time_t((ulong) cal_date_start.to_unix());
        var iso_last = E.isodate_from_time_t((ulong) cal_date_end.to_unix());

        var query = @"(occur-in-time-range? (make-time \"$iso_first\") (make-time \"$iso_last\"))";

        foreach (var source in source_client.keys) {

            debug("Loading events for source '%s'", source.peek_name());

            var client = source_client.get (source);

            client.get_object_list_as_comps.begin(query, null, (obj, results) => {
                on_events_received (results, source, client);
            });
        }
    }

    void on_events_received (AsyncResult results, E.Source source, E.CalClient client) {

        GLib.SList<E.CalComponent> ecalcomps;

        try {

            var status = client.get_object_list_as_comps.end(results, out ecalcomps);
            assert (status==true);

        } catch (Error e) {

            debug("Error loading events from source '%s': %s", source.peek_name(), e.message);
        }

        debug (@"Received $(ecalcomps.length()) events for source '%s'", source.peek_name());

        Gee.Set<E.CalComponent> events = new Gee.HashSet<E.CalComponent>();
        ecalcomps.foreach ((ecalcomp) => events.add (ecalcomp));

        source_events.set (source, events);

        source_loaded (source);
    }

    //--- SIGNAL HANDLERS ---//
    // on_e_cal_client_view_objects_added
    // on_e_cal_client_view_objects_removed
    // on_e_cal_client_view_objects_modified
}

}
