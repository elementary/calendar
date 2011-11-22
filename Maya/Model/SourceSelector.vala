namespace Maya.Model {

public class SourceDecorator : Object {
    public E.Source esource { get; set; }
    public bool enabled { get; set; }
}

class SourceSelector: GLib.Object {

    Gee.MultiMap<E.SourceGroup, E.Source> group_sources;

    public Gee.List<E.SourceGroup> groups { get; private set; }
    public Gee.Map<E.SourceGroup, Gtk.TreeModelSort> group_tree_model { get; private set;}

    public E.SourceGroup? GROUP_LOCAL { get; private set; }
    public E.SourceGroup? GROUP_REMOTE { get; private set; }
    public E.SourceGroup? GROUP_CONTACTS { get; private set; }

    public SourceSelector() {

        bool status;

        E.SourceList source_list;
        status = E.CalClient.get_sources (out source_list, E.CalClientSourceType.EVENTS);
        assert (status==true); // TODO

        GROUP_LOCAL = source_list.peek_group_by_base_uri("local:");
        GROUP_REMOTE = source_list.peek_group_by_base_uri("webcal://");
        GROUP_CONTACTS = source_list.peek_group_by_base_uri("contacts://");

        groups = new Gee.ArrayList<E.SourceGroup>();
        groups.add (GROUP_LOCAL);
        groups.add (GROUP_REMOTE);
        groups.add (GROUP_CONTACTS);

        group_sources = new Gee.HashMultiMap<E.SourceGroup, E.Source>();
        group_tree_model = new Gee.HashMap<E.SourceGroup, Gtk.TreeModelSort>();

        foreach (E.SourceGroup group in groups) {

            var list_store = new Gtk.ListStore.newv ( {typeof(SourceDecorator)} );
            var tree_model = new Gtk.TreeModelSort.with_model (list_store);
            tree_model.set_default_sort_func (tree_model_sort_func);
            group_tree_model.set (group, tree_model);

            foreach (unowned E.Source esource in group.peek_sources()) {

                var source_copy = esource.copy ();
                group_sources.set(group, source_copy);

                var source = new SourceDecorator();
                source.enabled = true;
                source.esource = esource;

                Gtk.TreeIter iter;
                list_store.append (out iter);
                list_store.set_value (iter, 0, source);

            }
        }
    }

    private static int tree_model_sort_func(Gtk.TreeModel model, Gtk.TreeIter inner_a, Gtk.TreeIter inner_b) {

        Value source_a, source_b;

        (model as Gtk.ListStore).get_value(inner_a, 0, out source_a);
        (model as Gtk.ListStore).get_value(inner_b, 0, out source_b);

        bool valid_a = source_a.holds(typeof(E.Source));
        bool valid_b = source_a.holds(typeof(E.Source));

        if (! valid_a && ! valid_b)
            return 0;
        else if (! valid_a)
            return 1;
        else if (! valid_b)
            return -1;

        var name_a = (source_a as SourceDecorator).esource.peek_name();
        var name_b = (source_b as SourceDecorator).esource.peek_name();
        return name_a.ascii_casecmp(name_b);
    }

    public Gee.Collection<E.Source> get_sources (E.SourceGroup group) {
        return group_sources.get (group);
    }

    public bool get_show_group (E.SourceGroup group) {
        var sources = get_sources (group);
        return sources.size>0;
    }

    public void debug () { // XXX: delete me
        foreach (E.SourceGroup group in groups) {
            print ("%s\n", group.peek_name());
            foreach (E.Source source in get_sources(group)) {
                print ("-- %s\n", source.peek_name());
            }
        }
    }

}

}
