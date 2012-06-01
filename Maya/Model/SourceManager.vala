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

namespace Maya.Model {

public class SourceManager: GLib.Object {

    Gee.List<E.SourceGroup> _groups;
    public Gee.List<E.SourceGroup> groups {
        owned get { return _groups.read_only_view; }
    }

    Gee.Map<E.SourceGroup, Gtk.TreeModelSort> _group_tree_model;

    /* A source has been enabled or disabled */
    public signal void status_changed (E.Source source, bool enabled);

    /* A source has been added to EDS */
    public signal void source_added (E.SourceGroup group, E.Source source);

    /* A source has been removed from EDS */
    public signal void source_removed (E.SourceGroup group, E.Source source);

    E.SourceList source_list;
    Gee.MultiMap<E.SourceGroup, E.Source> group_sources;
    Gee.Map<E.Source, bool> source_enabled;

    public E.Source DEFAULT_SOURCE { get; private set; }

    E.SourceGroup? GROUP_LOCAL { get; set; }
    E.SourceGroup? GROUP_REMOTE { get; set; }
    E.SourceGroup? GROUP_CONTACTS { get; set; }

    public SourceManager () {

        bool status = false;
        
        try {
        status = E.CalClient.get_sources (out source_list, E.CalClientSourceType.EVENTS);
        } catch(Error e) {
            warning (e.message);
        }
        assert (status==true);


        source_enabled = new Gee.HashMap<E.Source, bool> (
            (HashFunc) Util.source_hash_func,
            (EqualFunc) Util.source_equal_func,
            null);

        var settings = new Settings.MayaSettings();

        /* Ensure the groups actually exist */
        source_list.ensure_group(_("On this computer"), "local:", false);
        source_list.ensure_group(_("Webcal"), "webcal://", false);
        source_list.ensure_group(_("Contacts"), "contacts://", false);
        GROUP_LOCAL = source_list.peek_group_by_base_uri("local:");
        GROUP_REMOTE = source_list.peek_group_by_base_uri("webcal://");
        GROUP_CONTACTS = source_list.peek_group_by_base_uri("contacts://");
        /* If we don't have any source, let's add at least one */
        if(GROUP_LOCAL.peek_sources().length() == 0) {
            var source = new E.Source (_("Personal"), "system");
            GROUP_LOCAL.add_source (source, 0);
        }
        /* Set the default calendar from the configuration keys, if it doesn't exist, attribute one */
        if (settings.primary_calendar != "") {
            DEFAULT_SOURCE = source_list.peek_source_by_uid(settings.primary_calendar);
        }
        if (DEFAULT_SOURCE==null) {
            try {
                DEFAULT_SOURCE = (new E.CalClient.system (E.CalClientSourceType.EVENTS)).get_source ();
            } catch(Error e) {
                warning (e.message);
            }
            settings.primary_calendar = DEFAULT_SOURCE.peek_uid();
            string[] selected_calendars_copy = settings.selected_calendars;
            selected_calendars_copy += DEFAULT_SOURCE.peek_uid ();
            settings.selected_calendars = selected_calendars_copy;
        }
        assert (DEFAULT_SOURCE!=null);

        // the order that groups will appear
        _groups = new Gee.ArrayList<E.SourceGroup> ((EqualFunc) Util.source_group_equal_func);

//        foreach (E.SourceGroup group in source_list.peek_groups()) {
//            
//            _groups.add (group);
//        }
        _groups.add (GROUP_LOCAL);
        _groups.add (GROUP_REMOTE);
        _groups.add (GROUP_CONTACTS);

        group_sources = new Gee.HashMultiMap<E.SourceGroup, E.Source> (
            (HashFunc) Util.source_group_hash_func,
            (EqualFunc) Util.source_group_equal_func,
            (HashFunc) Util.source_hash_func,
            (EqualFunc) Util.source_equal_func);

        _group_tree_model = new Gee.HashMap<E.SourceGroup, Gtk.TreeModelSort> (
            (HashFunc) Util.source_group_hash_func,
            (EqualFunc) Util.source_group_equal_func,
            null);

        foreach (E.SourceGroup group in _groups) {

            debug("Processing source group '%s'", group.peek_name());

            group.source_added.connect ((source) => add_source (group, source));
            group.source_removed.connect ((source) => remove_source (group, source));

            var list_store = new Gtk.ListStore.newv ( {typeof(E.Source)} );
            var tree_model = new Gtk.TreeModelSort.with_model (list_store);
            _group_tree_model.set (group, tree_model);

            tree_model.set_default_sort_func (tree_model_sort_func);

            foreach (E.Source source in group.peek_sources()) {

                add_source (group, source);
            }
        }

    }

    /**
     * The given group is added to the list of groups and will thus be persisted.
     */
    public void create_group (E.SourceGroup group) {
        source_list.add_group(group, -1);
        source_list.sync ();
    }

    /**
     * The given group is destroyed and will no longer exist.
     */
    public void destroy_group (E.SourceGroup group) {
        source_list.remove_group(group);
        source_list.sync ();
    }

    /**
     * The given source is added to the list of sources and will thus be persisted.
     */
    public void create_source (E.SourceGroup group, E.Source source) {
        group.add_source (source, -1);
    }

    /**
     * The given source is destroyed and will no longer exist.
     */
    public void destroy_source (E.SourceGroup group, E.Source source) {
        group.remove_source (source);
    }

    //--- Helper Functions ---//

