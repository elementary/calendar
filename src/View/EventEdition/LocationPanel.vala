//
//  Copyright (C) 2011-2012 Jaap Broekhuizen
//
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

public class Maya.View.EventEdition.LocationPanel : Gtk.Grid {
    private EventDialog parent_dialog;

    private Gtk.SearchEntry location_entry;

    private GtkChamplain.Embed champlain_embed;
    private Champlain.Point point;

    public LocationPanel (EventDialog parent_dialog) {
        this.parent_dialog = parent_dialog;

        margin_left = 12;
        margin_right = 12;
        set_row_spacing (6);
        set_column_spacing (12);
        set_sensitive (parent_dialog.can_edit);

        var location_label = Maya.View.EventDialog.make_label (_("Location:"));
        location_entry = new Gtk.SearchEntry ();
        location_entry.placeholder_text = _("John Smith OR Example St.");
        location_entry.hexpand = true;
        location_entry.activate.connect (() => {compute_location.begin ();});
        attach (location_label, 0, 0, 1, 1);
        attach (location_entry, 0, 1, 1, 1);

        champlain_embed = new GtkChamplain.Embed ();
        var view = champlain_embed.champlain_view;
        var marker_layer = new Champlain.MarkerLayer.full (Champlain.SelectionMode.SINGLE);
        view.add_layer (marker_layer);

        attach (champlain_embed, 0, 2, 1, 1);

        // Load the location
        point = new Champlain.Point ();
        point.draggable = parent_dialog.can_edit;
        if (parent_dialog.ecal != null) {
            unowned iCal.Component comp = parent_dialog.ecal.get_icalcomponent ();
            string location = comp.get_location ();
            if (location != null)
                location_entry.text = location;

            unowned iCal.Property property = comp.get_first_property (iCal.PropertyKind.GEO);
            iCal.GeoType? geo = property.get_geo ();
            if (geo != null) {
                if (geo.latitude < Champlain.MIN_LATITUDE || geo.longitude < Champlain.MIN_LONGITUDE ||
                    geo.latitude > Champlain.MAX_LATITUDE || geo.longitude > Champlain.MAX_LONGITUDE) {
                    compute_location.begin ();
                } else {
                    point.latitude = geo.latitude;
                    point.longitude = geo.longitude;
                }
            } else if (location != null) {
                compute_location.begin ();
            }
        }
        view.zoom_level = 8;
        view.center_on (point.latitude, point.longitude);
        marker_layer.add_marker (point);
    }
    
    /**
     * Save the values in the dialog into the component.
     */
    public void save () {

        unowned iCal.Component comp = parent_dialog.ecal.get_icalcomponent ();
        // Save the location
        string location = location_entry.text;

        comp.set_location (location);
        
        // First, clear the geo
        int count = comp.count_properties (iCal.PropertyKind.GEO);

        for (int i = 0; i < count; i++) {
            unowned iCal.Property remove_prop = comp.get_first_property (iCal.PropertyKind.GEO);

            comp.remove_property (remove_prop);
        }

        // Add the comment
        var property = new iCal.Property (iCal.PropertyKind.GEO);
        iCal.GeoType geo = {0, 0};
        geo.latitude = (float)point.latitude;
        geo.longitude = (float)point.longitude;
        property.set_geo (geo);
        comp.add_property (property);
    }
    
    private async void compute_location () {
        var forward = new Geocode.Forward.for_string (location_entry.text);
        try {
            forward.set_answer_count (1);
            var places = forward.search ();
            foreach (var place in places) {
                point.latitude = place.location.latitude;
                point.longitude = place.location.longitude;
                champlain_embed.champlain_view.go_to (point.latitude, point.longitude);
            }
            location_entry.has_focus = true;
        } catch (Error e) {
        
        }
    }
}