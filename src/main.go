package main

import (
	"bytes"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gdamore/tcell/v2"
	"github.com/pelletier/go-toml/v2"
	"github.com/rivo/tview"
)

// --- CONFIG STRUCTS ---

type Bastion struct {
	Name      string `toml:"name"`
	ID        string `toml:"id"`
	SSHKey    string `toml:"ssh_key,omitempty"`     // Optionaler individueller SSH Private Key
	SSHPubKey string `toml:"ssh_pub_key,omitempty"` // Optionaler individueller SSH Public Key
}

type GeneralBastionSettings struct {
	SSHKey         string `toml:"ssh_key"`
	SSHPubKey      string `toml:"ssh_pub_key"`
	SessionTimeout int    `toml:"session_timeout,omitempty"`
	TunnelTimeout  int    `toml:"tunnel_timeout,omitempty"`
}

type TunnelConfig struct {
	Name       string `toml:"name"`
	BastionRef string `toml:"bastion_ref"`
	TargetIP   string `toml:"target_ip"`
	TargetPort int    `toml:"target_port"`
	LocalPort  int    `toml:"local_port"`
	Hint       string `toml:"hint,omitempty"`

	// Status-Tracker & Runtime Details
	Status    string    `toml:"-"` // "INACTIVE", "CREATING_SESSION", "ACTIVE", "FAILED"
	SessionID string    `toml:"-"`
	Cmd       *exec.Cmd `toml:"-"`
}

type AppConfig struct {
	BastionSettings GeneralBastionSettings `toml:"bastion_settings"`
	Bastions        map[string]Bastion     `toml:"bastions"`
	Tunnels         []TunnelConfig         `toml:"tunnels"`
}

const AppVersion = "v0.4.1"

var (
	app        *tview.Application
	pages      *tview.Pages
	config     AppConfig
	tunnelView *tview.TextView
	bastionBox *tview.TextView
	mainGrid   *tview.Grid
	configFile = "config.toml"
	isModified = false
)

func main() {
	if err := loadConfig(configFile); err != nil {
		fmt.Printf("Fehler beim Laden der %s: %v\n", configFile, err)
		os.Exit(1)
	}

	// Default Timeouts setzen falls nicht konfiguriert
	if config.BastionSettings.SessionTimeout == 0 {
		config.BastionSettings.SessionTimeout = 90
	}
	if config.BastionSettings.TunnelTimeout == 0 {
		config.BastionSettings.TunnelTimeout = 15
	}

	for i := range config.Tunnels {
		config.Tunnels[i].Status = "INACTIVE"
	}

	setupCustomTheme()

	app = tview.NewApplication()
	pages = tview.NewPages()

	mainGrid = buildMainView()
	pages.AddPage("main", mainGrid, true, true)

	// Globale Keybindings
	app.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		frontPage := getFrontPage()

		// Ctrl+C IMMER abfangen & kontrolliert aufräumen
		if event.Key() == tcell.KeyCtrlC {
			showConfirmModal("Beenden", "Möchtest du die Anwendung und alle aktiven Tunnel wirklich beenden?", func() {
				cleanupTunnels()
				app.Stop()
			})
			return nil
		}

		if frontPage == "main" {
			// Pfeiltasten auf der Hauptseite blockieren
			switch event.Key() {
			case tcell.KeyUp, tcell.KeyDown, tcell.KeyLeft, tcell.KeyRight, tcell.KeyPgUp, tcell.KeyPgDn:
				return nil
			}

			// Ctrl+A: Alle Tunnel aufbauen
			if event.Key() == tcell.KeyCtrlA {
				go connectAllTunnels()
				return nil
			}

			// Ctrl+E: In den Editor/Settings-Modus wechseln
			if event.Key() == tcell.KeyCtrlE {
				openSettingsMenu()
				return nil
			}

			// Q / q: Beenden (Robust gegen Fokus-Verlust)
			if event.Key() == tcell.KeyRune && (event.Rune() == 'q' || event.Rune() == 'Q') {
				focused := app.GetFocus()
				if focused != nil {
					if _, isInput := focused.(*tview.InputField); isInput {
						return event
					}
				}

				showConfirmModal("Beenden", "Möchtest du die Anwendung und alle aktiven Tunnel wirklich beenden?", func() {
					cleanupTunnels()
					app.Stop()
				})
				return nil
			}
		}

		return event
	})

	if err := app.SetRoot(pages, true).EnableMouse(true).Run(); err != nil {
		panic(err)
	}
}

