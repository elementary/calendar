public class Maya.Backend.Main : Object
{
    E.CalClient ecal;
    public Main ()
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
            }
            return false;
        });
    }


    void* startup_async ()
    {
        lock(ecal)
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
            {
                print("one event: %s\n", ical.description);
            }
        }
        return null;
    }


    public void create_event(Event event)
    {
        lock(ecal)
        {
            string uid;
            var ical = new icalcomponent.vevent();
            ical.description = event.name;
            ecal.create_object_sync(ical, out uid);
        }
    }
}

public class Maya.Backend.Event {
    public Event ()
    {
    }
    public string name { get; set; }
}
