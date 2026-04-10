package config

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"
	"github.com/nostr0mo9/trinity-windows/internal/hosts"
)

var (
	AppSupportDir = filepath.Join(os.Getenv("PROGRAMDATA"), "Trinity")
	ConfigURL     = filepath.Join(AppSupportDir, "config.json")
	StateURL      = filepath.Join(AppSupportDir, "state.json")
)

type TrinityConfig struct {
	BlockedDomains []string `json:"blockedDomains"`
}

type TrinityState struct {
	UnlockedUntil   *time.Time `json:"unlockedUntil"`
	ConfigHash      *string    `json:"configHash"`
	EnforcedDomains []string   `json:"enforcedDomains"`
}

func (s *TrinityState) IsCurrentlyUnlocked() bool {
	if s.UnlockedUntil != nil {
		return time.Now().Before(*s.UnlockedUntil)
	}
	return false
}

func EnsureDirs() error {
	return os.MkdirAll(AppSupportDir, 0755)
}

func LoadConfig() TrinityConfig {
	data, err := os.ReadFile(ConfigURL)
	if err != nil {
		recovered := hosts.RecoverDomains()
		if len(recovered) > 0 {
			c := TrinityConfig{BlockedDomains: recovered}
			_ = SaveConfig(c) // Casually re-hydrate state onto disk
			return c
		}
		return TrinityConfig{BlockedDomains: []string{}}
	}
	var config TrinityConfig
	err = json.Unmarshal(data, &config)
	if err != nil {
		return TrinityConfig{BlockedDomains: []string{}}
	}
	return config
}

func SaveConfig(config TrinityConfig) error {
	EnsureDirs()
	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(ConfigURL, data, 0644)
}

func GetLockInfo() (bool, *time.Time) {
	data, err := os.ReadFile(StateURL)
	if err != nil {
		return true, nil
	}
	var state TrinityState
	if err := json.Unmarshal(data, &state); err == nil {
		if state.IsCurrentlyUnlocked() {
			return false, state.UnlockedUntil
		}
	}
	return true, nil // Locked by default
}

func SaveState(state TrinityState) error {
	EnsureDirs()
	data, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(StateURL, data, 0644)
}
