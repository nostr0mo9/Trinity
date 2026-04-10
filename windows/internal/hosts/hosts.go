package hosts

import (
	"bufio"
	"os"
	"path/filepath"
	"strings"
)

const (
	MarkerStart = "# --- TRINITY MANAGED BLOCK ---"
	MarkerEnd   = "# --- TRINITY MANAGED END ---"
)

func GetHostsPath() string {
	return filepath.Join(os.Getenv("SystemRoot"), "System32", "drivers", "etc", "hosts")
}

func RecoverDomains() []string {
	content, err := os.ReadFile(GetHostsPath())
	if err != nil {
		return nil
	}

	var domains []string
	domainSet := make(map[string]bool)

	scanner := bufio.NewScanner(strings.NewReader(string(content)))
	inTrinityBlock := false
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == MarkerStart {
			inTrinityBlock = true
			continue
		}
		if line == MarkerEnd {
			inTrinityBlock = false
			break
		}
		if inTrinityBlock {
			// Lines are formatted like "0.0.0.0 reddit.com" or "::1 reddit.com"
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				d := parts[1]
				if !domainSet[d] && d != "localhost" {
					domains = append(domains, d)
					domainSet[d] = true
				}
			}
		}
	}
	return domains
}
