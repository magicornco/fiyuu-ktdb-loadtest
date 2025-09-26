package loadtest

import (
	"context"
	"fmt"
	"sync"
	"time"

	"fiyuu-ktdb-loadtest/internal/config"
	"fiyuu-ktdb-loadtest/internal/metrics"

	"github.com/sirupsen/logrus"
)

// LoadTester manages the load test execution
type LoadTester struct {
	config    *config.Config
	metrics   *metrics.Collector
	workers   []*Worker
	wg        sync.WaitGroup
	closeOnce sync.Once  // Prevent double close
}

// NewLoadTester creates a new load tester
func NewLoadTester(cfg *config.Config, metrics *metrics.Collector) *LoadTester {
	return &LoadTester{
		config:  cfg,
		metrics: metrics,
		workers: make([]*Worker, 0),
	}
}

// Run executes the load test
func (lt *LoadTester) Run(ctx context.Context) error {
	// Configure metrics collector
	if lt.config.Metrics.Enabled {
		lt.metrics.SetOutputFile(lt.config.Metrics.OutputFile)
		lt.metrics.SetInterval(lt.config.Metrics.Interval)

		if lt.config.Metrics.Prometheus.Enabled {
			lt.metrics.EnablePrometheus("fiyuu_ktdb_loadtest")
		}

		// Start metrics collection
		go lt.metrics.Start()
	}

	// Create and start workers with ramp-up
	if err := lt.startWorkers(ctx); err != nil {
		return fmt.Errorf("failed to start workers: %w", err)
	}

	// Wait for test duration or context cancellation
	select {
	case <-ctx.Done():
		logrus.Info("Test cancelled by user")
	case <-time.After(lt.config.Test.Duration):
		logrus.Info("Test duration completed")
	}

	// Stop all workers
	lt.stopWorkers()

	// Wait for all workers to finish
	lt.wg.Wait()

	// Print final statistics
	lt.metrics.PrintStats()

	return nil
}

// startWorkers starts workers with ramp-up
func (lt *LoadTester) startWorkers(ctx context.Context) error {
	concurrentUsers := lt.config.Test.ConcurrentUsers
	rampUpTime := lt.config.Test.RampUpTime

	if rampUpTime <= 0 {
		// Start all workers immediately
		return lt.startWorkerBatch(0, concurrentUsers, ctx)
	}

	// Calculate ramp-up parameters
	rampUpInterval := rampUpTime / time.Duration(concurrentUsers)
	if rampUpInterval < time.Millisecond {
		rampUpInterval = time.Millisecond
	}

	logrus.Infof("Starting %d workers with %v ramp-up interval", concurrentUsers, rampUpInterval)

	// Start workers gradually
	for i := 0; i < concurrentUsers; i++ {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
			if err := lt.startWorkerBatch(i, 1, ctx); err != nil {
				return err
			}

			// Update active users count
			lt.metrics.SetActiveUsers(i + 1)

			if i < concurrentUsers-1 {
				time.Sleep(rampUpInterval)
			}
		}
	}

	return nil
}

// startWorkerBatch starts a batch of workers
func (lt *LoadTester) startWorkerBatch(startID, count int, ctx context.Context) error {
	for i := 0; i < count; i++ {
		workerID := startID + i

		worker, err := NewWorker(workerID, lt.config, lt.metrics)
		if err != nil {
			return fmt.Errorf("failed to create worker %d: %w", workerID, err)
		}

		lt.workers = append(lt.workers, worker)
		lt.wg.Add(1)

		go func(w *Worker) {
			defer lt.wg.Done()
			w.Start()
		}(worker)
	}

	return nil
}

// stopWorkers stops all workers
func (lt *LoadTester) stopWorkers() {
	logrus.Info("Stopping all workers...")

	for _, worker := range lt.workers {
		worker.Stop()
	}
}

// Close closes the load tester and cleans up resources
func (lt *LoadTester) Close() error {
	var lastErr error

	lt.closeOnce.Do(func() {
		logrus.Info("Closing all workers and cleaning up connections...")
		
		for i, worker := range lt.workers {
			if worker != nil {
				if err := worker.Close(); err != nil {
					lastErr = err
					logrus.Errorf("Failed to close worker %d: %v", i, err)
				}
			}
		}

		// Clear workers slice
		lt.workers = nil
		
		lt.metrics.Close()

		logrus.Info("All connections cleaned up")
	})

	return lastErr
}

// GetStats returns current load test statistics
func (lt *LoadTester) GetStats() map[string]interface{} {
	stats := lt.metrics.GetStats()
	stats["active_workers"] = len(lt.workers)
	stats["target_workers"] = lt.config.Test.ConcurrentUsers
	return stats
}