// --- FARBSCHEMA & STYLING ---

func setupCustomTheme() {
	tview.Borders.Horizontal = '─'
	tview.Borders.Vertical = '│'
	tview.Borders.TopLeft = '┌'
	tview.Borders.TopRight = '┐'
	tview.Borders.BottomLeft = '└'
	tview.Borders.BottomRight = '┘'

	tview.Styles.PrimitiveBackgroundColor = tcell.ColorReset
	tview.Styles.ContrastBackgroundColor = tcell.Color236
	tview.Styles.MoreContrastBackgroundColor = tcell.Color238
	tview.Styles.BorderColor = tcell.ColorDarkGray
	tview.Styles.TitleColor = tcell.ColorYellow
	tview.Styles.GraphicsColor = tcell.ColorDarkGray
	tview.Styles.PrimaryTextColor = tcell.ColorWhite
	tview.Styles.SecondaryTextColor = tcell.ColorGray
	tview.Styles.TertiaryTextColor = tcell.ColorGreen
}

func loadConfig(filename string) error {
	data, err := os.ReadFile(filename)
	if err != nil {
		return err
	}
	return toml.Unmarshal(data, &config)
}

func maskID(id string) string {
	if len(id) <= 8 {
		return strings.Repeat("x", len(id))
	}
	return strings.Repeat("x", len(id)-6) + id[len(id)-6:]
}

// --- ED25519 & SSH HELPER ---

func expandHomeDir(path string) string {
	if strings.HasPrefix(path, "~/") {
		dirname, err := os.UserHomeDir()
		if err == nil {
			return filepath.Join(dirname, path[2:])
		}
	}
	return path
}

func isED25519Key(keyPath string) bool {
	expandedPath := expandHomeDir(keyPath)

	if strings.Contains(strings.ToLower(expandedPath), "ed25519") {
		return true
	}

	pubKeyPath := expandedPath + ".pub"
	if data, err := os.ReadFile(pubKeyPath); err == nil {
		if strings.HasPrefix(string(data), "ssh-ed25519") {
			return true
		}
	}

	if data, err := os.ReadFile(expandedPath); err == nil {
		content := string(data)
		if strings.Contains(content, "OPENSSH PRIVATE KEY") && strings.Contains(content, "ed25519") {
			return true
		}
	}

	return false
}

func buildSSHCommand(rawCmd string, sshKeyPath string, localPort int) string {
	expandedKey := expandHomeDir(sshKeyPath)

	cmd := strings.ReplaceAll(rawCmd, "<privateKey>", expandedKey)
	cmd = strings.ReplaceAll(cmd, "<localPort>", strconv.Itoa(localPort))

	extraOpts := []string{
		"-o ServerAliveInterval=10", // Alle 10s Ping senden
		"-o ServerAliveCountMax=3",  // Nach 3 verpassten Pings (30s) abbrechen
		"-o ExitOnForwardFailure=yes",
		"-o StrictHostKeyChecking=accept-new",
	}

	if isED25519Key(sshKeyPath) {
		extraOpts = append(extraOpts, "-o PubkeyAcceptedAlgorithms=+ssh-ed25519")
		extraOpts = append(extraOpts, "-o HostKeyAlgorithms=+ssh-ed25519")
	}

	return fmt.Sprintf("%s %s", cmd, strings.Join(extraOpts, " "))
}

// --- HAUPTANSICHT ---

