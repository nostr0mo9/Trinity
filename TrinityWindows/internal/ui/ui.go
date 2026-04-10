package ui

import (
	"bufio"
	"fmt"
	"math/rand"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"time"

	"golang.org/x/sys/windows"
)

const (
	themeColor = "\u001B[36m"
	red        = "\u001B[31m"
	green      = "\u001B[32m"
	dim        = "\u001B[90m"
	reset      = "\u001B[0m"
	bold       = "\u001B[1m"
)

type CustomLine struct {
	Text  string
	Color string
}

// EnableVirtualTerminalProcessing enables ANSI escape code parsing in Windows terminals natively
func EnableVirtualTerminalProcessing() error {
	handle, err := windows.GetStdHandle(windows.STD_OUTPUT_HANDLE)
	if err != nil {
		return err
	}

	var mode uint32
	err = windows.GetConsoleMode(handle, &mode)
	if err != nil {
		return err
	}

	mode |= windows.ENABLE_VIRTUAL_TERMINAL_PROCESSING
	return windows.SetConsoleMode(handle, mode)
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func centerPad(t string, w int) string {
	pad := max(0, w-len(t))
	return strings.Repeat(" ", pad/2) + t + strings.Repeat(" ", pad-pad/2)
}

func rightPad(t string, w int) string {
	pad := max(0, w-len(t))
	return t + strings.Repeat(" ", pad)
}

func PrintCyberPanel(headerTitle string, isDaemonActive bool, isLocked bool, domains []string, unlockDate *time.Time, customLines []CustomLine) {
	titleStr := headerTitle
	if titleStr == "" {
		if isDaemonActive {
			titleStr = "DAEMON: ACTIVE"
		} else {
			titleStr = "DAEMON: OFFLINE"
		}
	}
	title := "T R I N I T Y : : " + titleStr

	statusText := "STATUS: STANDBY :: FILTER OFFLINE"
	if isLocked {
		statusText = "STATUS: ENFORCED :: DISTRACTION FILTER ACTIVE"
	}

	fmt.Println()
	fmt.Printf("%s0101010101010101010101010101010101010101010101010101010101010101%s\n", themeColor, reset)
	fmt.Printf("%s0%s%s%s%s%s0%s\n", themeColor, reset, bold, centerPad(title, 62), reset, themeColor, reset)
	fmt.Printf("%s01%s %s%s10%s\n", themeColor, reset, centerPad(statusText, 60), themeColor, reset)
	fmt.Printf("%s010%s%s%s%s%s010%s\n", themeColor, reset, themeColor, strings.Repeat("-", 58), reset, themeColor, reset)

	fullBinLeft := "0101010101010101"
	fullBinRight := "1010101010101010"

	if len(customLines) > 0 {
		for index, line := range customLines {
			leftLen := 4 + (index % 5)
			rightLen := 4 + (index % 5)

			lBin := fullBinLeft[:leftLen]
			rBin := fullBinRight[:rightLen]
			lPad := strings.Repeat(" ", 9-leftLen)

			inner := 47
			cleanLen := len(line.Text)
			padCount := max(0, inner-cleanLen)
			totalPad := strings.Repeat(" ", padCount)

			fmt.Printf("%s%s%s%s%s%s%s%s%s%s%s\n", themeColor, lBin, reset, lPad, line.Color, line.Text, reset, totalPad, themeColor, rBin, reset)
		}
	} else {
		if len(domains) == 0 {
			fmt.Printf("%s0101%s   %s   %s1010%s\n", themeColor, reset, centerPad("NO DOMAINS BLOCKED", 54), themeColor, reset)
		} else {
			for index, domain := range domains {
				leftLen := 4 + (index % 5)
				rightLen := 4 + (index % 5)

				lBin := fullBinLeft[:leftLen]
				rBin := fullBinRight[:rightLen]
				lPad := strings.Repeat(" ", 9-leftLen)
				rPad := strings.Repeat(" ", 9-rightLen)

				cleanDomain := "[X] " + domain
				stateSuffix := "UNLOCKED"
				stateColor := green
				if isLocked {
					stateSuffix = "BLOCKED"
					stateColor = red
				}

				inner := 46
				colonsCount := max(1, inner-len(cleanDomain)-len(stateSuffix)-1)
				colons := strings.Repeat(":", colonsCount)

				fmt.Printf("%s%s%s%s%s %s%s%s %s%s%s%s%s%s%s\n", themeColor, lBin, reset, lPad, cleanDomain, dim, colons, reset, stateColor, stateSuffix, reset, rPad, themeColor, rBin, reset)
			}
		}
	}

	fmt.Printf("%s0101%s%s%s%s%s1010%s\n", themeColor, reset, themeColor, strings.Repeat("-", 56), reset, themeColor, reset)

	accessText := "ACCESS: GRANTED :: OVERRIDE: ENABLED"
	if isLocked {
		accessText = "ACCESS: DENIED :: OVERRIDE: DISABLED"
	}
	userStateText := "USER STATE: LOCKED :: SOLVE REQUIRED"
	if !isLocked {
		if unlockDate != nil {
			userStateText = "USER STATE: UNLOCKED :: EXPIRES " + unlockDate.Format("15:04")
		} else {
			userStateText = "USER STATE: UNLOCKED"
		}
	}
	footerTitle := "T R I N I T Y   I S   W A T C H I N G"

	accessColor := green
	if isLocked {
		accessColor = red
	}

	userStateColor := green
	if isLocked {
		userStateColor = red
	}

	fmt.Printf("%s010%s   %s%s%s%s010%s\n", themeColor, reset, accessColor, rightPad(accessText, 56), reset, themeColor, reset)
	fmt.Printf("%s01%s    %s%s%s%s10%s\n", themeColor, reset, userStateColor, rightPad(userStateText, 57), reset, themeColor, reset)
	fmt.Printf("%s0%s%s%s%s%s%s0%s\n", themeColor, reset, bold, dim, centerPad(footerTitle, 62), reset, themeColor, reset)
	fmt.Printf("%s0101010101010101010101010101010101010101010101010101010101010101%s\n\n", themeColor, reset)
}

func StartChallenge() bool {
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt)
	go func() {
		<-sigChan
		fmt.Printf("\n\n%s  ↳ Challenge aborted by user.%s\n\n", red, reset)
		os.Exit(1)
	}()
	defer signal.Stop(sigChan)

	fmt.Print("\033[2J\033[H")
	PrintCyberPanel("INITIATE PROTOCOL", true, true, nil, nil, []CustomLine{
		{"SUBJECT REQUESTED OVERRIDE.", red},
		{"You must complete 100 math sequences.", dim},
		{"Incorrect answers require a retry.", dim},
		{"Ctrl+C or type quit to abort.", dim},
	})

	totalProblems := 100
	completed := 0
	usedProblems := make(map[string]bool)

	rand.Seed(time.Now().UnixNano())
	scanner := bufio.NewScanner(os.Stdin)

	for completed < totalProblems {
		a := rand.Intn(90) + 10 // 10...99
		b := rand.Intn(90) + 10
		typ := rand.Intn(3) // 0...2
		var q string
		var ans int

		if typ == 0 {
			q = fmt.Sprintf("%d + %d", a, b)
			ans = a + b
		} else if typ == 1 {
			q = fmt.Sprintf("%d - %d", a+b, a)
			ans = b
		} else {
			a = rand.Intn(11) + 2 // 2...12
			b = rand.Intn(9) + 4  // 4...12
			q = fmt.Sprintf("%d × %d", a, b)
			ans = a * b
		}

		if usedProblems[q] {
			continue
		}
		usedProblems[q] = true

		solved := false
		for !solved {
			progress := fmt.Sprintf("%03d", completed+1)
			fmt.Printf("%s[%s/%d]%s %s%s = %s", themeColor, progress, totalProblems, reset, bold, q, reset)
			if !scanner.Scan() {
				time.Sleep(50 * time.Millisecond) // Allow SIGINT goroutine to print natively before nuclear exit
				os.Exit(1)
			}
			input := strings.TrimSpace(scanner.Text())
			if input == "" {
				continue
			}
			
			if strings.ToLower(input) == "quit" {
				fmt.Printf("\n%s  ↳ Challenge aborted by user.%s\n\n", red, reset)
				return false
			}

			pi, err := strconv.Atoi(input)
			if err == nil {
				if pi == ans {
					solved = true
					completed++
					if completed < totalProblems {
						fmt.Printf("%s  ↳ Correct%s\n", green, reset)
					}
				} else {
					fmt.Printf("%s  ↳ Incorrect. System rejects input.%s\n", red, reset)
				}
			} else {
				fmt.Printf("%s  ↳ Invalid input.%s\n", red, reset)
			}
		}
	}

	return true
}

func PrintHelp() {
	lines := []CustomLine{
		{"Usage Commands:", bold},
		{"  trinity block <domain>   - Restrict a remote website", reset},
		{"  trinity unblock <domain> - Remove restriction (if unlocked)", reset},
		{"  trinity list             - View current network policies", reset},
		{"  trinity status           - View daemon status & lock state", reset},
		{"  trinity unlock           - Subject yourself to the test", reset},
		{"  trinity version          - Display matrix version", reset},
		{"", reset},
		{"Administrative (Requires Admin):", bold},
		{"  trinity start            - Register and boot daemon", dim},
		{"  trinity stop             - Stop and un-register daemon", dim},
		{"  trinity delete           - Permanently uninstall system natively", dim},
	}
	PrintCyberPanel("M A N U A L", true, true, nil, nil, lines) // isLocked/isDaemonActive pass dummy true to keep visual style consistent for help
}
