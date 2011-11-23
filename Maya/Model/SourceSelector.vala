namespace Maya.Model {

class SourceSelector: GLib.Object {

    Gee.List<E.SourceGroup> _groups;
    public Gee.List<E.SourceGroup> groups {
        owned get { return _groups.read_only_view; }
    }

    Gee.Map<E.SourceGroup, Gtk.TreeModelSort> _group_tree_model;
    public Gee.Map<E.SourceGroup, Gtk.TreeModelSort> group_tree_model {
        owned get { return _group_tree_model.read_only_view; }
    }

    public signal void source_status_changed (E.Source source, bool enabled);

    Gee.MultiMap<E.SourceGroup, E.Source> group_sources;
    Gee.Map<E.Source, bool> source_enabled;

    E.SourceGroup? GROUP_LOCAL { get; set; }
    E.SourceGroup? GROUP_REMOTE { get; set; }
    E.SourceGroup? GROUP_CONTACTS { get; set; }

    public SourceSelector() {

        bool status;

        E.SourceList source_list;
        status = E.CalClient.get_sources (out source_list, E.CalClientSourceType.EVENTS);
        assert (status==true); // TODO

        source_enabled = new Gee.HashMap<E.Source, bool> ();

        GROUP_LOCAL = source_list.peek_group_by_base_uri("local:");
        GROUP_REMOTE = source_list.peek_group_by_base_uri("webcal://");
        GROUP_CONTACTS = source_list.peek_group_by_base_uri("contacts://");

        // the order that groups will appear
        _groups = new Gee.ArrayList<E.SourceGroup>();
        _groups.add (GROUP_LOCAL);
        _groups.add (GROUP_REMOTE);
        _groups.add (GROUP_CONTACTS);

        group_sources = new Gee.HashMultiMap<E.SourceGroup, E.Source>();
        _group_tree_model = new Gee.HashMap<E.SourceGroup, Gtk.TreeModelSort>();

        foreach (E.SourceGroup group in _groups) {

            debug("Processing E.SourceGroup '%s'", group.peek_name());

            var list_store = new Gtk.ListStore.newv ( {typeof(E.Source)} );
            var tree_model = new Gtk.TreeModelSort.with_model (list_store);
            _group_tree_model.set (group, tree_model);

            tree_model.set_default_sort_func (tree_model_sort_func);

            foreach (E.Source source in group.peek_sources()) {

                debug("Adding E.Source '%s'", source.peek_name());

                group_sources.set(group, source);
                source_enabled.set (source, true);

                Gtk.TreeIter iter;
                list_store.append (out iter);
                list_store.set_value (iter, 0, source);
            }
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

    public bool get_source_enabled (E.Source source) {
        return source_enabled.get (source);
    }

    public bool get_show_group (E.SourceGroup group) {
        var sources = group_sources.get (group);
        return sources.size>0;
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

        var tree_model_sort = group_tree_model.get (group);
        var list_store = (tree_model_sort.model as Gtk.ListStore);

        Gtk.TreeIter iter_outer;
        var path_outer = new Gtk.TreePath.from_string (path_string);

        tree_model_sort.get_iter (out iter_outer, path_outer);

        Gtk.TreeIter iter_inner;
        tree_model_sort.convert_iter_to_child_iter(out iter_inner, iter_outer);

        Value v;
        list_store.get_value(iter_inner, 0, out v);

        var source = (v as E.Source);
        bool new_status = ! source_enabled.get(source);
        source_enabled.set (source, new_status);

        debug("Toggled source status '%s' [enabled=%s]", source.peek_name(), new_status.to_string());

        Gtk.TreePath path_inner = list_store.get_path (iter_inner);
        list_store.row_changed (path_inner, iter_inner);

        source_status_changed (source, new_status);
    }

    public void dump () { // XXX: delete me
        foreach (E.SourceGroup group in groups) {
            print ("%s\n", group.peek_name());
            foreach (E.Source source in group_sources.get(group)) {
                print ("-- %s\n", source.peek_name());
            }
        }
    }

}

}
