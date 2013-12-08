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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

public class Maya.BackendsManager : GLib.Object {
    
    public Gee.ArrayList<unowned Backend> backends;
    
    public signal void backend_added (Backend b);
    public signal void backend_removed (Backend b);
    
    private LocalBackend local_backend;
    
    public BackendsManager() {
        backends = new Gee.ArrayList<unowned Backend> ();
        
        // Add default backend for local calendar
        local_backend = new LocalBackend ();
        add_backend (local_backend);
    }
    
    public void add_backend (Backend b) {
        backends.add (b);
        backend_added (b);
    }
    
    public void remove_backend (Backend b) {
        if (backends.contains (b)) {
            backends.remove (b);
            backend_removed (b);
        }
    }
}
