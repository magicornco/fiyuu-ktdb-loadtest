package loadtest

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"time"

	"fiyuu-ktdb-loadtest/internal/config"
	"fiyuu-ktdb-loadtest/internal/database"
	"fiyuu-ktdb-loadtest/internal/metrics"

	"github.com/sirupsen/logrus"
)

// Worker represents a load test worker
type Worker struct {
	id        int
	config    *config.Config
	dbManager *database.Manager
	metrics   *metrics.Collector
	queries   []config.QueryConfig
	weightSum int
	stopChan  chan struct{}
	ctx       context.Context
	cancel    context.CancelFunc
}

// NewWorker creates a new load test worker
func NewWorker(id int, cfg *config.Config, metrics *metrics.Collector) (*Worker, error) {
	dbManager, err := database.NewManager(&cfg.Database)
	if err != nil {
		return nil, fmt.Errorf("failed to create database manager: %w", err)
	}

	// Calculate total weight for query selection
	weightSum := 0
	for _, query := range cfg.Test.Queries {
		weightSum += query.Weight
	}

	ctx, cancel := context.WithCancel(context.Background())

	return &Worker{
		id:        id,
		config:    cfg,
		dbManager: dbManager,
		metrics:   metrics,
		queries:   cfg.Test.Queries,
		weightSum: weightSum,
		stopChan:  make(chan struct{}),
		ctx:       ctx,
		cancel:    cancel,
	}, nil
}

// Start starts the worker
func (w *Worker) Start() {
	logrus.Debugf("Worker %d started", w.id)
	defer logrus.Debugf("Worker %d stopped", w.id)

	for {
		select {
		case <-w.ctx.Done():
			return
		case <-w.stopChan:
			return
		default:
			w.executeQuery()
			w.thinkTime()
		}
	}
}

// Stop stops the worker
func (w *Worker) Stop() {
	w.cancel()
	close(w.stopChan)
}

// executeQuery executes a randomly selected query
func (w *Worker) executeQuery() {
	query := w.selectQuery()
	if query == nil {
		return
	}

	start := time.Now()
	result := metrics.QueryResult{
		QueryName: query.Name,
		Timestamp: start,
	}

	// Log query execution
	logrus.Debugf("Worker %d: Executing query: %s", w.id, query.Name)

	defer func() {
		result.Duration = time.Since(start)
		w.metrics.RecordQuery(result)
		logrus.Debugf("Worker %d: Query %s completed in %v", w.id, query.Name, result.Duration)
	}()

	// Execute the query based on its type
	switch query.Type {
	case "select":
		w.executeSelectQuery(query, &result)
	case "insert":
		w.executeInsertQuery(query, &result)
	case "update":
		w.executeUpdateQuery(query, &result)
	case "delete":
		w.executeDeleteQuery(query, &result)
	default:
		w.executeGenericQuery(query, &result)
	}
}

// selectQuery selects a query based on weights
func (w *Worker) selectQuery() *config.QueryConfig {
	if len(w.queries) == 0 {
		return nil
	}

	if len(w.queries) == 1 {
		return &w.queries[0]
	}

	// Weighted random selection
	random := rand.Intn(w.weightSum)
	current := 0

	for _, query := range w.queries {
		current += query.Weight
		if random < current {
			return &query
		}
	}

	// Fallback to first query
	return &w.queries[0]
}

// logError logs detailed error information to a separate file
func (w *Worker) logError(queryName, sql, errorMsg string, timestamp time.Time) {
	errorLogFile := "logs/error_logs.json"

	// Create logs directory if it doesn't exist
	if err := os.MkdirAll("logs", 0755); err != nil {
		logrus.Errorf("Failed to create logs directory: %v", err)
		return
	}

	errorEntry := fmt.Sprintf(`{
	"timestamp": "%s",
	"worker_id": %d,
	"query_name": "%s",
	"sql": "%s",
	"error": "%s"
},`, timestamp.Format(time.RFC3339), w.id, queryName, sql, errorMsg)

	// Append to error log file
	file, err := os.OpenFile(errorLogFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		logrus.Errorf("Failed to open error log file: %v", err)
		return
	}
	defer file.Close()

	if _, err := file.WriteString(errorEntry + "\n"); err != nil {
		logrus.Errorf("Failed to write error log: %v", err)
	}
}

