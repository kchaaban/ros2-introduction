#!/usr/bin/env python3
"""
Bus Geofence Analysis Module for ROS2 Applications

This module provides functionality to analyze bus movements in and out of geofenced areas
over time. It can be integrated into ROS2 applications for transportation and logistics
systems.

The module executes a complex SQL query that:
1. Analyzes bus position data against geofenced areas
2. Tracks entry/exit events over time
3. Calculates cumulative counts and flow metrics
4. Provides detailed bus-level tracking information

Dependencies:
- psycopg2 (for PostgreSQL connectivity)
- pandas (for data manipulation)
- datetime (for time handling)
"""

import os
import psycopg2
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Union
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class BusGeofenceAnalyzer:
    """
    A class to analyze bus movements in and out of geofenced areas.
    
    This class can be integrated into ROS2 applications for real-time or
    batch analysis of transportation data.
    """
    
    def __init__(self, db_config: Dict[str, str]):
        """
        Initialize the analyzer with database configuration.
        
        Args:
            db_config: Dictionary containing database connection parameters
                      (host, port, database, user, password)
        """
        self.db_config = db_config
        self.connection = None
        self.query_template = self._load_query_template()
    
    def _load_query_template(self) -> str:
        """Load the SQL query template from file."""
        try:
            sql_file_path = os.path.join(
                os.path.dirname(__file__), 
                '..', 
                'sql', 
                'bus_geofence_analysis.sql'
            )
            with open(sql_file_path, 'r') as f:
                return f.read()
        except FileNotFoundError:
            logger.error("SQL query file not found")
            raise
    
    def connect(self) -> None:
        """Establish database connection."""
        try:
            self.connection = psycopg2.connect(**self.db_config)
            logger.info("Database connection established")
        except psycopg2.Error as e:
            logger.error(f"Database connection failed: {e}")
            raise
    
    def disconnect(self) -> None:
        """Close database connection."""
        if self.connection:
            self.connection.close()
            logger.info("Database connection closed")
    
    def analyze_geofence_activity(
        self, 
        geofence_id: int, 
        start_time: Union[str, datetime], 
        end_time: Union[str, datetime]
    ) -> pd.DataFrame:
        """
        Analyze bus activity for a specific geofence over a time period.
        
        Args:
            geofence_id: ID of the geofence to analyze
            start_time: Start time for analysis (ISO format string or datetime)
            end_time: End time for analysis (ISO format string or datetime)
            
        Returns:
            DataFrame containing analysis results with columns:
            - time_bucket: Time bucket for aggregation
            - geofence_id: Geofence identifier
            - bus_id: Bus identifier
            - service_provider_company: Service provider
            - event_type: 'entry' or 'exit'
            - inbound_count: Number of entries in time bucket
            - outbound_count: Number of exits in time bucket
            - initial_count: Initial buses present
            - net_flow: Net flow (inbound - outbound)
            - cumulative_count: Cumulative count of buses present
        """
        if not self.connection:
            self.connect()
        
        # Convert datetime objects to strings if needed
        if isinstance(start_time, datetime):
            start_time = start_time.isoformat()
        if isinstance(end_time, datetime):
            end_time = end_time.isoformat()
        
        query_params = {
            'geofence_id': geofence_id,
            'starttime': start_time,
            'endtime': end_time
        }
        
        try:
            # Execute query
            cursor = self.connection.cursor()
            cursor.execute(self.query_template, query_params)
            
            # Fetch results
            columns = [desc[0] for desc in cursor.description]
            results = cursor.fetchall()
            
            # Create DataFrame
            df = pd.DataFrame(results, columns=columns)
            
            logger.info(f"Analysis completed for geofence {geofence_id}: {len(df)} records")
            return df
            
        except psycopg2.Error as e:
            logger.error(f"Query execution failed: {e}")
            raise
        finally:
            if cursor:
                cursor.close()
    
    def get_summary_statistics(self, results_df: pd.DataFrame) -> Dict:
        """
        Generate summary statistics from analysis results.
        
        Args:
            results_df: DataFrame from analyze_geofence_activity
            
        Returns:
            Dictionary containing summary statistics
        """
        if results_df.empty:
            return {}
        
        summary = {
            'total_time_buckets': len(results_df['time_bucket'].unique()),
            'total_buses_tracked': len(results_df['bus_id'].dropna().unique()),
            'total_entries': results_df['inbound_count'].sum(),
            'total_exits': results_df['outbound_count'].sum(),
            'max_simultaneous_buses': results_df['cumulative_count'].max(),
            'min_simultaneous_buses': results_df['cumulative_count'].min(),
            'avg_simultaneous_buses': results_df['cumulative_count'].mean(),
            'service_providers': list(results_df['service_provider_company'].dropna().unique())
        }
        
        return summary
    
    def export_results(self, results_df: pd.DataFrame, output_path: str) -> None:
        """
        Export analysis results to CSV file.
        
        Args:
            results_df: DataFrame from analyze_geofence_activity
            output_path: Path to output CSV file
        """
        try:
            results_df.to_csv(output_path, index=False)
            logger.info(f"Results exported to {output_path}")
        except Exception as e:
            logger.error(f"Export failed: {e}")
            raise


def main():
    """
    Example usage of the BusGeofenceAnalyzer.
    This function demonstrates how to use the analyzer in a ROS2 application.
    """
    # Example database configuration
    db_config = {
        'host': 'localhost',
        'port': 5432,
        'database': 'transportation_db',
        'user': 'ros_user',
        'password': 'ros_password'
    }
    
    # Initialize analyzer
    analyzer = BusGeofenceAnalyzer(db_config)
    
    try:
        # Analyze geofence activity
        results = analyzer.analyze_geofence_activity(
            geofence_id=1,
            start_time='2024-01-01T06:00:00',
            end_time='2024-01-01T18:00:00'
        )
        
        # Get summary statistics
        summary = analyzer.get_summary_statistics(results)
        print("Analysis Summary:")
        for key, value in summary.items():
            print(f"  {key}: {value}")
        
        # Export results
        analyzer.export_results(results, '/tmp/geofence_analysis_results.csv')
        
    except Exception as e:
        logger.error(f"Analysis failed: {e}")
    finally:
        analyzer.disconnect()


if __name__ == "__main__":
    main()