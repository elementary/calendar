public class Maya.Backend : Object
{
    E.CalClient ecal;
    public Backend ()
    {
        ecal = new E.CalClient.system(E.CalClientSourceType.EVENTS);
    }

    public void launch_thread ()
    {
        Idle.add( () => {
        try
        {
            // Start thread
            unowned Thread<void*> thread = Thread.create<void*> (startup_async, false);
        }
        catch (ThreadError e)
        {
            stderr.printf ("%s\n", e.message);
        } return false; });
    }


    void* startup_async ()
    {
        print("Enter threaded function.\n");
        print("Loading the calendar...\n");
        /* Is this part reall necessary? */
        try { ecal.open_sync(false, null); }
        catch (Error e) { error("Couldn't open the calendar: %s", e.message); }
        
        print("Calendar opened\n");

        List<icalcomponent> list_events = new List<icalcomponent>();
        ecal.get_object_list_sync ("#t", out list_events);

        foreach(unowned icalcomponent ical in list_events)
            print("one event");

        string uid;
        //if(ecal.create_object_sync(new icalcomponent.vevent(), out uid))
        //    print("Creation managed! %s\n", uid);

        debug("Leave threaded function.");
        return null;
    }
}
