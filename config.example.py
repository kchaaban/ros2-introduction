# Example configuration for Bus Geofence Analysis
# Copy this file to config.py and update with your database credentials

DATABASE_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'transportation_db',
    'user': 'your_username',
    'password': 'your_password'
}

# Analysis parameters
DEFAULT_GEOFENCE_ID = 1
DEFAULT_TIME_BUCKET_MINUTES = 5

# Logging configuration
LOG_LEVEL = 'INFO'
LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'