func buildMainView() *tview.Grid {
	grid := tview.NewGrid().
		SetRows(6, 0, 1).
		SetColumns(0).
		SetBorders(false)

	// Panel 1: Bastionen
	bastionBox = tview.NewTextView().
		SetDynamicColors(true).
		SetScrollable(false)
	bastionBox.SetTitle(" Registrierte OCI Bastionen ").SetBorder(true)
	updateBastionDisplay()

	// Panel 2: Tunnel-Liste
	tunnelView = tview.NewTextView().
		SetDynamicColors(true).
		SetScrollable(false)
	tunnelView.SetTitle(" OCI Port-Forwarding Tunnel Status ").SetBorder(true)
	updateTunnelDisplay()

	// Statusleiste
	statusBar := tview.NewFlex().SetDirection(tview.FlexColumn)
	panelName := tview.NewTextView().SetTextColor(tcell.ColorYellow).SetText(" [OCI Tunnel Manager]")
	shortcuts := tview.NewTextView().SetTextAlign(tview.AlignCenter).SetText("[Ctrl+A] Verbinden  |  [Ctrl+E] Settings/Editor  |  [Q] Beenden")
	versionInfo := tview.NewTextView().SetTextAlign(tview.AlignRight).SetTextColor(tcell.ColorDarkGray).SetText(fmt.Sprintf("%s ", AppVersion))

	statusBar.AddItem(panelName, 22, 1, false)
	statusBar.AddItem(shortcuts, 0, 2, false)
	statusBar.AddItem(versionInfo, 10, 1, false)

	grid.AddItem(bastionBox, 0, 0, 1, 1, 0, 0, false)
	grid.AddItem(tunnelView, 1, 0, 1, 1, 0, 0, false)
	grid.AddItem(statusBar, 2, 0, 1, 1, 0, 0, false)

	return grid
}

func updateBastionDisplay() {
	if bastionBox == nil {
		return
	}
	var bastionText string
	for ref, b := range config.Bastions {
		keyInfo := b.SSHKey
		if keyInfo == "" {
			keyInfo = config.BastionSettings.SSHKey + " (Global)"
		}
		bastionText += fmt.Sprintf("[yellow][%s][white] %s\n  ├─ ID: [darkgray]%s[white]\n  └─ Key: [darkgray]%s[white]\n",
			ref, b.Name, maskID(b.ID), keyInfo)
	}
	bastionBox.SetText(bastionText)
}

func updateTunnelDisplay() {
	if tunnelView == nil {
		return
	}
	var text string
	for i, t := range config.Tunnels {
		var statusSymbol string
		switch t.Status {
		case "ACTIVE":
			statusSymbol = "[green]● ACTIVE[white]"
		case "CREATING_SESSION":
			statusSymbol = "[yellow]⏳ CREATING SESSION...[white]"
		case "WAITING_ACTIVE":
			statusSymbol = "[yellow]⏳ WAITING FOR OCI ACTIVE...[white]"
		case "OPENING_TUNNEL":
			statusSymbol = "[yellow]⏳ OPENING SSH TUNNEL...[white]"
		case "FAILED":
			statusSymbol = "[red]✖ FAILED[white]"
		default:
			statusSymbol = "[darkgray]○ INACTIVE[white]"
		}

		bastion, exists := config.Bastions[t.BastionRef]
		bastionInfo := fmt.Sprintf("[cyan]%s[white] (%s)", t.BastionRef, bastion.Name)
		if !exists {
			bastionInfo = fmt.Sprintf("[red]FEHLER: Bastion '%s' fehlt![white]", t.BastionRef)
		}

		hintText := ""
		if t.Hint != "" {
			hintText = fmt.Sprintf("\n  └─ [darkgray]Info: %s[reset]", t.Hint)
		}

		text += fmt.Sprintf("%s [bold]%d. %s[reset]\n"+
			"  ├─ Bastion: %s\n"+
			"  ├─ %s:%d ──> localhost:[bold]%d[reset]%s\n\n",
			statusSymbol, i+1, t.Name, bastionInfo, t.TargetIP, t.TargetPort, t.LocalPort, hintText)
	}

	tunnelView.SetText(text)
}

// --- LOGIK FÜR OCI CLI & SSH EXECUTION ---

