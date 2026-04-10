package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/nostr0mo9/trinity-windows/internal/config"
	"github.com/nostr0mo9/trinity-windows/internal/ui"
	"golang.org/x/sys/windows/svc/mgr"
)

const srvName = "TrinityDaemon"

func isElevated() bool {
	// A simple check is to open the local machine SCM with full access
	m, err := mgr.Connect()
	if err != nil {
		return false
	}
	m.Disconnect()
	return true
}

func getExePath() string {
	exe, _ := os.Executable()
	dir := filepath.Dir(exe)
	// We assume trinity-daemon.exe is in the same directory as trinity.exe
	// If during MVP they build to bin/, we're good.
	daemon := filepath.Join(dir, "trinity-daemon.exe")
	if _, err := os.Stat(daemon); os.IsNotExist(err) {
		// Fallback to checking for it
        return "trinity-daemon.exe" // Needs to be absolute for SCM typically
	}
	return daemon
}

func runStart() {
	if !isElevated() {
		ui.PrintCyberPanel("INSUFFICIENT PRIVILEGES", false, config.LoadConfig().BlockedDomains != nil, nil, nil, []ui.CustomLine{
			{"Error: `trinity start` must be run as Administrator.", "\u001b[31m"},
		})
		os.Exit(1)
	}

	m, err := mgr.Connect()
	if err != nil {
		fmt.Printf("SCM connection failed: %v\n", err)
		return
	}
	defer m.Disconnect()

	daemonPath := getExePath()
    if !strings.Contains(daemonPath, "\\") {
        ui.PrintCyberPanel("BINARY NOT FOUND", false, false, nil, nil, []ui.CustomLine{
			{"Cannot locate trinity-daemon.exe near CLI.", "\u001b[31m"},
		})
		os.Exit(1)
    }

	s, err := m.OpenService(srvName)
	if err != nil {
		// Needs to be created
		s, err = m.CreateService(srvName, daemonPath, mgr.Config{
			StartType: mgr.StartAutomatic,
            DisplayName: "Trinity Background Daemon",
            Description: "Enforces network productivity protocols.",
		})
		if err != nil {
			ui.PrintCyberPanel("SYSTEM BOOT FAILED", false, false, nil, nil, []ui.CustomLine{
				{"Failed to create daemon service.", "\u001b[31m"},
			})
			return
		}
	}
	defer s.Close()

	err = s.Start("is", "manual-started")
	if err != nil {
		ui.PrintCyberPanel("SYSTEM BOOT FAILED", false, false, nil, nil, []ui.CustomLine{
			{"Failed to start daemon. Already running?", "\u001b[31m"},
		})
		return
	}

	ui.PrintCyberPanel("SYSTEM BOOT", true, config.LoadConfig().BlockedDomains != nil, nil, nil, []ui.CustomLine{
		{"Daemon boot sequence successful.", "\u001b[32m"},
		{"Trinity is now active in the background.", "\u001b[32m"},
	})
}

func runStop() {
	if !isElevated() {
		ui.PrintCyberPanel("INSUFFICIENT PRIVILEGES", true, false, nil, nil, []ui.CustomLine{ // Just defaults for visual consistency
			{"Error: `trinity stop` must be run as Administrator.", "\u001b[31m"},
		})
		os.Exit(1)
	}

	locked, _ := config.GetLockInfo()
	if locked {
        // Technically I am passing `true` for daemon state below to be consistent
		ui.PrintCyberPanel("ACCESS DENIED", true, true, nil, nil, []ui.CustomLine{
			{"Error: System is LOCKED.", "\u001b[31m"},
			{"You cannot stop the daemon right now.", "\u001b[31m"},
			{"Run `trinity unlock` to gain temporary access.", "\u001b[90m"},
		})
		os.Exit(1)
	}

	m, err := mgr.Connect()
	if err != nil {
		return
	}
	defer m.Disconnect()

	s, err := m.OpenService(srvName)
	if err != nil {
		ui.PrintCyberPanel("TEARDOWN FAILED", false, false, nil, nil, []ui.CustomLine{
			{"Failed to stop daemon. Service doesn't exist?", "\u001b[31m"},
		})
		return
	}
	defer s.Close()

    // Control service to stop
    // we could use s.Control(svc.Stop)
    _ = exec.Command("sc", "stop", srvName).Run()
    
    // Once stopped, we can delete the service
	err = s.Delete()
	if err != nil {
		ui.PrintCyberPanel("TEARDOWN FAILED", false, false, nil, nil, []ui.CustomLine{
			{"Failed to scrub daemon from registry.", "\u001b[31m"},
		})
		return
	}

	ui.PrintCyberPanel("SYSTEM TEARDOWN", false, false, nil, nil, []ui.CustomLine{
		{"Trinity background daemon safely stopped and removed.", "\u001b[32m"},
	})
}
