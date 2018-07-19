CREATE INDEX stop_srd_index ON stop_route_direction (stop_id);
CREATE INDEX route_srd_index ON stop_route_direction (route_id);
CREATE INDEX direction_srd_index ON stop_route_direction (direction_id);

-- index trips by route

CREATE INDEX trips_bus_route_id_index
ON trips_bus (route_id);

-- trips rail
CREATE INDEX trips_rail_route_id_trip_id_index
ON trips_rail (route_id, trip_id);

CREATE INDEX trips_rail_trip_id_route_id_index
ON trips_rail (trip_id, route_id);

-- routes-bus

CREATE INDEX routes_bus_route_id_index
ON routes_bus (route_id);

-- routes-rail

CREATE INDEX routes_rail_route_id_index
ON routes_rail (route_id);

-- reverse Stop Search
CREATE INDEX reverseStopSearch_reverse_stop_id_stop_id_index
ON reverseStopSearch (reverse_stop_id, stop_id);
CREATE INDEX reverseStopSearch_stop_id_reverse_stop_id_index
ON reverseStopSearch (stop_id, reverse_stop_id);

-- bus stop directions

CREATE INDEX bus_stop_directions_Route_index
ON bus_stop_directions (Route);

-- stop times rail

CREATE INDEX stop_times_rail_trip_id_stop_id_stop_sequence_index
ON stop_times_rail (trip_id, stop_id, stop_sequence);
CREATE INDEX stop_times_rail_stop_id_trip_id_index
ON stop_times_rail (stop_id, trip_id);

VACUUM;
