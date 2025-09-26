package config

import (
	"fmt"
	"time"

	"github.com/spf13/viper"
)

// Config represents the application configuration
type Config struct {
	Database DatabaseConfig `mapstructure:"database"`
	Test     TestConfig     `mapstructure:"test"`
	Metrics  MetricsConfig  `mapstructure:"metrics"`
}

// DatabaseConfig holds database connection settings
type DatabaseConfig struct {
	Type     string `mapstructure:"type"` // mysql, postgres, sqlite
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	Username string `mapstructure:"username"`
	Password string `mapstructure:"password"`
	Database string `mapstructure:"database"`
	SSLMode  string `mapstructure:"ssl_mode"`

	// Connection pool settings
	MaxOpenConns    int           `mapstructure:"max_open_conns"`
	MaxIdleConns    int           `mapstructure:"max_idle_conns"`
	ConnMaxLifetime time.Duration `mapstructure:"conn_max_lifetime"`
	ConnMaxIdleTime time.Duration `mapstructure:"conn_max_idle_time"`
}

// TestConfig holds load test parameters
type TestConfig struct {
	Duration        time.Duration `mapstructure:"duration"`
	ConcurrentUsers int           `mapstructure:"concurrent_users"`
	RampUpTime      time.Duration `mapstructure:"ramp_up_time"`
	ThinkTime       time.Duration `mapstructure:"think_time"`

	// Query settings
	Queries []QueryConfig `mapstructure:"queries"`
}

// QueryConfig defines a test query
type QueryConfig struct {
	Name       string            `mapstructure:"name"`
	SQL        string            `mapstructure:"sql"`
	Weight     int               `mapstructure:"weight"`     // Relative frequency (1-100)
	Type       string            `mapstructure:"type"`       // select, insert, update, delete
	Parameters map[string]string `mapstructure:"parameters"` // Parameter placeholders
}

// MetricsConfig holds metrics collection settings
type MetricsConfig struct {
	Enabled    bool             `mapstructure:"enabled"`
	Interval   time.Duration    `mapstructure:"interval"`
	OutputFile string           `mapstructure:"output_file"`
	Prometheus PrometheusConfig `mapstructure:"prometheus"`
}

// PrometheusConfig holds Prometheus metrics settings
type PrometheusConfig struct {
	Enabled bool   `mapstructure:"enabled"`
	Port    int    `mapstructure:"port"`
	Path    string `mapstructure:"path"`
}

// Load loads configuration from file
func Load(configFile string) (*Config, error) {
	viper.SetConfigFile(configFile)
	viper.SetConfigType("yaml")

	// Set default values
	setDefaults()

	// Read config file
	if err := viper.ReadInConfig(); err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// Validate configuration
	if err := validateConfig(&config); err != nil {
		return nil, fmt.Errorf("invalid configuration: %w", err)
	}

	return &config, nil
}

// setDefaults sets default configuration values
func setDefaults() {
	// Database defaults
	viper.SetDefault("database.type", "mysql")
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", 3306)
	viper.SetDefault("database.max_open_conns", 100)
	viper.SetDefault("database.max_idle_conns", 10)
	viper.SetDefault("database.conn_max_lifetime", "1h")
	viper.SetDefault("database.conn_max_idle_time", "10m")

	// Test defaults
	viper.SetDefault("test.duration", "5m")
	viper.SetDefault("test.concurrent_users", 10)
	viper.SetDefault("test.ramp_up_time", "30s")
	viper.SetDefault("test.think_time", "1s")

	// Metrics defaults
	viper.SetDefault("metrics.enabled", true)
	viper.SetDefault("metrics.interval", "10s")
	viper.SetDefault("metrics.output_file", "metrics.json")
	viper.SetDefault("metrics.prometheus.enabled", false)
	viper.SetDefault("metrics.prometheus.port", 8080)
	viper.SetDefault("metrics.prometheus.path", "/metrics")
}

// validateConfig validates the configuration
func validateConfig(config *Config) error {
	// Validate database type
	validDBTypes := map[string]bool{
		"mysql":    true,
		"postgres": true,
		"sqlite":   true,
	}
	if !validDBTypes[config.Database.Type] {
		return fmt.Errorf("invalid database type: %s", config.Database.Type)
	}

	// Validate test parameters
	if config.Test.Duration <= 0 {
		return fmt.Errorf("test duration must be positive")
	}
	if config.Test.ConcurrentUsers <= 0 {
		return fmt.Errorf("concurrent users must be positive")
	}
	if config.Test.RampUpTime < 0 {
		return fmt.Errorf("ramp-up time cannot be negative")
	}

	// Validate queries
	if len(config.Test.Queries) == 0 {
		return fmt.Errorf("at least one query must be defined")
	}

	for i, query := range config.Test.Queries {
		if query.Name == "" {
			return fmt.Errorf("query %d: name is required", i)
		}
		if query.SQL == "" {
			return fmt.Errorf("query %d: SQL is required", i)
		}
		if query.Weight <= 0 {
			return fmt.Errorf("query %d: weight must be positive", i)
		}
	}

	return nil
}

// GetDSN returns the database connection string
func (c *DatabaseConfig) GetDSN() string {
	switch c.Type {
	case "mysql":
		return fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?parseTime=true&timeout=30s",
			c.Username, c.Password, c.Host, c.Port, c.Database)
	case "postgres":
		dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s",
			c.Host, c.Port, c.Username, c.Password, c.Database)
		if c.SSLMode != "" {
			dsn += fmt.Sprintf(" sslmode=%s", c.SSLMode)
		}
		return dsn
	case "sqlite":
		return c.Database
	default:
		return ""
	}
}
