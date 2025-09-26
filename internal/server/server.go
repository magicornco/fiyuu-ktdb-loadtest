package server

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"fiyuu-ktdb-loadtest/internal/config"
	"fiyuu-ktdb-loadtest/internal/database"

	"github.com/gorilla/mux"
	_ "github.com/microsoft/go-mssqldb"
	"github.com/sirupsen/logrus"
)

// Server represents the HTTP server
type Server struct {
	config    *config.EnvConfig
	dbManager *database.Manager
	router    *mux.Router
	server    *http.Server
}

// QueryRequest represents a query request
type QueryRequest struct {
	Query string `json:"query"`
}

// QueryResponse represents a query response
type QueryResponse struct {
	Success      bool                     `json:"success"`
	Data         []map[string]interface{} `json:"data,omitempty"`
	Error        string                   `json:"error,omitempty"`
	Duration     time.Duration            `json:"duration"`
	RowsAffected int64                    `json:"rows_affected,omitempty"`
	Timestamp    time.Time                `json:"timestamp"`
}

// HealthResponse represents a health check response
type HealthResponse struct {
	Status    string        `json:"status"`
	Database  string        `json:"database"`
	Uptime    time.Duration `json:"uptime"`
	Timestamp time.Time     `json:"timestamp"`
}

// NewServer creates a new HTTP server
func NewServer(cfg *config.EnvConfig) (*Server, error) {
	// Create database manager
	dbConfig := &config.DatabaseConfig{
		Type:            cfg.DBType,
		Host:            cfg.DBHost,
		Port:            cfg.DBPort,
		Username:        cfg.DBUsername,
		Password:        cfg.DBPassword,
		Database:        cfg.DBName,
		SSLMode:         cfg.DBSSLMode,
		MaxOpenConns:    cfg.DBMaxOpenConns,
		MaxIdleConns:    cfg.DBMaxIdleConns,
		ConnMaxLifetime: cfg.DBConnMaxLifetime,
		ConnMaxIdleTime: cfg.DBConnMaxIdleTime,
	}

	dbManager, err := database.NewManager(dbConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create database manager: %w", err)
	}

	router := mux.NewRouter()
	server := &Server{
		config:    cfg,
		dbManager: dbManager,
		router:    router,
	}

	server.setupRoutes()

	return server, nil
}

// setupRoutes sets up the HTTP routes
func (s *Server) setupRoutes() {
	// API routes
	api := s.router.PathPrefix("/api/v1").Subrouter()

	// Query endpoint
	api.HandleFunc("/query", s.handleQuery).Methods("POST")
	api.HandleFunc("/query", s.handleDefaultQuery).Methods("GET")

	// Health check
	api.HandleFunc("/health", s.handleHealth).Methods("GET")

	// Database info
	api.HandleFunc("/db/info", s.handleDBInfo).Methods("GET")
	api.HandleFunc("/db/stats", s.handleDBStats).Methods("GET")

	// Prometheus metrics endpoint
	if s.config.PrometheusEnabled {
		s.router.HandleFunc(s.config.PrometheusPath, s.handlePrometheusMetrics).Methods("GET")
	}

	// Root endpoint
	s.router.HandleFunc("/", s.handleRoot).Methods("GET")

	// Add middleware
	s.router.Use(s.loggingMiddleware)
	s.router.Use(s.corsMiddleware)
}

// Start starts the HTTP server
func (s *Server) Start() error {
	s.server = &http.Server{
		Addr:         s.config.GetServerAddress(),
		Handler:      s.router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	logrus.Infof("Starting server on %s", s.config.GetServerAddress())
	return s.server.ListenAndServe()
}

// Stop stops the HTTP server
func (s *Server) Stop(ctx context.Context) error {
	logrus.Info("Stopping server...")

	if s.dbManager != nil {
		s.dbManager.Close()
	}

	return s.server.Shutdown(ctx)
}

// handleQuery handles POST /api/v1/query
func (s *Server) handleQuery(w http.ResponseWriter, r *http.Request) {
	var req QueryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		s.sendErrorResponse(w, http.StatusBadRequest, "Invalid JSON", err)
		return
	}

	if req.Query == "" {
		s.sendErrorResponse(w, http.StatusBadRequest, "Query is required", nil)
		return
	}

	s.executeQuery(w, req.Query)
}