// executeSelectQuery executes a SELECT query
func (w *Worker) executeSelectQuery(query *config.QueryConfig, result *metrics.QueryResult) {
	// Log connection pool stats every 100 queries
	if w.id%100 == 0 {
		stats := w.dbManager.GetStats()
		logrus.Debugf("Worker %d: Pool stats - Open: %d, InUse: %d, Idle: %d, WaitCount: %d",
			w.id, stats.OpenConnections, stats.InUse, stats.Idle, stats.WaitCount)
	}

	rows, err := w.dbManager.ExecuteQuery(query.SQL)
	if err != nil {
		result.Success = false
		result.Error = err.Error()
		logrus.Debugf("Worker %d: SELECT query failed: %v", w.id, err)

		// Log detailed error
		w.logError(query.Name, query.SQL, err.Error(), time.Now())
		return
	}
	defer func() {
		if err := rows.Close(); err != nil {
			logrus.Debugf("Worker %d: Failed to close rows: %v", w.id, err)
			w.logError(query.Name, "rows.Close()", err.Error(), time.Now())
		}
	}()

	// Count rows
	count := 0
	for rows.Next() {
		count++
		// Optionally scan the row to simulate real usage
		if count > 1000 { // Limit to prevent memory issues
			break
		}
	}

	if err := rows.Err(); err != nil {
		result.Success = false
		result.Error = err.Error()
		w.logError(query.Name, query.SQL, err.Error(), time.Now())
		return
	}

	result.Success = true
	result.RowsAffected = int64(count)
}

// executeInsertQuery executes an INSERT query
func (w *Worker) executeInsertQuery(query *config.QueryConfig, result *metrics.QueryResult) {
	res, err := w.dbManager.ExecuteExec(query.SQL)
	if err != nil {
		result.Success = false
		result.Error = err.Error()
		logrus.Debugf("Worker %d: INSERT query failed: %v", w.id, err)
		w.logError(query.Name, query.SQL, err.Error(), time.Now())
		return
	}

	rowsAffected, err := res.RowsAffected()
	if err != nil {
		result.Success = false
		result.Error = err.Error()
		w.logError(query.Name, query.SQL, err.Error(), time.Now())
		return
	}

	result.Success = true
	result.RowsAffected = rowsAffected
}

// executeUpdateQuery executes an UPDATE query
func (w *Worker) executeUpdateQuery(query *config.QueryConfig, result *metrics.QueryResult) {
	res, err := w.dbManager.ExecuteExec(query.SQL)
	if err != nil {
		result.Success = false
		result.Error = err.Error()
		logrus.Debugf("Worker %d: UPDATE query failed: %v", w.id, err)
		return
	}

	rowsAffected, err := res.RowsAffected()
	if err != nil {
		result.Success = false
		result.Error = err.Error()
		return
	}

	result.Success = true
	result.RowsAffected = rowsAffected
}

// executeDeleteQuery executes a DELETE query
func (w *Worker) executeDeleteQuery(query *config.QueryConfig, result *metrics.QueryResult) {
	res, err := w.dbManager.ExecuteExec(query.SQL)
	if err != nil {
		result.Success = false
		result.Error = err.Error()
		logrus.Debugf("Worker %d: DELETE query failed: %v", w.id, err)
		return
	}

	rowsAffected, err := res.RowsAffected()
	if err != nil {
		result.Success = false
		result.Error = err.Error()
		return
	}

	result.Success = true
	result.RowsAffected = rowsAffected
}

// executeGenericQuery executes a generic query
func (w *Worker) executeGenericQuery(query *config.QueryConfig, result *metrics.QueryResult) {
	// Try to determine if it's a SELECT query by checking if it returns rows
	rows, err := w.dbManager.ExecuteQuery(query.SQL)
	if err != nil {
		result.Success = false
		result.Error = err.Error()
		logrus.Debugf("Worker %d: Generic query failed: %v", w.id, err)
		return
	}
	defer rows.Close()

	// If it's a SELECT query, count rows
	if rows.Next() {
		count := 1
		for rows.Next() {
			count++
			if count > 1000 { // Limit to prevent memory issues
				break
			}
		}
		result.RowsAffected = int64(count)
	} else {
		// It's not a SELECT query, try to get affected rows
		if res, err := w.dbManager.ExecuteExec(query.SQL); err == nil {
			if rowsAffected, err := res.RowsAffected(); err == nil {
				result.RowsAffected = rowsAffected
			}
		}
	}

	if err := rows.Err(); err != nil {
		result.Success = false
		result.Error = err.Error()
		return
	}

	result.Success = true
}

// thinkTime adds a delay between queries
func (w *Worker) thinkTime() {
	if w.config.Test.ThinkTime > 0 {
		// Add some randomness to think time (±20%)
		randomFactor := 0.8 + rand.Float64()*0.4
		thinkTime := time.Duration(float64(w.config.Test.ThinkTime) * randomFactor)
		time.Sleep(thinkTime)
	}
}

// Close closes the worker and its database connection
func (w *Worker) Close() error {
	w.Stop()
	return w.dbManager.Close()
}