func connectAllTunnels() {
	for i := range config.Tunnels {
		t := &config.Tunnels[i]

		bastion, exists := config.Bastions[t.BastionRef]
		if !exists {
			t.Status = "FAILED"
			refreshUI()
			continue
		}

		effectiveSSHKey := bastion.SSHKey
		if effectiveSSHKey == "" {
			effectiveSSHKey = config.BastionSettings.SSHKey
		}

		effectivePubKey := bastion.SSHPubKey
		if effectivePubKey == "" {
			if bastion.SSHKey != "" {
				effectivePubKey = bastion.SSHKey + ".pub"
			} else {
				effectivePubKey = config.BastionSettings.SSHPubKey
			}
		}

		t.Status = "CREATING_SESSION"
		refreshUI()

		pubKeyPath := expandHomeDir(effectivePubKey)
		cmdSession := exec.Command("oci", "bastion", "session", "create-port-forwarding",
			"--bastion-id", bastion.ID,
			"--display-name", t.Name,
			"--target-private-ip", t.TargetIP,
			"--target-port", strconv.Itoa(t.TargetPort),
			"--ssh-public-key-file", pubKeyPath,
			"--session-ttl", "10800", // Max 3 Stunden TTL
			"--query", "data.id",
			"--raw-output",
		)

		var outBuf, errBuf bytes.Buffer
		cmdSession.Stdout = &outBuf
		cmdSession.Stderr = &errBuf

		if err := cmdSession.Run(); err != nil {
			t.Status = "FAILED"
			refreshUI()
			continue
		}

		sessionID := strings.TrimSpace(outBuf.String())
		if sessionID == "" {
			t.Status = "FAILED"
			refreshUI()
			continue
		}
		t.SessionID = sessionID

		t.Status = "WAITING_ACTIVE"
		refreshUI()

		if !waitForSessionActive(sessionID) {
			t.Status = "FAILED"
			refreshUI()
			continue
		}

		t.Status = "OPENING_TUNNEL"
		refreshUI()

		rawSSHCmd := fetchSSHCommand(sessionID)
		if rawSSHCmd == "" {
			t.Status = "FAILED"
			refreshUI()
			continue
		}

		finalSSHCmd := buildSSHCommand(rawSSHCmd, effectiveSSHKey, t.LocalPort)

		if openSSHTunnel(t, finalSSHCmd) {
			t.Status = "ACTIVE"
		} else {
			t.Status = "FAILED"
		}
		refreshUI()
	}
}

func waitForSessionActive(sessionID string) bool {
	timeout := time.Duration(config.BastionSettings.SessionTimeout) * time.Second
	deadline := time.Now().Add(timeout)

	for time.Now().Before(deadline) {
		cmd := exec.Command("oci", "bastion", "session", "get",
			"--session-id", sessionID,
			"--query", "data.\"lifecycle-state\"",
			"--raw-output",
		)
		var outBuf bytes.Buffer
		cmd.Stdout = &outBuf

		if err := cmd.Run(); err == nil {
			state := strings.TrimSpace(outBuf.String())
			if state == "ACTIVE" {
				return true
			}
			if state == "DELETED" || state == "FAILED" {
				return false
			}
		}
		time.Sleep(2 * time.Second)
	}
	return false
}

func fetchSSHCommand(sessionID string) string {
	cmd := exec.Command("oci", "bastion", "session", "get",
		"--session-id", sessionID,
		"--query", "data.\"ssh-metadata\".command",
		"--raw-output",
	)
	var outBuf bytes.Buffer
	cmd.Stdout = &outBuf

	if err := cmd.Run(); err == nil {
		return strings.TrimSpace(outBuf.String())
	}
	return ""
}

func openSSHTunnel(t *TunnelConfig, fullCmd string) bool {
	sshCmd := exec.Command("bash", "-c", fullCmd)
	if err := sshCmd.Start(); err != nil {
		return false
	}
	t.Cmd = sshCmd

	timeout := time.Duration(config.BastionSettings.TunnelTimeout) * time.Second
	deadline := time.Now().Add(timeout)

	tunnelReady := false
	for time.Now().Before(deadline) {
		conn, err := net.DialTimeout("tcp", fmt.Sprintf("127.0.0.1:%d", t.LocalPort), 500*time.Millisecond)
		if err == nil {
			conn.Close()
			tunnelReady = true
			break
		}
		time.Sleep(1 * time.Second)
	}

	if !tunnelReady {
		if sshCmd.Process != nil {
			_ = sshCmd.Process.Kill()
		}
		return false
	}

	// Health-Monitoring starten, um Abbrüche im laufenden Betrieb zu erkennen
	go monitorTunnel(t)

	return true
}

