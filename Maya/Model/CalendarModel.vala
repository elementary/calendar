namespace Maya.Model {

public class CalendarModel : Object {

    /* The data_range is the range of dates for which this model is storing
     * data. The month_range is a subset of this range corresponding to the
     * calendar month that is being focused on. In summary:
     *
     * data_range.first <= month_range.first < month_range.last <= data_range.last
     *
     * There is no way to set the ranges publicly. They can only be modified by
     * changing one of the following properties: month_start, num_weeks, and
     * week_starts_on.
    */
    public DateRange data_range { get; private set; }
    public DateRange month_range { get; private set; }

    /* The first day of the month */
    public DateTime month_start { get; set; }

    /* The number of weeks to show in this model */
    public int num_weeks { get; set; default = 6; }

    /* The start of week, ie. Monday=1 or Sunday=7 */
    public Settings.Weekday week_starts_on { get; set; }

    /* The events for a source have been loaded or unloaded */
    public signal void source_loaded (E.Source source);
    public signal void source_unloaded (E.Source source);

    /* The month_start, num_weeks, or week_starts_on have been changed */
    public signal void parameters_changed ();

    Gee.Map<E.Source, E.CalClient> source_client;
    Gee.Map<E.Source, Gee.Set<E.CalComponent>> source_events;

    // more signals to be implemented
    //public signal void events_added();
    //public signal void events_modified();
    //public signal void events_removed();

    public CalendarModel (Model.SourceSelectionModel source_model, Settings.Weekday week_starts_on) {

        this.month_start = get_start_of_month ();
        this.week_starts_on = week_starts_on;

        compute_ranges ();

        source_client = new Gee.HashMap<E.Source, E.CalClient> ();
        source_events = new Gee.HashMap<E.Source, Gee.Set<E.CalComponent>> ();

        var sources = source_model.enabled_sources;
        foreach (var source in sources) {
            add_source (source);
        }

        // Signals

        source_model.status_changed.connect (on_source_status_changed);
        source_model.source_added.connect (on_source_added);
        source_model.source_removed.connect (on_source_removed);

        notify["month-start"].connect (on_parameter_changed);
        notify["num-weeks"].connect (on_parameter_changed);
        notify["week-starts-on"].connect (on_parameter_changed);
    }

    public Gee.Collection<E.CalComponent> get_events (E.Source source) {
        return (source_events.get(source) as Gee.AbstractSet<E.CalComponent>).read_only_view;
    }

    void on_parameter_changed () {

        compute_ranges ();
        parameters_changed ();

        load_all_source_events ();
    }

    void compute_ranges () {

        int dow = month_start.get_day_of_week(); 
        int wso = (int) week_starts_on;
        int offset = 0;

        if (wso < dow)
            offset = dow - wso;
        else if (wso > dow)
            offset = 7 + dow - wso;

        var data_range_first = month_start.add_days (-offset);
        var data_range_last = data_range_first.add_weeks(num_weeks-1).add_days(6);

        data_range = new DateRange (data_range_first, data_range_last);

        var month_end = month_start.add_full (0, 1, -1);
        month_range = new DateRange (month_start, month_end);

        debug(@"Date ranges: ($data_range_first <= $month_start < $month_end <= $data_range_last)");
    }

    void load_all_source_events () {

        foreach (var source in source_client.keys)
            load_source_events (source);
    }

    void load_source_events (E.Source source) {
        
        debug("Loading events for source '%s'", source.peek_name());

        var iso_first = E.isodate_from_time_t((ulong) data_range.first.to_unix());
        var iso_last = E.isodate_from_time_t((ulong) data_range.last.to_unix());

        var query = @"(occur-in-time-range? (make-time \"$iso_first\") (make-time \"$iso_last\"))";

        var client = source_client.get (source);

        client.get_object_list_as_comps.begin(query, null, (obj, results) => {
            on_events_received (results, source, client);
        });
    }

    void add_source (E.Source source) {

        var client = new E.CalClient(source, E.CalClientSourceType.EVENTS);
        source_client.set (source, client);
        load_source_events (source);
    }

    void remove_source (E.Source source) {

        source_client.unset (source);
        source_events.unset (source);
        source_unloaded (source);
    }

    //--- SIGNAL HANDLERS ---//

    void on_source_status_changed (E.Source source, bool enabled) {

        if (enabled)
            add_source (source);
        else
            remove_source (source);
    }

    void on_source_added (E.SourceGroup group, E.Source source) {

        add_source (source);
    }

    void on_source_removed (E.SourceGroup group, E.Source source) {
        
        remove_source (source);
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

    // on_e_cal_client_view_objects_added
    // on_e_cal_client_view_objects_removed
    // on_e_cal_client_view_objects_modified
}

}