    void add_source (E.SourceGroup group, E.Source source) {
        debug("Adding source '%s'", source.peek_name());
        group_sources.set (group, source);

        // Load Sources from preferences
        var settings = new Settings.MayaSettings();
        source_enabled.set (source, false);
        for (int i=0; i<settings.selected_calendars.length;i++) {
            if (settings.selected_calendars[i] == source.peek_uid())
                source_enabled.set (source, true);
                
        }
        

        var tree_model = _group_tree_model [group] as Gtk.TreeModelSort;
        var list_store = tree_model.get_model () as Gtk.ListStore;

        Gtk.TreeIter iter;
        list_store.append (out iter);
        list_store.set_value (iter, 0, source);

        source_added (group, source);
    }

    void remove_source (E.SourceGroup group, E.Source source) {

        debug("Removing source '%s'", source.peek_name());
        // Delete sources from preferences
        var settings = new Settings.MayaSettings();
            string[] new_selected_calendars = {};
        for (int i=0; i<settings.selected_calendars.length;i++) {
            if (settings.selected_calendars[i] != source.peek_uid())
                new_selected_calendars += settings.selected_calendars[i];
        }
        settings.selected_calendars = new_selected_calendars;
        group_sources.remove (group, source);
        source_enabled.unset (source, null);
        var tree_model = _group_tree_model [group] as Gtk.TreeModelSort;
        var list_store = tree_model.get_model () as Gtk.ListStore;
        Gtk.TreePath? path = Util.find_treemodel_object<E.Source> (list_store, 0, source, (EqualFunc) Util.source_equal_func);
        Gtk.TreeIter iter;
        list_store.get_iter (out iter, path);
        list_store.remove (iter);
        if (new_selected_calendars != null) {
            source_removed (group, source);
        }
    }

    /* Sorts evolution sources in alphabetical order by name within each group */
    static int tree_model_sort_func(Gtk.TreeModel model, Gtk.TreeIter inner_a, Gtk.TreeIter inner_b) {

        Value value_a, value_b;

        (model as Gtk.ListStore).get_value(inner_a, 0, out value_a);
        (model as Gtk.ListStore).get_value(inner_b, 0, out value_b);

        E.Source? source_a = (value_a as E.Source);
        E.Source? source_b = (value_b as E.Source);

        bool valid_a = (source_a != null);
        bool valid_b = (source_b != null);

        if (! valid_a && ! valid_b)
            return 0;
        else if (! valid_a)
            return 1;
        else if (! valid_b)
            return -1;

        var name_a = source_a.peek_name();
        var name_b = source_b.peek_name();
        return name_a.ascii_casecmp(name_b);
    }

    //--- Public Methods ---//

    /* Return all sources */
    public Gee.Collection<E.Source> get_all_sources () {
        return group_sources.get_values();
    }

    /* Return collection of enabled sources */
    public Gee.Collection<E.Source> get_enabled_sources () {
    
        var sources = new Gee.ArrayList<E.Source> (
            (EqualFunc) Util.source_equal_func);

        foreach (var source in group_sources.get_values()) {
            if (source_enabled [source])
                sources.add (source);
        }

        return sources;
    }

    public Gtk.TreeModelSort get_tree_model (E.SourceGroup group) {

        return _group_tree_model [group];
    }

    public bool get_source_enabled (E.Source source) {
        return source_enabled [source];
    }

    public Gee.Collection<E.Source> get_sources (E.SourceGroup group) {
        return group_sources [group];
    }

    public E.Source get_source_for_iter (Gtk.TreeModelSort model, Gtk.TreeIter iter_outer)
        requires (model.iter_is_valid(iter_outer)) {

        Gtk.TreeIter iter_inner;
        model.convert_iter_to_child_iter(out iter_inner, iter_outer);
        assert((model.model as Gtk.ListStore).iter_is_valid(iter_inner));

        Value v;
        (model.model as Gtk.ListStore).get_value(iter_inner, 0, out v);

        return (v as E.Source);
    }

    public void toggle_source_status (E.SourceGroup group, string path_string) {
        var tree_model_sort = _group_tree_model [group];
        var list_store = (tree_model_sort.model as Gtk.ListStore);

        Gtk.TreeIter iter_outer;
        var path_outer = new Gtk.TreePath.from_string (path_string);

        tree_model_sort.get_iter (out iter_outer, path_outer);

        Gtk.TreeIter iter_inner;
        tree_model_sort.convert_iter_to_child_iter(out iter_inner, iter_outer);

        Value v;
        list_store.get_value(iter_inner, 0, out v);

        var source = (v as E.Source);
        bool new_status = ! source_enabled [source];
        source_enabled.set (source, new_status);
        
        // Load Sources from preferences
        var settings = new Settings.MayaSettings();
        if (new_status) {
            string[] selected_calendars_copy = settings.selected_calendars;
            selected_calendars_copy += source.peek_uid ();
            settings.selected_calendars = selected_calendars_copy;
        }
        else {
            
            string[] new_selected_calendars = {};
            for (int i=0; i<settings.selected_calendars.length;i++) {
                if (settings.selected_calendars[i] != source.peek_uid())
                    new_selected_calendars += settings.selected_calendars[i];
            }
            settings.selected_calendars = new_selected_calendars;
        }
        debug("Source '%s' [enabled=%s]", source.peek_name(), new_status.to_string());

        Gtk.TreePath path_inner = list_store.get_path (iter_inner);
        list_store.row_changed (path_inner, iter_inner);

        debug ("Emitting status_changed");

        status_changed (source, new_status);
    }

    //--- Debugging ---//

    public void _dump () {
        foreach (E.SourceGroup group in groups) {
            print ("%s\n", group.peek_name());
            foreach (E.Source source in group_sources [group]) {
                print ("-- %s\n", source.peek_name());
            }
        }
    }

}

}
