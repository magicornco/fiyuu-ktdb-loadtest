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

	db, err := sql.Open(cfg.Type, dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(cfg.MaxOpenConns)
	db.SetMaxIdleConns(cfg.MaxIdleConns)
	db.SetConnMaxLifetime(cfg.ConnMaxLifetime)
	db.SetConnMaxIdleTime(cfg.ConnMaxIdleTime)

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
	return m.db.Close()
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
	return m.db.Query(query, args...)
}

// ExecuteQueryRow executes a query that returns a single row
func (m *Manager) ExecuteQueryRow(query string, args ...interface{}) *sql.Row {
	return m.db.QueryRow(query, args...)
}

// ExecuteExec executes a query that doesn't return rows
func (m *Manager) ExecuteExec(query string, args ...interface{}) (sql.Result, error) {
	return m.db.Exec(query, args...)
}

// BeginTransaction starts a new transaction
func (m *Manager) BeginTransaction() (*sql.Tx, error) {
	return m.db.Begin()
}

// PrepareStatement prepares a statement for execution
func (m *Manager) PrepareStatement(query string) (*sql.Stmt, error) {
	return m.db.Prepare(query)
}
