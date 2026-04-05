import sqlite3
import json
import time
from typing import List, Optional
from metrics import SystemMetrics

class MetricsStorage:
    def __init__(self, db_path: str = "metrics.db"):
        self.db_path = db_path
        self._init_db()

    def _init_db(self):
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            # Enable WAL mode for better concurrency and reliability
            cursor.execute("PRAGMA journal_mode=WAL;")
            
            # Create metrics table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS metrics (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp REAL NOT NULL,
                    metric_type TEXT NOT NULL,
                    value TEXT NOT NULL,
                    tenant_id TEXT
                )
            """)
            # Create index on timestamp for faster pruning
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON metrics(timestamp)")
            conn.commit()

    def append_metrics(self, metrics: SystemMetrics, tenant_id: Optional[str] = None):
        """Append SystemMetrics to the local database."""
        timestamp = time.time()
        # We'll store the full SystemMetrics as JSON for now
        # In a real-world scenario, we might want to split it into multiple tables
        # But per requirements "value (JSON/Blob)", this is fine.
        metrics_json = metrics.model_dump_json()
        
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO metrics (timestamp, metric_type, value, tenant_id) VALUES (?, ?, ?, ?)",
                (timestamp, "system_metrics", metrics_json, tenant_id)
            )
            conn.commit()

    def get_recent_metrics(self, limit: int = 10) -> List[dict]:
        """Retrieve recent metrics from the database."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(
                "SELECT timestamp, metric_type, value, tenant_id FROM metrics ORDER BY timestamp DESC LIMIT ?",
                (limit,)
            )
            rows = cursor.fetchall()
            return [
                {
                    "timestamp": row[0],
                    "metric_type": row[1],
                    "value": json.loads(row[2]),
                    "tenant_id": row[3]
                }
                for row in rows
            ]

    def prune_old_data(self, max_age_hours: int = 24):
        """Remove metrics older than max_age_hours."""
        cutoff_time = time.time() - (max_age_hours * 3600)
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM metrics WHERE timestamp < ?", (cutoff_time,))
            deleted_count = cursor.rowcount
            conn.commit()
            return deleted_count

if __name__ == "__main__":
    # Quick self-test
    storage = MetricsStorage("test_metrics.db")
    print(f"WAL mode: {sqlite3.connect('test_metrics.db').execute('PRAGMA journal_mode').fetchone()[0]}")
    
    from metrics import collect_all_metrics
    m = collect_all_metrics()
    storage.append_metrics(m, tenant_id="test-tenant")
    print(f"Stored 1 metric record.")
    
    recent = storage.get_recent_metrics(1)
    print(f"Retrieved {len(recent)} recent record.")
    
    deleted = storage.prune_old_data(0) # Prune everything for test
    print(f"Pruned {deleted} records.")