func monitorTunnel(t *TunnelConfig) {
	for {
		time.Sleep(5 * time.Second)

		// Stoppen, wenn der Tunnel nicht mehr ACTIVE sein soll
		if t.Status != "ACTIVE" {
			return
		}

		// 1. Prüfen ob SSH-Prozess noch existiert
		if t.Cmd == nil || t.Cmd.Process == nil {
			t.Status = "FAILED"
			refreshUI()
			return
		}

		// 2. Port-Rechabarkeits-Check
		conn, err := net.DialTimeout("tcp", fmt.Sprintf("127.0.0.1:%d", t.LocalPort), 1*time.Second)
		if err != nil {
			t.Status = "FAILED"
			if t.Cmd.Process != nil {
				_ = t.Cmd.Process.Kill()
			}
			refreshUI()
			return
		}
		conn.Close()
	}
}

func cleanupTunnels() {
	for i := range config.Tunnels {
		t := &config.Tunnels[i]

		if t.Cmd != nil && t.Cmd.Process != nil {
			_ = t.Cmd.Process.Kill()
		}

		if t.SessionID != "" {
			_ = exec.Command("oci", "bastion", "session", "delete",
				"--session-id", t.SessionID,
				"--force",
			).Run()
		}
	}
}

func refreshUI() {
	app.QueueUpdateDraw(func() {
		updateTunnelDisplay()
	})
}

// --- DUAL-PANEL SETTINGS MENU ---

func openSettingsMenu() {
	mainFlex := tview.NewFlex().SetDirection(tview.FlexRow)
	mainFlex.SetBorder(true).SetTitle(" Einstellungen (Dual Panel) ").SetTitleAlign(tview.AlignLeft)

	panelsFlex := tview.NewFlex().SetDirection(tview.FlexColumn)

	bastionList := tview.NewList().ShowSecondaryText(true)
	bastionList.SetBorder(true).SetTitle(" 1. Bastionen [Tab] ")

	tunnelList := tview.NewList().ShowSecondaryText(true)
	tunnelList.SetBorder(true).SetTitle(" 2. Tunnel [Tab] ")

	var bastionRefs []string

	refreshBastions := func() {
		bastionList.Clear()
		bastionRefs = nil
		for ref, b := range config.Bastions {
			r := ref
			bastionRefs = append(bastionRefs, r)
			keyInfo := b.SSHKey
			if keyInfo == "" {
				keyInfo = "Globaler Key"
			}
			sub := fmt.Sprintf("ID: %s | %s", maskID(b.ID), keyInfo)
			bastionList.AddItem(fmt.Sprintf("[%s] %s", r, b.Name), sub, 0, func() {
				openBastionForm(r, func() { openSettingsMenu() })
			})
		}
	}

	refreshTunnels := func() {
		tunnelList.Clear()
		for idx, t := range config.Tunnels {
			i := idx
			subtext := fmt.Sprintf("%s -> localhost:%d (%s)", t.TargetIP, t.LocalPort, t.BastionRef)
			tunnelList.AddItem(fmt.Sprintf("%d. %s", i+1, t.Name), subtext, 0, func() {
				openTunnelForm(i, func() { openSettingsMenu() })
			})
		}
	}

	refreshBastions()
	refreshTunnels()

	panelsFlex.AddItem(bastionList, 0, 1, true)
	panelsFlex.AddItem(tunnelList, 0, 1, false)

	statusBar := tview.NewFlex().SetDirection(tview.FlexColumn)
	btnSave := tview.NewButton("Speichern (Ctrl+S)").SetSelectedFunc(func() { saveSettings() })
	btnCancel := tview.NewButton("Abbrechen (Esc)").SetSelectedFunc(func() { closeSettings() })
	btnNeu := tview.NewButton("Neu (Ctrl+N)")
	btnDel := tview.NewButton("Löschen (Del)")

	statusBar.AddItem(btnNeu, 0, 1, false)
	statusBar.AddItem(btnDel, 0, 1, false)
	statusBar.AddItem(btnSave, 0, 1, false)
	statusBar.AddItem(btnCancel, 0, 1, false)

	mainFlex.AddItem(panelsFlex, 0, 1, true)
	mainFlex.AddItem(statusBar, 1, 1, false)

	mainFlex.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		if event.Key() == tcell.KeyTab || event.Key() == tcell.KeyBacktab {
			if app.GetFocus() == bastionList {
				app.SetFocus(tunnelList)
			} else {
				app.SetFocus(bastionList)
			}
			return nil
		}

		if event.Key() == tcell.KeyCtrlN {
			if app.GetFocus() == bastionList {
				openBastionForm("", func() { openSettingsMenu() })
			} else {
				openTunnelForm(-1, func() { openSettingsMenu() })
			}
			return nil
		}

		if event.Key() == tcell.KeyDelete {
			if app.GetFocus() == bastionList {
				sel := bastionList.GetCurrentItem()
				if sel >= 0 && sel < len(bastionRefs) {
					ref := bastionRefs[sel]
					showConfirmModal("Bastion löschen", fmt.Sprintf("Soll Bastion '%s' gelöscht werden?", ref), func() {
						delete(config.Bastions, ref)
						isModified = true
						refreshBastions()
					})
				}
			} else {
				sel := tunnelList.GetCurrentItem()
				if sel >= 0 && sel < len(config.Tunnels) {
					showConfirmModal("Tunnel löschen", fmt.Sprintf("Soll '%s' wirklich gelöscht werden?", config.Tunnels[sel].Name), func() {
						config.Tunnels = append(config.Tunnels[:sel], config.Tunnels[sel+1:]...)
						isModified = true
						refreshTunnels()
					})
				}
			}
			return nil
		}

		if event.Key() == tcell.KeyCtrlS {
			saveSettings()
			return nil
		}

		if event.Key() == tcell.KeyEscape {
			closeSettings()
			return nil
		}

		return event
	})

	pages.AddPage("settings", mainFlex, true, true)
}

