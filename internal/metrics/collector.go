package metrics

import (
	"encoding/json"
	"os"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/sirupsen/logrus"
)

// QueryResult represents the result of a query execution
type QueryResult struct {
	QueryName    string        `json:"query_name"`
	Success      bool          `json:"success"`
	Duration     time.Duration `json:"duration"`
	RowsAffected int64         `json:"rows_affected"`
	Error        string        `json:"error,omitempty"`
	Timestamp    time.Time     `json:"timestamp"`
}

// Collector handles metrics collection for load testing
type Collector struct {
	// Prometheus metrics
	requestsTotal     prometheus.Counter
	requestDuration   prometheus.Histogram
	activeConnections prometheus.Gauge
	errorsTotal       prometheus.Counter
	queriesExecuted   prometheus.Counter
	queryDuration     prometheus.Histogram

	// Internal state
	outputFile     string
	interval       time.Duration
	prometheusName string
	activeUsers    int
	stats          map[string]interface{}
	mu             sync.RWMutex
	stopChan       chan struct{}
}

// NewCollector creates a new metrics collector
func NewCollector() *Collector {
	return &Collector{
		requestsTotal: promauto.NewCounter(prometheus.CounterOpts{
			Name: "fiyuu_ktdb_requests_total",
			Help: "Total number of requests processed",
		}),
		requestDuration: promauto.NewHistogram(prometheus.HistogramOpts{
			Name:    "fiyuu_ktdb_request_duration_seconds",
			Help:    "Request duration in seconds",
			Buckets: prometheus.DefBuckets,
		}),
		activeConnections: promauto.NewGauge(prometheus.GaugeOpts{
			Name: "fiyuu_ktdb_active_connections",
			Help: "Number of active database connections",
		}),
		errorsTotal: promauto.NewCounter(prometheus.CounterOpts{
			Name: "fiyuu_ktdb_errors_total",
			Help: "Total number of errors",
		}),
		queriesExecuted: promauto.NewCounter(prometheus.CounterOpts{
			Name: "fiyuu_ktdb_queries_executed_total",
			Help: "Total number of queries executed",
		}),
		queryDuration: promauto.NewHistogram(prometheus.HistogramOpts{
			Name:    "fiyuu_ktdb_query_duration_seconds",
			Help:    "Query execution duration in seconds",
			Buckets: prometheus.DefBuckets,
		}),
		stats:    make(map[string]interface{}),
		stopChan: make(chan struct{}),
	}
}

// RecordRequest records a request metric
func (c *Collector) RecordRequest(duration time.Duration) {
	c.requestsTotal.Inc()
	c.requestDuration.Observe(duration.Seconds())
}

// RecordError records an error metric
func (c *Collector) RecordError() {
	c.errorsTotal.Inc()
}

// RecordQueryDuration records a query execution metric by duration
func (c *Collector) RecordQueryDuration(duration time.Duration) {
	c.queriesExecuted.Inc()
	c.queryDuration.Observe(duration.Seconds())
}

// SetActiveConnections sets the number of active connections
func (c *Collector) SetActiveConnections(count int) {
	c.activeConnections.Set(float64(count))
}

// SetOutputFile sets the output file for metrics
func (c *Collector) SetOutputFile(filename string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.outputFile = filename
}

// SetInterval sets the collection interval
func (c *Collector) SetInterval(interval time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.interval = interval
}

// EnablePrometheus enables Prometheus metrics collection
func (c *Collector) EnablePrometheus(name string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.prometheusName = name
}

// Start starts the metrics collection
func (c *Collector) Start() {
	if c.interval <= 0 {
		c.interval = 10 * time.Second
	}

	ticker := time.NewTicker(c.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			c.collectMetrics()
		case <-c.stopChan:
			return
		}
	}
}

// SetActiveUsers sets the number of active users
func (c *Collector) SetActiveUsers(count int) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.activeUsers = count
}

// RecordQuery records a query execution with QueryResult
func (c *Collector) RecordQuery(result QueryResult) {
	c.queriesExecuted.Inc()
	c.queryDuration.Observe(result.Duration.Seconds())

	if !result.Success {
		c.errorsTotal.Inc()
	}

	// Update internal stats
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.stats == nil {
		c.stats = make(map[string]interface{})
	}

	// Update query-specific stats
	queryStats, ok := c.stats[result.QueryName].(map[string]interface{})
	if !ok {
		queryStats = make(map[string]interface{})
		queryStats["total_queries"] = 0
		queryStats["successful_queries"] = 0
		queryStats["failed_queries"] = 0
		queryStats["total_duration"] = time.Duration(0)
		queryStats["avg_duration"] = time.Duration(0)
	}

	queryStats["total_queries"] = queryStats["total_queries"].(int) + 1
	if result.Success {
		queryStats["successful_queries"] = queryStats["successful_queries"].(int) + 1
	} else {
		queryStats["failed_queries"] = queryStats["failed_queries"].(int) + 1
	}

	totalDuration := queryStats["total_duration"].(time.Duration) + result.Duration
	queryStats["total_duration"] = totalDuration
	queryStats["avg_duration"] = totalDuration / time.Duration(queryStats["total_queries"].(int))

	c.stats[result.QueryName] = queryStats
}

// GetStats returns current statistics
func (c *Collector) GetStats() map[string]interface{} {
	c.mu.RLock()
	defer c.mu.RUnlock()

	stats := make(map[string]interface{})
	for k, v := range c.stats {
		stats[k] = v
	}
	stats["active_users"] = c.activeUsers
	return stats
}

// PrintStats prints current statistics
func (c *Collector) PrintStats() {
	c.mu.RLock()
	defer c.mu.RUnlock()

	logrus.Info("=== Load Test Statistics ===")
	logrus.Infof("Active Users: %d", c.activeUsers)

	for queryName, queryStats := range c.stats {
		if stats, ok := queryStats.(map[string]interface{}); ok {
			logrus.Infof("Query: %s", queryName)
			logrus.Infof("  Total Queries: %d", stats["total_queries"])
			logrus.Infof("  Successful: %d", stats["successful_queries"])
			logrus.Infof("  Failed: %d", stats["failed_queries"])
			logrus.Infof("  Average Duration: %v", stats["avg_duration"])
		}
	}
}

// collectMetrics collects and logs metrics
func (c *Collector) collectMetrics() {
	c.mu.RLock()
	defer c.mu.RUnlock()

	if c.outputFile != "" {
		stats := c.GetStats()
		data, err := json.MarshalIndent(stats, "", "  ")
		if err != nil {
			logrus.Errorf("Failed to marshal stats: %v", err)
			return
		}

		if err := os.WriteFile(c.outputFile, data, 0644); err != nil {
			logrus.Errorf("Failed to write stats to file: %v", err)
		}
	}
}

// Close closes the metrics collector
func (c *Collector) Close() {
	close(c.stopChan)
	logrus.Info("Metrics collector closed")
}
