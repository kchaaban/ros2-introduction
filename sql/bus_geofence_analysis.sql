-- Bus Geofence Analysis Query
-- This query analyzes bus movements in and out of geofenced areas over time
-- Parameters: geofence_id, starttime, endtime

WITH position_status AS (
    SELECT 
        b."BID" AS bus_id,
        b.service_provider_company,
        b."DT_DATETIME"::timestamp AS dt_datetime,
        g."OBJECTID" AS geofence_id,
        CASE 
            WHEN ST_Contains(g.geometry, b.geometry) THEN 'inside'
            ELSE 'outside'
        END AS status
    FROM 
        hajj_days b
    JOIN 
        geofences_new g ON g."OBJECTID" = %(geofence_id)s
    WHERE 
        b."DT_DATETIME"::timestamp >= TIMESTAMP %(starttime)s
        AND b."DT_DATETIME"::timestamp < TIMESTAMP %(endtime)s
        AND b.geometry && g.geometry
),

time_buckets AS (
    SELECT 
        generate_series(
            date_trunc('hour', TIMESTAMP %(starttime)s),
            TIMESTAMP %(endtime)s,
            interval '5 minutes'
        ) AS time_bucket
),

with_transitions AS (
    SELECT 
        bus_id,
        dt_datetime,
        service_provider_company,
        geofence_id,
        status,
        LAG(status) OVER (PARTITION BY bus_id ORDER BY dt_datetime) AS prev_status
    FROM 
        position_status
),

geofence_events AS (
    SELECT 
        bus_id,
        dt_datetime AS event_time,
        service_provider_company,
        geofence_id,
        CASE
            WHEN prev_status = 'outside' AND status = 'inside' THEN 'entry'
            WHEN prev_status = 'inside' AND status = 'outside' THEN 'exit'
        END AS event_type
    FROM 
        with_transitions
    WHERE 
        (prev_status = 'outside' AND status = 'inside')
        OR (prev_status = 'inside' AND status = 'outside')
),

-- Count entries/exits per time bucket (aggregate properly)
bucket_counts AS (
    SELECT 
        tb.time_bucket,
        %(geofence_id)s AS geofence_id,
        COUNT(CASE WHEN e.event_type = 'entry' THEN 1 END) AS inbound_count,
        COUNT(CASE WHEN e.event_type = 'exit' THEN 1 END) AS outbound_count
    FROM 
        time_buckets tb
    LEFT JOIN 
        geofence_events e ON e.event_time >= tb.time_bucket 
                         AND e.event_time < tb.time_bucket + interval '5 minutes'
    GROUP BY 
        tb.time_bucket
),

-- Get buses that were inside at start time with their IDs
initial_buses_detailed AS (
    SELECT DISTINCT
        b."BID" AS bus_id,
        b.service_provider_company
    FROM 
        hajj_days b
    JOIN 
        geofences_new g ON g."OBJECTID" = %(geofence_id)s
    WHERE 
        ST_Contains(g.geometry, b.geometry)
        AND b."DT_DATETIME"::timestamp <= TIMESTAMP %(starttime)s
        AND b."DT_DATETIME"::timestamp >= TIMESTAMP %(starttime)s - INTERVAL '1 hour'
),

-- Track actual bus presence per time bucket
bus_status_per_bucket AS (
    SELECT 
        tb.time_bucket,
        ib.bus_id,
        ib.service_provider_company,
        %(geofence_id)s AS geofence_id,
        -- Check if bus has exited by this time bucket
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM geofence_events ge 
                WHERE ge.bus_id = ib.bus_id 
                AND ge.event_type = 'exit' 
                AND ge.event_time <= tb.time_bucket + interval '5 minutes'
                AND NOT EXISTS (
                    SELECT 1 FROM geofence_events ge2 
                    WHERE ge2.bus_id = ib.bus_id 
                    AND ge2.event_type = 'entry' 
                    AND ge2.event_time > ge.event_time 
                    AND ge2.event_time <= tb.time_bucket + interval '5 minutes'
                )
            ) THEN 0
            ELSE 1
        END AS is_present
    FROM 
        time_buckets tb
    CROSS JOIN 
        initial_buses_detailed ib
    
    UNION ALL
    
    -- Add buses that entered during the period
    SELECT 
        tb.time_bucket,
        ge.bus_id,
        ge.service_provider_company,
        ge.geofence_id,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM geofence_events ge2 
                WHERE ge2.bus_id = ge.bus_id 
                AND ge2.event_type = 'exit' 
                AND ge2.event_time > ge.event_time 
                AND ge2.event_time <= tb.time_bucket + interval '5 minutes'
                AND NOT EXISTS (
                    SELECT 1 FROM geofence_events ge3 
                    WHERE ge3.bus_id = ge.bus_id 
                    AND ge3.event_type = 'entry' 
                    AND ge3.event_time > ge2.event_time 
                    AND ge3.event_time <= tb.time_bucket + interval '5 minutes'
                )
            ) THEN 0
            ELSE 1
        END AS is_present
    FROM 
        time_buckets tb
    JOIN 
        geofence_events ge ON ge.event_type = 'entry' 
                          AND ge.event_time <= tb.time_bucket + interval '5 minutes'
                          AND ge.event_time >= TIMESTAMP %(starttime)s
),

-- Calculate initial count once
initial_count_calc AS (
    SELECT COUNT(DISTINCT bus_id) AS initial_count
    FROM initial_buses_detailed
),

-- Calculate cumulative flow for each time bucket
bucket_aggregates AS (
    SELECT 
        bc.time_bucket,
        bc.geofence_id,
        bc.inbound_count,
        bc.outbound_count,
        COUNT(DISTINCT CASE WHEN bsp.is_present = 1 THEN bsp.bus_id END) AS actual_present_count
    FROM 
        bucket_counts bc
    LEFT JOIN 
        bus_status_per_bucket bsp ON bc.time_bucket = bsp.time_bucket
    GROUP BY 
        bc.time_bucket, bc.geofence_id, bc.inbound_count, bc.outbound_count
),

cumulative_counts AS (
    SELECT 
        ba.time_bucket,
        ba.geofence_id,
        ba.inbound_count,
        ba.outbound_count,
        ba.actual_present_count,
        icc.initial_count,
        (ba.inbound_count - ba.outbound_count) AS net_flow,
        -- Calculate cumulative net flow from start time to current bucket
        icc.initial_count + SUM(ba.inbound_count - ba.outbound_count) 
            OVER (ORDER BY ba.time_bucket ROWS UNBOUNDED PRECEDING) AS cumulative_count_calculated
    FROM 
        bucket_aggregates ba
    CROSS JOIN
        initial_count_calc icc
)

-- Final result with individual bus details and proper cumulative calculation
SELECT 
    cc.time_bucket,
    cc.geofence_id,
    ge.bus_id,
    ge.service_provider_company,
    ge.event_type,
    cc.inbound_count,
    cc.outbound_count,
    cc.initial_count,
    cc.net_flow,
    GREATEST(0, cc.cumulative_count_calculated) AS cumulative_count
FROM 
    cumulative_counts cc
LEFT JOIN 
    geofence_events ge ON ge.event_time >= cc.time_bucket 
                      AND ge.event_time < cc.time_bucket + interval '5 minutes'
ORDER BY 
    cc.time_bucket, ge.service_provider_company, ge.bus_id;