// --- FORMULARE (BASTION & TUNNEL) ---

func openBastionForm(ref string, onDone func()) {
	isNew := ref == ""
	var b Bastion
	var currentRef = ref

	if !isNew {
		b = config.Bastions[ref]
	} else {
		currentRef = "neue_bastion"
		b = Bastion{
			Name: "Neue Bastion",
			ID:   "ocid1.bastion.oc1...",
		}
	}

	form := tview.NewForm()
	title := " Bastion bearbeiten "
	if isNew {
		title = " Neue Bastion anlegen "
	}
	form.SetBorder(true).SetTitle(title).SetTitleAlign(tview.AlignLeft)

	form.AddInputField("Referenz Key (z.B. prod)", currentRef, 0, nil, func(text string) { currentRef = text })
	form.AddInputField("Name / Display Name", b.Name, 0, nil, func(text string) { b.Name = text })
	form.AddInputField("Bastion OCID", b.ID, 0, nil, func(text string) { b.ID = text })
	form.AddInputField("SSH Private Key Path (Optional)", b.SSHKey, 0, nil, func(text string) { b.SSHKey = text })
	form.AddInputField("SSH Public Key Path (Optional)", b.SSHPubKey, 0, nil, func(text string) { b.SSHPubKey = text })

	form.AddButton("Übernehmen", func() {
		if config.Bastions == nil {
			config.Bastions = make(map[string]Bastion)
		}
		if !isNew && currentRef != ref {
			delete(config.Bastions, ref)
		}
		config.Bastions[currentRef] = b
		isModified = true
		pages.RemovePage("bastionForm")
		onDone()
	})

	form.AddButton("Abbrechen", func() {
		pages.RemovePage("bastionForm")
	})

	form.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		if event.Key() == tcell.KeyEscape {
			pages.RemovePage("bastionForm")
			return nil
		}
		return event
	})

	pages.AddPage("bastionForm", form, true, true)
}

