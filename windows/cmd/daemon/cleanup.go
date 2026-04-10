package main

import (
	"bufio"
	"os"
	"os/exec"
	"strings"
)

func CleanupNetworkEnforcement() error {
	hostsPath := getHostsPath()
	content, err := os.ReadFile(hostsPath)
	if err != nil {
		return err
	}

	var newLines []string
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

	finalContent := strings.Join(newLines, "\r\n")
	err = os.WriteFile(hostsPath, []byte(finalContent), 0644)
	if err != nil {
		return err
	}

	cmd := exec.Command("ipconfig", "/flushdns")
	_ = cmd.Run()
	return nil
}
