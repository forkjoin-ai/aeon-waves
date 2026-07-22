package main

import (
	"encoding/json"
	"fmt"
	"net/http"
)

// HandleRequest processes incoming API requests.
func HandleRequest(w http.ResponseWriter, r *http.Request) error {
	data, err := parseBody(r)
	if err != nil {
		return fmt.Errorf("parse error: %w", err)
	}

	result := processData(data)
	return writeJSON(w, result)
}

func parseBody(r *http.Request) (map[string]interface{}, error) {
	var data map[string]interface{}
	decoder := json.NewDecoder(r.Body)
	if err := decoder.Decode(&data); err != nil {
		return nil, err
	}
	return data, nil
}

func processData(data map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})
	for k, v := range data {
		result[k] = v
	}
	result["processed"] = true
	return result
}

func writeJSON(w http.ResponseWriter, data interface{}) error {
	w.Header().Set("Content-Type", "application/json")
	return json.NewEncoder(w).Encode(data)
}