func openTunnelForm(index int, onDone func()) {
	isNew := index == -1
	var t TunnelConfig

	if !isNew {
		t = config.Tunnels[index]
	} else {
		defaultRef := ""
		for k := range config.Bastions {
			defaultRef = k
			break
		}
		t = TunnelConfig{
			Name:       "Neuer Tunnel",
			BastionRef: defaultRef,
			TargetIP:   "10.0.0.1",
			TargetPort: 80,
			LocalPort:  8080,
		}
	}

	form := tview.NewForm()
	title := " Tunnel bearbeiten "
	if isNew {
		title = " Neuen Tunnel anlegen "
	}
	form.SetBorder(true).SetTitle(title).SetTitleAlign(tview.AlignLeft)

	form.AddInputField("Name", t.Name, 0, nil, func(text string) { t.Name = text })

	bastionKeys := []string{}
	for k := range config.Bastions {
		bastionKeys = append(bastionKeys, k)
	}
	initialOption := 0
	for i, k := range bastionKeys {
		if k == t.BastionRef {
			initialOption = i
			break
		}
	}
	form.AddDropDown("Bastion Reference", bastionKeys, initialOption, func(option string, optionIndex int) {
		t.BastionRef = option
	})

	form.AddInputField("Target IP", t.TargetIP, 0, nil, func(text string) { t.TargetIP = text })
	form.AddInputField("Target Port", strconv.Itoa(t.TargetPort), 0, nil, func(text string) {
		p, _ := strconv.Atoi(text)
		t.TargetPort = p
	})
	form.AddInputField("Local Port", strconv.Itoa(t.LocalPort), 0, nil, func(text string) {
		p, _ := strconv.Atoi(text)
		t.LocalPort = p
	})
	form.AddInputField("Info/Hint (Optional)", t.Hint, 0, nil, func(text string) { t.Hint = text })

	form.AddButton("Übernehmen", func() {
		t.Status = "INACTIVE"
		if isNew {
			config.Tunnels = append(config.Tunnels, t)
		} else {
			config.Tunnels[index] = t
		}
		isModified = true
		pages.RemovePage("tunnelForm")
		onDone()
	})

	form.AddButton("Abbrechen", func() {
		pages.RemovePage("tunnelForm")
	})

	form.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		if event.Key() == tcell.KeyEscape {
			pages.RemovePage("tunnelForm")
			return nil
		}
		return event
	})

	pages.AddPage("tunnelForm", form, true, true)
}

func saveSettings() {
	data, err := toml.Marshal(config)
	if err != nil {
		showModal("Fehler", fmt.Sprintf("Kann Config nicht serialisieren: %v", err))
		return
	}

	if err := os.WriteFile(configFile, data, 0600); err != nil {
		showModal("Fehler", fmt.Sprintf("Fehler beim Speichern der %s: %v", configFile, err))
		return
	}

	isModified = false
	pages.RemovePage("settings")
	pages.SwitchToPage("main")
	updateBastionDisplay()
	updateTunnelDisplay()
	app.SetFocus(mainGrid)
}

func closeSettings() {
	if isModified {
		showConfirmModal("Ungespeicherte Änderungen", "Änderungen verwerfen?", func() {
			isModified = false
			pages.RemovePage("settings")
			pages.SwitchToPage("main")
			updateBastionDisplay()
			updateTunnelDisplay()
			app.SetFocus(mainGrid)
		})
	} else {
		pages.RemovePage("settings")
		pages.SwitchToPage("main")
		updateBastionDisplay()
		updateTunnelDisplay()
		app.SetFocus(mainGrid)
	}
}

// --- MODAL HELPER ---

func showModal(title, text string) {
	modal := tview.NewModal().
		SetText(fmt.Sprintf("[yellow]%s[white]\n\n%s", title, text)).
		AddButtons([]string{"OK"}).
		SetDoneFunc(func(buttonIndex int, buttonLabel string) {
			pages.RemovePage("modal")
			if getFrontPage() == "main" {
				app.SetFocus(mainGrid)
			}
		})
	pages.AddPage("modal", modal, false, true)
}

func showConfirmModal(title, text string, onConfirm func()) {
	modal := tview.NewModal().
		SetText(fmt.Sprintf("[yellow]%s[white]\n\n%s", title, text)).
		AddButtons([]string{"Ja", "Nein"}).
		SetDoneFunc(func(buttonIndex int, buttonLabel string) {
			pages.RemovePage("confirmModal")
			if buttonLabel == "Ja" {
				onConfirm()
			} else {
				if getFrontPage() == "main" {
					app.SetFocus(mainGrid)
				}
			}
		})
	pages.AddPage("confirmModal", modal, false, true)
}

func getFrontPage() string {
	name, _ := pages.GetFrontPage()
	return name
}