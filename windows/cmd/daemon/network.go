package main

import (
	"bufio"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/nostr0mo9/trinity-windows/internal/config"
)

const markerStart = "# --- TRINITY MANAGED BLOCK ---"
const markerEnd = "# --- TRINITY MANAGED END ---"

func getHostsPath() string {
	return filepath.Join(os.Getenv("SystemRoot"), "System32", "drivers", "etc", "hosts")
}

func UpdateNetworkEnforcement() error {
	conf := config.LoadConfig()
	locked, _ := config.GetLockInfo() // Returns true if locked, unlockedDate

	hostsPath := getHostsPath()

	// Read existing hosts without Trinity marks
	content, err := os.ReadFile(hostsPath)
	var newLines []string
	if err == nil {
		scanner := bufio.NewScanner(strings.NewReader(string(content)))
		inTrinityBlock := false
		for scanner.Scan() {
			line := scanner.Text()
			if strings.TrimSpace(line) == markerStart {
				inTrinityBlock = true
				continue
			}
			if strings.TrimSpace(line) == markerEnd {
				inTrinityBlock = false
				continue
			}
			if !inTrinityBlock {
				newLines = append(newLines, line)
			}
		}
	} else {
		newLines = append(newLines, "# Windows Hosts")
	}

	// Always append the Trinity block at the end if Locked and domains exist
	if locked && len(conf.BlockedDomains) > 0 {
		newLines = append(newLines, "")
		newLines = append(newLines, markerStart)
		for _, d := range conf.BlockedDomains {
			newLines = append(newLines, "0.0.0.0 "+d)
			newLines = append(newLines, "::1 "+d)
		}
		newLines = append(newLines, markerEnd)
	}

	finalContent := strings.Join(newLines, "\r\n")
	err = os.WriteFile(hostsPath, []byte(finalContent), 0644)
	if err != nil {
		return err
	}

	// Flush DNS to ensure immediate drop
	cmd := exec.Command("ipconfig", "/flushdns")
	_ = cmd.Run()

	return nil
}
