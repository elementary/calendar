// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013 Maya Developers (https://launchpad.net/maya)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Zeeshan Ali (Khattak) <zeeshanak@gnome.org> (from Rygel)
 *              Lucas Baudin <xapantu@gmail.com> (from Pantheon Files)
 *              Corentin Noël <tintou@mailoo.org>
 */

public class Maya.Plugins.Interface : Object {
    Manager manager;
    
    public Gtk.Application maya_app {internal set; get; }
    public string set_name {internal set; get; }
    public string? argument {internal set; get; }

    public Interface (Manager manager) {
        this.manager = manager;
    }
    
}


public class Maya.Plugins.Manager : Object {
    Peas.Engine engine;
    Peas.ExtensionSet exts;
    
    public Gtk.Application maya_app { set { plugin_iface.maya_app = value;  }}
    public Maya.Plugins.Interface plugin_iface { private set; get; }

    public Manager(string d, string? e, string? argument_set) {

        plugin_iface = new Maya.Plugins.Interface (this);
        plugin_iface.argument = argument_set;
        plugin_iface.set_name = e ?? "maya";

        /* Let's init the engine */
        engine = Peas.Engine.get_default ();
        engine.enable_loader ("python");
        engine.enable_loader ("gjs");
        engine.add_search_path (d, null);
        
        /* Do not load blacklisted plugins */
        var disabled_plugins = new Gee.LinkedList<string> ();
        foreach (var plugin in global_settings.plugins_disabled) {
            disabled_plugins.add (plugin);
        }
        
        foreach (var plugin in engine.get_plugin_list ()) {
            if (!disabled_plugins.contains (plugin.get_module_name ())) {
                engine.try_load_plugin (plugin);
            }
        }

        /* Our extension set */
        Parameter param = Parameter();
        param.value = plugin_iface;
        param.name = "object";
        exts = new Peas.ExtensionSet (engine, typeof(Peas.Activatable), "object", plugin_iface, null);

        exts.extension_added.connect( (info, ext) => {  
            ((Peas.Activatable)ext).activate();
        });
        exts.extension_removed.connect(on_extension_removed);
        
        exts.foreach (on_extension_added);
        
    }
    
    void on_extension_added (Peas.ExtensionSet set, Peas.PluginInfo info, Peas.Extension extension) {
        foreach (var plugin in engine.get_plugin_list ()) {
            string module = plugin.get_module_name ();
            if (module == info.get_module_name ()) {
                ((Peas.Activatable)extension).activate();
            }
        }
    }

    void on_extension_removed (Peas.PluginInfo info, Object extension) {
        ((Peas.Activatable)extension).deactivate();
    }

    public void hook_app (Gtk.Application app) {
        plugin_iface.maya_app = app;
    }
}

