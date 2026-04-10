package main

import (
	"os"
	"strings"
	"time"

	"github.com/nostr0mo9/trinity-windows/internal/config"
	"github.com/nostr0mo9/trinity-windows/internal/ipc"
	"github.com/nostr0mo9/trinity-windows/internal/ui"
)

const version = "v1.0.0-windows-mvp"

func runBlock(domain string) {
	clean := strings.ToLower(strings.TrimSpace(domain))
	if clean == "" {
		return
	}
	conf := config.LoadConfig()
	alreadyExists := false
	for _, d := range conf.BlockedDomains {
		if d == clean {
			alreadyExists = true
			break
		}
	}

	if !alreadyExists {
		conf.BlockedDomains = append(conf.BlockedDomains, clean)
		config.SaveConfig(conf)
		_, _ = ipc.SendCommandToDaemon("SYNC", "") // Tell daemon to re-read and enforce immediately
		ui.PrintCyberPanel("TARGET ACQUIRED", getDaemonRunning(), getLockState(), nil, nil, []ui.CustomLine{
			{"Successfully restricted routing for:", "\u001b[0m"},
			{"  -> " + clean, "\u001b[32m"},
		})
	} else {
		ui.PrintCyberPanel("TARGET ACQUIRED", getDaemonRunning(), getLockState(), nil, nil, []ui.CustomLine{
			{clean + " is already restricted.", "\u001b[90m"},
		})
	}
}

func runUnblock(domain string) {
	locked, _ := config.GetLockInfo()
	if locked {
		ui.PrintCyberPanel("ACCESS DENIED", getDaemonRunning(), true, nil, nil, []ui.CustomLine{
			{"System is LOCKED.", "\u001b[31m"},
			{"You cannot remove domains.", "\u001b[31m"},
			{"Run `trinity unlock` to gain access.", "\u001b[90m"},
		})
		os.Exit(1)
	}

	clean := strings.ToLower(strings.TrimSpace(domain))
	conf := config.LoadConfig()
	newDomains := []string{}
	found := false
	for _, d := range conf.BlockedDomains {
		if d == clean {
			found = true
		} else {
			newDomains = append(newDomains, d)
		}
	}

	if found {
		conf.BlockedDomains = newDomains
		config.SaveConfig(conf)
		_, _ = ipc.SendCommandToDaemon("SYNC", "")
		ui.PrintCyberPanel("TARGET RELEASED", getDaemonRunning(), false, nil, nil, []ui.CustomLine{
			{"Successfully lifted restriction for:", "\u001b[0m"},
			{"  -> " + clean, "\u001b[32m"},
		})
	} else {
		ui.PrintCyberPanel("TARGET NOT FOUND", getDaemonRunning(), false, nil, nil, []ui.CustomLine{
			{clean + " is not in the blocklist.", "\u001b[90m"},
		})
	}
}

func runList() {
	conf := config.LoadConfig()
	locked, unlockDate := config.GetLockInfo()
	ui.PrintCyberPanel("B L O C K L I S T", getDaemonRunning(), locked, conf.BlockedDomains, unlockDate, nil)
}

func printStatus() {
	conf := config.LoadConfig()
	locked, unlockDate := config.GetLockInfo()
	ui.PrintCyberPanel("", getDaemonRunning(), locked, conf.BlockedDomains, unlockDate, nil)
}

func getLockState() bool {
	locked, _ := config.GetLockInfo()
	return locked
}

func getDaemonRunning() bool {
	resp, err := ipc.SendCommandToDaemon("PING", "")
	return err == nil && resp == "PONG"
}

func startChallenge() {
	if ui.StartChallenge() {
		// Challenge passed!
		ui.PrintCyberPanel("PROTOCOL COMPLETE", getDaemonRunning(), true, nil, nil, []ui.CustomLine{
			{"Challenge Sequence 100/100 verified.", "\u001b[32m"},
			{"Applying override mechanism...", "\u001b[90m"},
		})
		runApplyUnlock()
	}
}

func runApplyUnlock() {
	expire := time.Now().Add(30 * time.Minute)
	state := config.TrinityState{
		UnlockedUntil: &expire,
	}
	config.SaveState(state)
	_, _ = ipc.SendCommandToDaemon("SYNC", "") // trigger enforcement relaxation
	ui.PrintCyberPanel("OVERRIDE ACCEPTED", getDaemonRunning(), false, nil, &expire, []ui.CustomLine{
		{"The routing restrictions are temporarily severed.", "\u001b[32m"},
		{"Thirty-minute grace period active. Use it wisely.", "\u001b[90m"},
	})
}

func main() {
	config.EnsureDirs()
	_ = ui.EnableVirtualTerminalProcessing()

	args := os.Args
	if len(args) > 1 {
		switch args[1] {
		case "block":
			if len(args) > 2 {
				runBlock(args[2])
			} else {
				ui.PrintHelp()
			}
		case "unblock":
			if len(args) > 2 {
				runUnblock(args[2])
			} else {
				ui.PrintHelp()
			}
		case "list":
			runList()
		case "start":
			runStart()
		case "stop":
			runStop()
		case "status":
			printStatus()
		case "unlock":
			if getLockState() {
				startChallenge()
			} else {
				ui.PrintCyberPanel("NO ACTION REQUIRED", getDaemonRunning(), false, nil, nil, []ui.CustomLine{
					{"System is already unlocked. No math required!", "\u001b[32m"},
				})
			}
		case "version":
			ui.PrintCyberPanel("V E R S I O N", getDaemonRunning(), getLockState(), nil, nil, []ui.CustomLine{
				{"Trinity CLI Layer", "\u001b[32m"},
				{"Windows Version: " + version, "\u001b[90m"},
			})
		case "help":
			ui.PrintHelp()
		default:
			ui.PrintHelp()
		}
	} else {
		ui.PrintHelp()
	}
}