// handleDefaultQuery handles GET /api/v1/query
func (s *Server) handleDefaultQuery(w http.ResponseWriter, r *http.Request) {
	s.executeQuery(w, s.config.DefaultQuery)
}

// executeQuery executes a SQL query
func (s *Server) executeQuery(w http.ResponseWriter, query string) {
	start := time.Now()
	response := QueryResponse{
		Timestamp: start,
	}

	defer func() {
		response.Duration = time.Since(start)
		s.sendJSONResponse(w, http.StatusOK, response)
	}()

	// Execute the query
	rows, err := s.dbManager.ExecuteQuery(query)
	if err != nil {
		response.Success = false
		response.Error = err.Error()
		logrus.Errorf("Query execution failed: %v", err)
		return
	}
	defer rows.Close()

	// Get column names
	columns, err := rows.Columns()
	if err != nil {
		response.Success = false
		response.Error = err.Error()
		return
	}

	// Scan rows
	var results []map[string]interface{}
	for rows.Next() {
		// Create a slice of interface{} to hold the values
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		for i := range columns {
			valuePtrs[i] = &values[i]
		}

		// Scan the row
		if err := rows.Scan(valuePtrs...); err != nil {
			response.Success = false
			response.Error = err.Error()
			return
		}

		// Create a map for this row
		row := make(map[string]interface{})
		for i, col := range columns {
			val := values[i]
			if val != nil {
				// Handle different types
				switch v := val.(type) {
				case []byte:
					row[col] = string(v)
				case time.Time:
					row[col] = v.Format(time.RFC3339)
				default:
					row[col] = v
				}
			} else {
				row[col] = nil
			}
		}
		results = append(results, row)
	}

	if err := rows.Err(); err != nil {
		response.Success = false
		response.Error = err.Error()
		return
	}

	response.Success = true
	response.Data = results
	response.RowsAffected = int64(len(results))
}

// handleHealth handles GET /api/v1/health
func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	response := HealthResponse{
		Timestamp: time.Now(),
	}

	// Check database connection
	if err := s.dbManager.HealthCheck(); err != nil {
		response.Status = "unhealthy"
		response.Database = "disconnected"
		s.sendJSONResponse(w, http.StatusServiceUnavailable, response)
		return
	}

	response.Status = "healthy"
	response.Database = "connected"
	s.sendJSONResponse(w, http.StatusOK, response)
}

// handleDBInfo handles GET /api/v1/db/info
func (s *Server) handleDBInfo(w http.ResponseWriter, r *http.Request) {
	info := map[string]interface{}{
		"type":             s.config.DBType,
		"host":             s.config.DBHost,
		"port":             s.config.DBPort,
		"database":         s.config.DBName,
		"username":         s.config.DBUsername,
		"ssl_mode":         s.config.DBSSLMode,
		"max_open_conns":   s.config.DBMaxOpenConns,
		"max_idle_conns":   s.config.DBMaxIdleConns,
		"connection_count": s.config.ConnectionCount,
	}

	s.sendJSONResponse(w, http.StatusOK, info)
}

// handleDBStats handles GET /api/v1/db/stats
func (s *Server) handleDBStats(w http.ResponseWriter, r *http.Request) {
	stats := s.dbManager.GetStats()
	s.sendJSONResponse(w, http.StatusOK, stats)
}

