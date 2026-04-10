package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/nostr0mo9/trinity-windows/internal/config"
	"github.com/nostr0mo9/trinity-windows/internal/hosts"
	"github.com/nostr0mo9/trinity-windows/internal/ui"
)

func runDelete() {
	if !isElevated() {
		ui.PrintCyberPanel("INSUFFICIENT PRIVILEGES", false, false, nil, nil, []ui.CustomLine{
			{"Error: Administrator privileges required.", "\u001b[31m"},
			{"Cannot trigger uninstallation.", "\u001b[90m"},
		})
		os.Exit(1)
	}

	locked, _ := config.GetLockInfo()
	if locked {
		ui.PrintCyberPanel("UNINSTALL DENIED", true, true, nil, nil, []ui.CustomLine{
			{"Trinity is actively enforcing policies.", "\u001b[31m"},
			{"Run `trinity unlock` to lift restrictions", "\u001b[31m"},
			{"before attempting removal.", "\u001b[90m"},
		})
		os.Exit(1)
	}

	ui.PrintCyberPanel("VERIFY UNINSTALLATION", false, false, nil, nil, []ui.CustomLine{
		{"This will permanently uninstall Trinity.", "\u001b[31m"},
		{"All configuration and history will be lost.", "\u001b[90m"},
	})

	fmt.Print("Are you sure you want to proceed? [y/N]: ")
	reader := bufio.NewReader(os.Stdin)
	response, _ := reader.ReadString('\n')
	response = strings.ToLower(strings.TrimSpace(response))

	if response != "y" && response != "yes" {
		fmt.Println("\nUninstall sequence aborted.")
		os.Exit(0)
	}

	fmt.Println("\n[SYSTEM LOG] Executing Trinity Native Removal Protocol...")

	// 1. Remove Service & Network
	fmt.Print("[*] Halting Windows Daemon and scrubbing registry...")
	err := stopServiceSafely()
	if err != nil {
		fmt.Println(" FAILED!")
		fmt.Printf("    -> %v\n", err)
	} else {
		fmt.Println(" SUCCESS")
	}

	// Double check the network logic locally just in case daemon was already offline
	fmt.Print("[*] Reversing system hosts configurations natively...")
	err = hosts.CleanupNetworkEnforcement()
	if err != nil {
		fmt.Println(" FAILED!")
		fmt.Printf("    -> %v\n", err)
	} else {
		fmt.Println(" SUCCESS")
	}

	// 2. Erase Artifacts
	fmt.Print("[*] Erasing encrypted configuration caches...")
	err = os.RemoveAll(config.AppSupportDir)
	if err != nil {
		fmt.Println(" ERROR (may be missing or locked)")
	} else {
		fmt.Println(" SUCCESS")
	}

	// 3. Resolve Self-Destruct
	fmt.Print("[*] Establishing ephemeral binary self-destruct mechanism...")
	
	cliPath, _ := os.Executable()
	cliPath, _ = filepath.Abs(cliPath)
	dir := filepath.Dir(cliPath)
	daemonPath := filepath.Join(dir, "trinity-daemon.exe")

    // Construct deletion script tightly targeting only the binaries explicitly
	delScript := fmt.Sprintf(`ping 127.0.0.1 -n 3 > nul & del /Q /F "%s" "%s"`, cliPath, daemonPath)
	
	cmd := exec.Command("cmd.exe", "/C", delScript)
	err = cmd.Start()
	
	if err != nil {
		fmt.Println(" FAILED!")
		fmt.Println("[!] You must manually delete the binaries.")
		os.Exit(1)
	} else {
		fmt.Println(" SUCCESS")
		fmt.Println("\n[SYSTEM SECURE] Trinity has been completely purged.")
		fmt.Println("Shutting down core link...")
		os.Exit(0) // Safe termination dropping the execution lock entirely
	}
}
