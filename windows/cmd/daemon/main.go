package main

import (
	"log"
	"os"

	"github.com/nostr0mo9/trinity-windows/internal/config"
	"github.com/nostr0mo9/trinity-windows/internal/hosts"
	"github.com/nostr0mo9/trinity-windows/internal/ipc"
	"golang.org/x/sys/windows/svc"
)

type trinityService struct{}

func (m *trinityService) Execute(args []string, r <-chan svc.ChangeRequest, changes chan<- svc.Status) (ssec bool, errno uint32) {
	const cmdsAccepted = svc.AcceptStop | svc.AcceptShutdown
	changes <- svc.Status{State: svc.StartPending}
	changes <- svc.Status{State: svc.Running, Accepts: cmdsAccepted}

	// Always enforce baseline on boot
	UpdateNetworkEnforcement()

	// Start IPC Listener
	go func() {
		err := ipc.ListenForCommands(func(action, payload string) string {
			switch action {
			case "PING":
				return "PONG"
			case "SYNC":
				err := UpdateNetworkEnforcement()
				if err != nil {
					return "ERROR|" + err.Error()
				}
				return "OK"
			}
			return "UNKNOWN"
		})
		if err != nil {
			log.Fatal("IPC Listener failed:", err)
		}
	}()

loop:
	for {
		c := <-r
		switch c.Cmd {
		case svc.Interrogate:
			changes <- c.CurrentStatus
		case svc.Stop, svc.Shutdown:
			hosts.CleanupNetworkEnforcement()
			break loop
		}
	}

	changes <- svc.Status{State: svc.StopPending}
	return
}

func main() {
	config.EnsureDirs()

	isInteractive, err := svc.IsAnInteractiveSession()
	if err != nil {
		log.Fatalf("failed to determine interactive session: %v", err)
	}
	if isInteractive {
		UpdateNetworkEnforcement()
		ipc.ListenForCommands(func(action, payload string) string {
			if action == "SYNC" {
				UpdateNetworkEnforcement()
				return "OK"
			}
			return "UNKNOWN"
		})
		os.Exit(0)
	}

	err = svc.Run("TrinityDaemon", &trinityService{})
	if err != nil {
		log.Fatalf("service runtime failed: %v", err)
	}
}