// handleRoot handles GET /
func (s *Server) handleRoot(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"service": "Fiyuu KTDB Web Server",
		"version": "1.0.0",
		"endpoints": map[string]string{
			"health":   "/api/v1/health",
			"query":    "/api/v1/query",
			"db_info":  "/api/v1/db/info",
			"db_stats": "/api/v1/db/stats",
		},
		"timestamp": time.Now(),
	}

	s.sendJSONResponse(w, http.StatusOK, response)
}

// sendJSONResponse sends a JSON response
func (s *Server) sendJSONResponse(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

// sendErrorResponse sends an error response
func (s *Server) sendErrorResponse(w http.ResponseWriter, statusCode int, message string, err error) {
	response := map[string]interface{}{
		"success":   false,
		"error":     message,
		"timestamp": time.Now(),
	}

	if err != nil {
		response["details"] = err.Error()
		logrus.Errorf("Error: %s - %v", message, err)
	}

	s.sendJSONResponse(w, statusCode, response)
}

// loggingMiddleware logs HTTP requests
func (s *Server) loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Create a response writer wrapper to capture status code
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		next.ServeHTTP(wrapped, r)

		duration := time.Since(start)
		logrus.Infof("%s %s %d %v", r.Method, r.URL.Path, wrapped.statusCode, duration)
	})
}

// corsMiddleware adds CORS headers
func (s *Server) corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// responseWriter wraps http.ResponseWriter to capture status code
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// handlePrometheusMetrics handles Prometheus metrics endpoint
func (s *Server) handlePrometheusMetrics(w http.ResponseWriter, r *http.Request) {
	// Get database stats
	stats := s.dbManager.GetStats()

	// Format as Prometheus metrics
	metrics := fmt.Sprintf(`# HELP fiyuu_ktdb_connections_open Current number of open connections
# TYPE fiyuu_ktdb_connections_open gauge
fiyuu_ktdb_connections_open %d

# HELP fiyuu_ktdb_connections_idle Current number of idle connections
# TYPE fiyuu_ktdb_connections_idle gauge
fiyuu_ktdb_connections_idle %d

# HELP fiyuu_ktdb_connections_in_use Current number of connections in use
# TYPE fiyuu_ktdb_connections_in_use gauge
fiyuu_ktdb_connections_in_use %d

# HELP fiyuu_ktdb_connections_wait_count Total number of connections waited for
# TYPE fiyuu_ktdb_connections_wait_count counter
fiyuu_ktdb_connections_wait_count %d

# HELP fiyuu_ktdb_connections_wait_duration Total time blocked waiting for a new connection
# TYPE fiyuu_ktdb_connections_wait_duration counter
fiyuu_ktdb_connections_wait_duration %d

# HELP fiyuu_ktdb_connections_max_idle_closed Total number of connections closed due to SetMaxIdleConns
# TYPE fiyuu_ktdb_connections_max_idle_closed counter
fiyuu_ktdb_connections_max_idle_closed %d

# HELP fiyuu_ktdb_connections_max_idle_time_closed Total number of connections closed due to SetConnMaxIdleTime
# TYPE fiyuu_ktdb_connections_max_idle_time_closed counter
fiyuu_ktdb_connections_max_idle_time_closed %d

# HELP fiyuu_ktdb_connections_max_lifetime_closed Total number of connections closed due to SetConnMaxLifetime
# TYPE fiyuu_ktdb_connections_max_lifetime_closed counter
fiyuu_ktdb_connections_max_lifetime_closed %d

# HELP fiyuu_ktdb_server_info Server information
# TYPE fiyuu_ktdb_server_info gauge
fiyuu_ktdb_server_info{database_type="%s",database_host="%s",database_name="%s"} 1
`,
		stats.OpenConnections,
		stats.Idle,
		stats.InUse,
		stats.WaitCount,
		stats.WaitDuration.Milliseconds(),
		stats.MaxIdleClosed,
		stats.MaxIdleTimeClosed,
		stats.MaxLifetimeClosed,
		s.config.DBType,
		s.config.DBHost,
		s.config.DBName,
	)

	w.Header().Set("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
	w.Write([]byte(metrics))
}
