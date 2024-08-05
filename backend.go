// Backend for Roblox-Api-Tracker

package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type EndpointData struct {
	Version string                 `json:"version"`
	Data    map[string]interface{} `json:"data"`
}

func formatJSON(data interface{}) (string, error) {
	jsonData, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return "", fmt.Errorf("failed to format JSON: %w", err)
	}
	return string(jsonData), nil
}

func scrapeEndpoint(url string) (*http.Response, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to scrape endpoint %s: %w", url, err)
	}
	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return nil, fmt.Errorf("status code %d for URL %s", resp.StatusCode, url)
	}
	return resp, nil
}

func fetchAndSaveVersionData(url, version, folder string) (map[string]interface{}, error) {
	response, err := scrapeEndpoint(fmt.Sprintf("https://%s/docs/json/%s", url, version))
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()

	var jsonData interface{}
	if err := json.NewDecoder(response.Body).Decode(&jsonData); err != nil {
		return nil, fmt.Errorf("failed to decode JSON from URL %s: %w", response.Request.URL, err)
	}

	if jsonDataMap, ok := jsonData.(map[string]interface{}); ok && jsonDataMap["errors"] != nil {
		return nil, nil
	}

	formatted, err := formatJSON(jsonData)
	if err != nil {
		return nil, err
	}

	if err := saveToFile(folder, version, formatted); err != nil {
		return nil, err
	}

	return jsonData.(map[string]interface{}), nil
}

func saveToFile(folder, version, content string) error {
	if err := os.MkdirAll(folder, os.ModePerm); err != nil {
		return fmt.Errorf("failed to create directory %s: %w", folder, err)
	}
	filePath := filepath.Join(folder, fmt.Sprintf("%s.json", version))
	if err := os.WriteFile(filePath, []byte(content), 0644); err != nil {
		return fmt.Errorf("failed to write file %s: %w", filePath, err)
	}
	return nil
}

func handleEndpoint(url string, folder string) (map[string]interface{}, error) {
	out := make(map[string]interface{})
	for i := 1; i < 5; i++ {
		version := fmt.Sprintf("v%d", i)
		data, err := fetchAndSaveVersionData(url, version, folder)
		if err != nil {
			if err != nil {
				fmt.Println("Warning:", err)
			}
			continue
		}
		if data != nil {
			out[version] = data
		}
	}
	return out, nil
}

func loadEndpoints(filename string) ([]string, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("failed to read file %s: %w", filename, err)
	}

	var endpoints []string
	if err := json.Unmarshal(data, &endpoints); err != nil {
		return nil, fmt.Errorf("failed to unmarshal JSON: %w", err)
	}

	return endpoints, nil
}

func processEndpoints() error {
	endpoints, err := loadEndpoints("endpoints.json")
	if err != nil {
		return err
	}

	api := make(map[string]map[string]interface{})
	for _, url := range endpoints {
		folder := fmt.Sprintf("out/%s", strings.Split(url, ".")[0])
		data, err := handleEndpoint(url, folder)
		if err != nil {
			fmt.Println("Error:", err)
			continue
		}
		api[folder] = data
	}

	sortedApi, err := sortAPI(api)
	if err != nil {
		return err
	}

	formatted, err := formatJSON(sortedApi)
	if err != nil {
		return err
	}

	if err := os.WriteFile("api.json", []byte(formatted), 0644); err != nil {
		return fmt.Errorf("failed to write API file: %w", err)
	}

	return nil
}

func sortAPI(api map[string]map[string]interface{}) (map[string]interface{}, error) {
	keys := make([]string, 0, len(api))
	for k := range api {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	sortedApi := make(map[string]interface{})
	for _, k := range keys {
		sortedApi[k] = api[k]
	}

	return sortedApi, nil
}

func main() {
	if err := processEndpoints(); err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}
}

