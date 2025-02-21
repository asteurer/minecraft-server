package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"
)

type CloudflareEnv struct {
	APIKey      string
	DNSName     string
	DNSRecordID string
	ZoneID      string
}

type RcloneEnv struct {
	BackblazeKey        string
	BackblazeKeyID      string
	BackblazeBucketName string
	VolumeMountPath     string // Where the minecraft data is mounted to the container
}

func main() {
	// Make sure the environment variables are present
	cfEnv, bbEnv, err := parseEnvVars()
	if err != nil {
		log.Fatal(err)
	}

	for {
		// These need to be retried if they fail, and will exit(1)
		// if they fail more than the retry amount
		exponentialBackoff(updatePublicIP, cfEnv, 5)
		log.Println("successfully updated public IP")

		exponentialBackoff(backUpData, bbEnv, 5)
		log.Println("successfully backed up data")

		// Run every 24 hours
		time.Sleep(time.Duration(24) * time.Hour)
	}
}

func parseEnvVars() (CloudflareEnv, RcloneEnv, error) {
	var cfEnv CloudflareEnv
	var rcEnv RcloneEnv

	// Create a list of missing environment variables, if any
	var missingEnvVars []string
	parse := func(s string) string {
		value, ok := os.LookupEnv(s)
		if !ok || value == "" {
			missingEnvVars = append(missingEnvVars, s)
		}

		return value
	}

	cfEnv.APIKey = parse("CLOUDFLARE_API_KEY")
	cfEnv.DNSName = parse("CLOUDFLARE_DNS_NAME")
	cfEnv.DNSRecordID = parse("CLOUDFLARE_DNS_RECORD_ID")
	cfEnv.ZoneID = parse("CLOUDFLARE_ZONE_ID")
	rcEnv.BackblazeKeyID = parse("BACKBLAZE_KEY_ID")
	rcEnv.BackblazeKey = parse("BACKBLAZE_KEY")
	rcEnv.BackblazeBucketName = parse("BACKBLAZE_BUCKET_NAME")
	rcEnv.VolumeMountPath = parse("VOLUME_MOUNT_PATH")

	if len(missingEnvVars) > 0 {
		return CloudflareEnv{},
			RcloneEnv{},
			fmt.Errorf("missing the following environment variables:\n%s", strings.Join(missingEnvVars, "\n"))
	}

	return cfEnv, rcEnv, nil
}

// See https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
func exponentialBackoff[T any](fn func(T) error, args T, retries int) {
	if err := fn(args); err == nil {
		return
	} else {
		log.Printf("function failed: %v\nproceeding to exponential backoff...", err)
		for i := 1; i <= retries; i++ {
			waitInMilliseconds := math.Pow(2, float64(i)) * 1000
			time.Sleep(time.Duration(waitInMilliseconds) * time.Millisecond)
			if err := fn(args); err == nil {
				return
			} else {
				log.Printf("function failed: %v\ncompleted iteration %d", err, i)
			}
		}

		os.Exit(1)
	}
}

// updatePublicIP performs dynamic DNS, updating cloudflare with the current public IP of the server
func updatePublicIP(vars CloudflareEnv) error {
	// Retrieve public IP address
	ipResp, err := http.Get("https://checkip.amazonaws.com")
	if err != nil {
		return fmt.Errorf("unable to query 'checkip.amazonaws.com': %v", err)
	}

	ipRespBytes, err := io.ReadAll(ipResp.Body)
	if err != nil {
		return fmt.Errorf("unable to read ipResp: %v", err)
	}
	defer ipResp.Body.Close()

	publicIP := string(ipRespBytes)

	// Assemble the Cloudflare URL
	// Docs: https://developers.cloudflare.com/api/resources/dns/subresources/records/methods/update/
	cfURL := fmt.Sprintf("https://api.cloudflare.com/client/v4/zones/%s/dns_records/%s", vars.ZoneID, vars.DNSRecordID)
	jsonData := map[string]any{
		"comment": "Update DNS record",
		"content": publicIP,
		"name":    vars.DNSName,
		"type":    "A",
		"proxied": false, // The Minecraft server won't work if it's proxied. Cloudflare doesn't seem to like UDP.
	}

	jsonBinary, err := json.Marshal(jsonData)
	if err != nil {
		return fmt.Errorf("unable to marshal JSON: %v", err)
	}

	cfReq, err := http.NewRequest("PUT", cfURL, bytes.NewReader(jsonBinary))
	if err != nil {
		return fmt.Errorf("unable to create http request artifact: %v", err)
	}

	cfReq.Header.Add("Authorization", "Bearer "+vars.APIKey)
	cfReq.Header.Add("Content-Type", "application/json")

	cfRes, err := http.DefaultClient.Do(cfReq)
	if err != nil {
		return fmt.Errorf("unable to query URL %q: %v", cfURL, err)
	}

	cfResBody, err := io.ReadAll(cfRes.Body)
	if err != nil {
		return fmt.Errorf("unable to read Cloudflare API response body: %v", err)
	}

	if cfRes.StatusCode != http.StatusOK {
		return fmt.Errorf("DNS record update failed.\nSTATUS: %d\nMESSAGE: %s", cfRes.StatusCode, string(cfResBody))
	}

	return nil
}

// backUpData performs backups of the minecraft data to Backblaze via rclone
func backUpData(vars RcloneEnv) error {
	// Docs: https://rclone.org/b2

	configPath := "/root/.config/rclone"
	if err := os.MkdirAll(configPath, 0700); err != nil {
		return fmt.Errorf("failed to create dir %q", configPath)
	}

	// The rclone.config below file was created by running 'rclone config', going through
	// the interactive prompts, and templating the sensitive information
	configFileContents := []byte(fmt.Sprintf("[mc-remote]\ntype = b2\naccount = %s\nkey = %s\n\n", vars.BackblazeKeyID, vars.BackblazeKey))
	if err := os.WriteFile(configPath+"/rclone.conf", configFileContents, 0400); err != nil {
		return fmt.Errorf("failed to write rclone.conf: %v", err)
	}

	mkDirOut, err := exec.Command("rclone", "mkdir", "mc-remote:"+vars.BackblazeBucketName).CombinedOutput()
	if err != nil {
		return fmt.Errorf("unable to execute 'rclone mkdir':\n%s", string(mkDirOut))
	}

	// This uses the ***exact*** volume mount path
	syncOut, err := exec.Command("rclone", "sync", vars.VolumeMountPath, "mc-remote:"+vars.BackblazeBucketName).CombinedOutput()
	if err != nil {
		return fmt.Errorf("unable to execute 'rclone sync':\n%s", string(syncOut))
	}

	return nil
}
