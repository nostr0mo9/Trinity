package ipc

import (
	"bufio"
	"net"
	"strings"

	"github.com/Microsoft/go-winio"
)

const PipePath = `\\.\pipe\TrinityControlPipe`

// SendCommandToDaemon connects to the Named Pipe and transmits the action and payload.
func SendCommandToDaemon(action, payload string) (string, error) {
	conn, err := winio.DialPipe(PipePath, nil)
	if err != nil {
		return "", err
	}
	defer conn.Close()

	msg := action + "|" + payload + "\n"
	_, err = conn.Write([]byte(msg))
	if err != nil {
		return "", err
	}

	reader := bufio.NewReader(conn)
	resp, err := reader.ReadString('\n')
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(resp), nil
}

// ListenForCommands opens the Named Pipe server and passes decoded payloads to the handler.
func ListenForCommands(handler func(action, payload string) string) error {
    // Sddl definition ensures only administrative users / specific groups can open it if we want.
    // For MVP, we will use a loose SDDL or let the default pipe security inherit.
    // We can restrict it to Administrators and SYSTEM using SDDL: "D:P(A;;GA;;;BA)(A;;GA;;;SY)"
	pipeConfig := &winio.PipeConfig{
		SecurityDescriptor: "D:P(A;;GA;;;BA)(A;;GA;;;SY)(A;;GRGW;;;WD)", // Built-in Admins(BA), SYSTEM(SY), Everyone(WD) 
        // For production, WD (Everyone) shouldn't be GA (Generic All) or Write, but since the CLI needs to send UNLOCK from user space without UAC...
        // Wait, the user space CLI needs to communicate with the daemon! So WD must have Read/Write (GRGW)
	}

	listener, err := winio.ListenPipe(PipePath, pipeConfig)
	if err != nil {
		return err
	}
	defer listener.Close()

	for {
		conn, err := listener.Accept()
		if err != nil {
			// In a real service, check for termination context
			continue
		}
		go handleConnection(conn, handler)
	}
}

func handleConnection(conn net.Conn, handler func(action, payload string) string) {
	defer conn.Close()
	reader := bufio.NewReader(conn)
	msg, err := reader.ReadString('\n')
	if err != nil {
		return
	}
	msg = strings.TrimSpace(msg)
	parts := strings.SplitN(msg, "|", 2)
	action := parts[0]
	payload := ""
	if len(parts) > 1 {
		payload = parts[1]
	}

	resp := handler(action, payload)
	conn.Write([]byte(resp + "\n"))
}
