package config

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

// EnvConfig holds environment-based configuration
type EnvConfig struct {
	// Server configuration
	ServerPort string
	ServerHost string

	// Database configuration
	DBType     string
	DBHost     string
	DBPort     int
	DBUsername string
	DBPassword string
	DBName     string
	DBSSLMode  string

	// Connection pool settings
	DBMaxOpenConns    int
	DBMaxIdleConns    int
	DBConnMaxLifetime time.Duration
	DBConnMaxIdleTime time.Duration

	// Connection count for load testing
	ConnectionCount int

	// Query configuration
	DefaultQuery string

	// Logging
	LogLevel string

	// Prometheus metrics
	PrometheusEnabled bool
	PrometheusPort    int
	PrometheusPath    string
}

// LoadFromEnv loads configuration from environment variables
func LoadFromEnv() (*EnvConfig, error) {
	config := &EnvConfig{
		// Server defaults
		ServerPort: getEnv("SERVER_PORT", "8080"),
		ServerHost: getEnv("SERVER_HOST", "0.0.0.0"),

		// Database defaults
		DBType:     getEnv("DB_TYPE", "mssql"),
		DBHost:     getEnv("DB_HOST", "localhost"),
		DBPort:     getEnvAsInt("DB_PORT", 1433),
		DBUsername: getEnv("DB_USERNAME", "sa"),
		DBPassword: getEnv("DB_PASSWORD", ""),
		DBName:     getEnv("DB_NAME", "master"),
		DBSSLMode:  getEnv("DB_SSL_MODE", "disable"),

		// Connection pool defaults
		DBMaxOpenConns:    getEnvAsInt("DB_MAX_OPEN_CONNS", 100),
		DBMaxIdleConns:    getEnvAsInt("DB_MAX_IDLE_CONNS", 10),
		DBConnMaxLifetime: getEnvAsDuration("DB_CONN_MAX_LIFETIME", "1h"),
		DBConnMaxIdleTime: getEnvAsDuration("DB_CONN_MAX_IDLE_TIME", "10m"),

		// Connection count for load testing
		ConnectionCount: getEnvAsInt("CONNECTION_COUNT", 10),

		// Query defaults
		DefaultQuery: getEnv("DEFAULT_QUERY", "SELECT 1 as test"),

		// Logging
		LogLevel: getEnv("LOG_LEVEL", "info"),

		// Prometheus metrics
		PrometheusEnabled: getEnv("PROMETHEUS_ENABLED", "false") == "true",
		PrometheusPort:    getEnvAsInt("PROMETHEUS_PORT", 8080),
		PrometheusPath:    getEnv("PROMETHEUS_PATH", "/metrics"),
	}

	// Validate required fields
	if config.DBPassword == "" {
		return nil, fmt.Errorf("DB_PASSWORD environment variable is required")
	}

	return config, nil
}

// GetDSN returns the database connection string for SQL Server
func (c *EnvConfig) GetDSN() string {
	// Only SQL Server is supported
	return fmt.Sprintf("server=%s;port=%d;user id=%s;password=%s;database=%s;encrypt=%s",
		c.DBHost, c.DBPort, c.DBUsername, c.DBPassword, c.DBName, c.DBSSLMode)
}

// GetServerAddress returns the server address
func (c *EnvConfig) GetServerAddress() string {
	return fmt.Sprintf("%s:%s", c.ServerHost, c.ServerPort)
}

// Helper functions
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvAsDuration(key string, defaultValue string) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	if duration, err := time.ParseDuration(defaultValue); err == nil {
		return duration
	}
	return time.Hour // fallback
}
