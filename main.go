package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
	"github.com/go-redis/redis/v8"
	"github.com/julienschmidt/httprouter"
	"go.uber.org/zap"
)

type server struct {
	redis  redis.UniversalClient
	logger *zap.Logger
}

var httpRequestsTotal = prometheus.NewCounterVec(
    prometheus.CounterOpts{
        Name: "http_requests_total",
        Help: "Total number of HTTP requests by status code, method, and path.",
    },
    []string{"code", "method", "path"},
)

func init() {
    prometheus.MustRegister(httpRequestsTotal)
}

type responseWriter struct {
    http.ResponseWriter
    statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
    rw.statusCode = code
    rw.ResponseWriter.WriteHeader(code)
}

func newPrometheusMiddleware(next httprouter.Handle) httprouter.Handle {
    return func(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
        wrappedWriter := &responseWriter{ResponseWriter: w, statusCode: 200} 
        next(wrappedWriter, r, ps)

        httpRequestsTotal.With(prometheus.Labels{
            "code":   fmt.Sprintf("%d", wrappedWriter.statusCode),
            "method": r.Method,
            "path":   r.URL.Path,
        }).Inc()
    }
}

func main() {
	logger, err := zap.NewProduction()
	if err != nil {
		log.Fatal("unable to initialize logger")
	}

	rdb := redis.NewUniversalClient(&redis.UniversalOptions{
		Addrs:    []string{os.Getenv("REDIS_ADDR")},
		Password: "",
		DB:       0,
	})

	srv := &server{
		redis:  rdb,
		logger: logger,
	}

	router := httprouter.New()
	router.GET("/", newPrometheusMiddleware(srv.indexHandler))
	router.GET("/hello", newPrometheusMiddleware(srv.helloHandler))
	router.Handler("GET", "/metrics", promhttp.Handler())

	logger.Info("server started on port 8080")
	log.Fatal(http.ListenAndServe(":8080", router))
}

func (s *server) indexHandler(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
	var v string
	var err error
	if v, err = s.redis.Get(context.Background(), "updated_time").Result(); err != nil {
		s.logger.Info("updated_time not found, setting it")
		v = time.Now().Format("2006-01-02 15:04:05")
		s.redis.Set(context.Background(), "updated_time", v, 5*time.Second)
	} else {
		s.logger.Info("got updated_time")
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Hello world: updated_time=%s\n", v)
}