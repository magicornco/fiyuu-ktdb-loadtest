package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"fiyuu-ktdb-loadtest/internal/config"

	_ "github.com/microsoft/go-mssqldb"
	"github.com/sirupsen/logrus"
)

// Manager handles database connections
type Manager struct {
	db   *sql.DB
	cfg  *config.DatabaseConfig
	done chan struct{}
}

// NewManager creates a new database manager
func NewManager(cfg *config.DatabaseConfig) (*Manager, error) {
	dsn := cfg.GetDSN()
	if dsn == "" {
		return nil, fmt.Errorf("unsupported database type: %s", cfg.Type)
	}

	db, err := sql.Open("sqlserver", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(cfg.MaxOpenConns)
	db.SetMaxIdleConns(cfg.MaxIdleConns)
	db.SetConnMaxLifetime(cfg.ConnMaxLifetime)
	db.SetConnMaxIdleTime(cfg.ConnMaxIdleTime)

	// Set connection wait timeout to prevent blocking
	db.SetConnMaxLifetime(cfg.ConnMaxLifetime)

	// Test connection
	if err := db.Ping(); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	logrus.Infof("Connected to %s database at %s:%d", cfg.Type, cfg.Host, cfg.Port)

	return &Manager{
		db:   db,
		cfg:  cfg,
		done: make(chan struct{}),
	}, nil
}

// GetDB returns the database connection
func (m *Manager) GetDB() *sql.DB {
	return m.db
}

// Close closes the database connection
func (m *Manager) Close() error {
	close(m.done)

	// Force close all connections
	if m.db != nil {
		// Close all idle connections
		m.db.SetMaxIdleConns(0)
		m.db.SetMaxOpenConns(0)

		// Close the database
		err := m.db.Close()
		if err != nil {
			logrus.Errorf("Error closing database: %v", err)
		}

		logrus.Debugf("Database connections closed")
	}

	return nil
}

// HealthCheck performs a health check on the database
func (m *Manager) HealthCheck() error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	done := make(chan error, 1)
	go func() {
		done <- m.db.Ping()
	}()

	select {
	case err := <-done:
		return err
	case <-ctx.Done():
		return fmt.Errorf("health check timeout")
	}
}

// GetStats returns database connection statistics
func (m *Manager) GetStats() sql.DBStats {
	return m.db.Stats()
}

// ExecuteQuery executes a query and returns the result
func (m *Manager) ExecuteQuery(query string, args ...interface{}) (*sql.Rows, error) {
	// Use config timeout or default 30 seconds
	timeout := m.cfg.QueryTimeout
	if timeout <= 0 {
		timeout = 30 * time.Second
	}

	// Use context with timeout to ensure connection is returned to pool
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	rows, err := m.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}

	return rows, nil
}

// ExecuteQueryRow executes a query that returns a single row
func (m *Manager) ExecuteQueryRow(query string, args ...interface{}) *sql.Row {
	return m.db.QueryRow(query, args...)
}

// ExecuteExec executes a query that doesn't return rows
func (m *Manager) ExecuteExec(query string, args ...interface{}) (sql.Result, error) {
	// Use config timeout or default 30 seconds
	timeout := m.cfg.QueryTimeout
	if timeout <= 0 {
		timeout = 30 * time.Second
	}

	// Use context with timeout to ensure connection is returned to pool
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	return m.db.ExecContext(ctx, query, args...)
}

// BeginTransaction starts a new transaction
func (m *Manager) BeginTransaction() (*sql.Tx, error) {
	return m.db.Begin()
}

// PrepareStatement prepares a statement for execution
func (m *Manager) PrepareStatement(query string) (*sql.Stmt, error) {
	return m.db.Prepare(query)
}
