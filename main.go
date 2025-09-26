package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"fiyuu-ktdb-loadtest/internal/config"
	"fiyuu-ktdb-loadtest/internal/loadtest"
	"fiyuu-ktdb-loadtest/internal/metrics"
	"fiyuu-ktdb-loadtest/internal/server"

	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var (
	configFile string
	verbose    bool
	serverMode bool
)

func main() {
	rootCmd := &cobra.Command{
		Use:   "fiyuu-ktdb",
		Short: "Fiyuu KTDB Web Server",
		Long:  "Asynchronous web server for SQL database operations with environment-based configuration",
		RunE:  run,
	}

	rootCmd.Flags().StringVarP(&configFile, "config", "c", "config.yaml", "Configuration file path (for load test mode)")
	rootCmd.Flags().BoolVarP(&verbose, "verbose", "v", false, "Enable verbose logging")
	rootCmd.Flags().BoolVarP(&serverMode, "server", "s", true, "Run in server mode (default: true)")

	if err := rootCmd.Execute(); err != nil {
		logrus.Fatal(err)
	}
}

func run(cmd *cobra.Command, args []string) error {
	// Setup logging
	setupLogging()

	if serverMode {
		return runServer()
	}

	return runLoadTest()
}

func setupLogging() {
	// Set log level from environment or flag
	logLevel := os.Getenv("LOG_LEVEL")
	if verbose {
		logLevel = "debug"
	}

	switch logLevel {
	case "debug":
		logrus.SetLevel(logrus.DebugLevel)
	case "info":
		logrus.SetLevel(logrus.InfoLevel)
	case "warn":
		logrus.SetLevel(logrus.WarnLevel)
	case "error":
		logrus.SetLevel(logrus.ErrorLevel)
	default:
		logrus.SetLevel(logrus.InfoLevel)
	}

	// Set JSON formatter for production
	if os.Getenv("LOG_FORMAT") == "json" {
		logrus.SetFormatter(&logrus.JSONFormatter{})
	}
}

func runServer() error {
	// Load configuration from environment variables
	cfg, err := config.LoadFromEnv()
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	logrus.Info("Starting Fiyuu KTDB Web Server...")
	logrus.Infof("Server: %s", cfg.GetServerAddress())
	logrus.Infof("Database: %s://%s:%d/%s", cfg.DBType, cfg.DBHost, cfg.DBPort, cfg.DBName)
	logrus.Infof("Connection Count: %d", cfg.ConnectionCount)
	logrus.Infof("Max Open Connections: %d", cfg.DBMaxOpenConns)
	logrus.Infof("Max Idle Connections: %d", cfg.DBMaxIdleConns)
	logrus.Infof("Default Query: %s", cfg.DefaultQuery)

	// Create and start server
	srv, err := server.NewServer(cfg)
	if err != nil {
		return fmt.Errorf("failed to create server: %w", err)
	}

	// Create context with cancellation
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Setup signal handling
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigChan
		logrus.Info("Received interrupt signal, shutting down gracefully...")
		cancel()
	}()

	// Start server in goroutine
	serverErr := make(chan error, 1)
	go func() {
		serverErr <- srv.Start()
	}()

	// Wait for context cancellation or server error
	select {
	case <-ctx.Done():
		logrus.Info("Shutting down server...")
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer shutdownCancel()

		if err := srv.Stop(shutdownCtx); err != nil {
			logrus.Errorf("Error during server shutdown: %v", err)
		}

		return nil
	case err := <-serverErr:
		if err != nil {
			return fmt.Errorf("server error: %w", err)
		}
		return nil
	}
}

func runLoadTest() error {
	// Load configuration from file
	cfg, err := config.Load(configFile)
	if err != nil {
		return fmt.Errorf("failed to load configuration: %w", err)
	}

	// Create context with cancellation
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Setup signal handling
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigChan
		logrus.Info("Received interrupt signal, shutting down gracefully...")
		cancel()
	}()

	// Initialize metrics collector
	metricsCollector := metrics.NewCollector()
	defer metricsCollector.Close()

	// Start Prometheus metrics server if enabled
	if cfg.Metrics.Prometheus.Enabled {
		go func() {
			http.Handle(cfg.Metrics.Prometheus.Path, promhttp.Handler())
			addr := fmt.Sprintf(":%d", cfg.Metrics.Prometheus.Port)
			logrus.Infof("Starting Prometheus metrics server on %s%s", addr, cfg.Metrics.Prometheus.Path)
			if err := http.ListenAndServe(addr, nil); err != nil {
				logrus.Errorf("Prometheus metrics server error: %v", err)
			}
		}()
	}

	// Create and run load test
	loadTester := loadtest.NewLoadTester(cfg, metricsCollector)

	logrus.Info("Starting load test...")
	logrus.Infof("Database: %s", cfg.Database.Type)
	logrus.Infof("Duration: %v", cfg.Test.Duration)
	logrus.Infof("Concurrent users: %d", cfg.Test.ConcurrentUsers)
	logrus.Infof("Ramp-up time: %v", cfg.Test.RampUpTime)

	if err := loadTester.Run(ctx); err != nil {
		return fmt.Errorf("load test failed: %w", err)
	}

	logrus.Info("Load test completed successfully")
	return nil
}
