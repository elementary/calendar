// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 */

using Gtk;
using Peas;

namespace Maya.Plugins {
    
    public class CalDAVPlugin : Peas.ExtensionBase, Peas.Activatable {
        public GLib.Object object { owned get; construct; }

        public CalDAVPlugin () {
          GLib.Object ();
        }
        
        private CalDavBackend caldav_backend;
        
        public void activate () {

            message ("Activating CalDAV plugin");
            caldav_backend = new CalDavBackend ();
            backends_manager.add_backend (caldav_backend);
        }

        public void deactivate () {
            message ("Deactivating CalDAV plugin");
            backends_manager.remove_backend (caldav_backend);
        }

        public void update_state () {
            // do nothing
        }
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Peas.Activatable),
                                     typeof (Maya.Plugins.CalDAVPlugin));
}
