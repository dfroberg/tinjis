package main

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"os"
        "time"

	"github.com/gorilla/mux"
)

type App struct {
	Router *mux.Router
	// DB     *sql.DB // If DB backend is required add it here
}

type ProcessPaymentRequest struct {
	Id       int     `json:"customer_id,omitempty"`
	Currency string  `json:"currency,omitempty"`
	Value    float32 `json:"value,omitempty"`
}

func (a *App) Initialize() {
	a.Router = mux.NewRouter()
	a.setupRoutes()
}
func (a *App) Run(addr string) {
	log.Fatal(http.ListenAndServe(addr, a.Router))
}

func (a *App) setupRoutes() {

	api := a.Router.PathPrefix("/").Subrouter()
	api.HandleFunc("/", a.processPaymentRequest).Methods("POST")
	a.Router.HandleFunc("/ping", a.pingRoute).Methods("GET")
	a.Router.HandleFunc("/health", a.healthCheck).Methods("GET")
	// Setup MiddleWare for Auth
	amw := authenticationMiddleware{make(map[string]string)}
	amw.PopulateAllowedTokens()
	api.Use(amw.Middleware)
}

// Define our auth struct
type authenticationMiddleware struct {
	tokenUsers map[string]string
}

// Loads allowed tokens
func (amw *authenticationMiddleware) PopulateAllowedTokens() {
	// Picks a single predefined token, should probably be linked to a database of allowed users.
	token := os.Getenv("PAYMENTS_API_TOKEN")
	amw.tokenUsers[token] = "antaeus"
}

// Middleware function, which will be called for each request
func (amw *authenticationMiddleware) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := r.Header.Get("X-Token")
		if user, found := amw.tokenUsers[token]; found {
			// We found the token in our map
			log.Printf("Authenticated user %s\n", user)
			next.ServeHTTP(w, r)
		} else {
			log.Printf("Unauthenticated user\n")
			http.Error(w, "Forbidden", http.StatusForbidden)
		}
	})
}

func (a *App) pingRoute(w http.ResponseWriter, r *http.Request) {
	log.Printf("ping recieved\n")
	respondWithJSON(w, http.StatusOK, map[string]string{"ping": "pong"})
}

func (a *App) healthCheck(w http.ResponseWriter, r *http.Request) {
	log.Printf("healthcheck recieved\n")
	respondWithJSON(w, http.StatusOK, map[string]string{"alive": "true"})
}

func (a *App) processPaymentRequest(w http.ResponseWriter, r *http.Request) {
	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"result": "false", "error": "Invalid Request"})
		return
	}
	println(string(body))
	var pr ProcessPaymentRequest
	err = json.Unmarshal(body, &pr)
	if err != nil {
		println(err.Error())
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"result": "false", "error": "Invalid Request"})
		return
	}

	if pr.Id < 1 || pr.Value < 0 || pr.Currency == "" {
		respondWithJSON(w, http.StatusBadRequest, map[string]string{"result": "false", "error": "Invalid Request. Missing or faulty fields"})
		return
	}
	rand.Seed(time.Now().UnixNano())
	success := rand.Intn(2)
	if success == 0 {
		respondWithJSON(w, http.StatusOK, map[string]string{"result": "true"})
		return
	}
	respondWithJSON(w, http.StatusOK, map[string]string{"result": "false"})
}

func respondWithJSON(w http.ResponseWriter, code int, payload interface{}) {
	response, _ := json.Marshal(payload)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	w.Write(response)
}

func main() {
	a := App{}
	a.Initialize()
	a.Run(":9000")
}
