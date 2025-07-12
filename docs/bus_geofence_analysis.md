# Bus Geofence Analysis for ROS2 Applications

This module provides comprehensive analysis of bus movements in and out of geofenced areas over time. It's designed to integrate with ROS2 applications for transportation and logistics systems.

## Features

- **Spatial-Temporal Analysis**: Analyzes bus positions against geofenced areas over time
- **Event Detection**: Identifies entry/exit events for buses crossing geofence boundaries
- **Flow Metrics**: Calculates inbound/outbound counts and net flow
- **Cumulative Tracking**: Maintains running counts of buses present in geofenced areas
- **Time-based Aggregation**: Groups analysis into 5-minute time buckets
- **Multi-Provider Support**: Handles data from multiple service providers

## Files

- `sql/bus_geofence_analysis.sql`: Complex SQL query for geofence analysis
- `src/bus_geofence_analyzer.py`: Python module for executing analysis
- `requirements.txt`: Python dependencies

## Database Schema

The analysis expects the following database tables:

### hajj_days
- `BID`: Bus identifier
- `service_provider_company`: Service provider name
- `DT_DATETIME`: Timestamp of bus position
- `geometry`: Spatial geometry of bus position

### geofences_new
- `OBJECTID`: Geofence identifier
- `geometry`: Spatial geometry of geofenced area

## Usage

### Basic Usage

```python
from src.bus_geofence_analyzer import BusGeofenceAnalyzer

# Database configuration
db_config = {
    'host': 'localhost',
    'port': 5432,
    'database': 'transportation_db',
    'user': 'username',
    'password': 'password'
}

# Initialize analyzer
analyzer = BusGeofenceAnalyzer(db_config)

# Analyze geofence activity
results = analyzer.analyze_geofence_activity(
    geofence_id=1,
    start_time='2024-01-01T06:00:00',
    end_time='2024-01-01T18:00:00'
)

# Get summary statistics
summary = analyzer.get_summary_statistics(results)
print(summary)
```

### ROS2 Integration

This module can be integrated into ROS2 nodes for:

1. **Real-time Monitoring**: Continuous analysis of bus movements
2. **Fleet Management**: Tracking fleet distribution across geofenced areas
3. **Capacity Planning**: Understanding usage patterns for different areas
4. **Event-driven Actions**: Triggering actions based on geofence events

### Installation

```bash
pip install -r requirements.txt
```

## SQL Query Details

The query performs the following operations:

1. **Position Analysis**: Determines if buses are inside or outside geofenced areas
2. **Time Bucketing**: Creates 5-minute time intervals for aggregation
3. **Transition Detection**: Identifies when buses cross geofence boundaries
4. **Event Classification**: Categorizes transitions as 'entry' or 'exit' events
5. **Flow Calculation**: Counts entries and exits per time bucket
6. **Presence Tracking**: Tracks which buses are present in each time bucket
7. **Cumulative Analysis**: Calculates running totals of buses present

## Output Schema

The analysis returns data with the following columns:

- `time_bucket`: 5-minute time interval for aggregation
- `geofence_id`: Identifier of the analyzed geofence
- `bus_id`: Bus identifier (null for summary rows)
- `service_provider_company`: Service provider name
- `event_type`: 'entry', 'exit', or null
- `inbound_count`: Number of buses entering in this time bucket
- `outbound_count`: Number of buses exiting in this time bucket
- `initial_count`: Number of buses present at start time
- `net_flow`: Net change in bus count (inbound - outbound)
- `cumulative_count`: Total buses present at end of time bucket

## Performance Considerations

- Uses spatial indexing for efficient geometry operations
- Optimized for time-series analysis with proper windowing
- Handles large datasets through efficient CTEs
- Consider partitioning large tables by date for better performance

## Dependencies

- PostgreSQL with PostGIS extension
- Python 3.8+
- psycopg2-binary
- pandas
- numpy