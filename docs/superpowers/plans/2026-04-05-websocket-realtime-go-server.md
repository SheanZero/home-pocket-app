# WebSocket Realtime Group Status — Go Relay Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add WebSocket Hub and endpoint to the Go relay server so group status events (join_request, member_confirmed, member_left, group_dissolved) are broadcast in realtime to connected clients.

**Architecture:** A single `Hub` goroutine manages all WebSocket connections keyed by `groupId`. Existing REST handlers call `hub.Broadcast()` after state changes. Each client has independent read/write goroutines. Authentication reuses the existing Ed25519 device key verification with a WebSocket-specific signature format.

**Tech Stack:** Go 1.22+, `gorilla/websocket`, chi router, PostgreSQL 16

**Note:** Replace `yourmodule` in import paths with the actual module path from your `go.mod` file (e.g., `github.com/xinz/sync-relay`).

**Spec:** `docs/superpowers/specs/2026-04-04-websocket-realtime-group-status-design.md`

**Server Design Doc:** `docs/arch/server/SERVER-001_SyncRelay.md`

**Prerequisite:** The Go relay server REST API must already be functional with device registration, group endpoints, and Ed25519 auth middleware. This plan adds WebSocket support alongside the existing REST API.

---

## File Structure

### New Files

These files follow the existing server project structure from SERVER-001.

| File | Responsibility |
|------|---------------|
| `internal/ws/hub.go` | Hub struct, main loop goroutine, register/unregister/broadcast via channels |
| `internal/ws/client.go` | Client struct, readPump/writePump goroutines, message handling |
| `internal/ws/message.go` | WebSocket message types (auth, event, ping/pong) |
| `internal/handler/ws_handler.go` | HTTP upgrade handler, auth validation, connection setup |
| `internal/ws/hub_test.go` | Hub unit tests |
| `internal/ws/client_test.go` | Client unit tests |
| `internal/handler/ws_handler_test.go` | WebSocket handler integration tests |

### Modified Files
| File | Change |
|------|--------|
| `go.mod` | Add `github.com/gorilla/websocket` dependency |
| `cmd/relay/main.go` | Create Hub, start goroutine, pass to handlers |
| `internal/handler/routes.go` (or equivalent) | Add `/ws/group/{groupId}` route |
| `internal/handler/group_handler.go` | Call `hub.Broadcast()` after confirm, confirm-join, leave, delete |

---

## Task 1: Add `gorilla/websocket` dependency

**Files:**
- Modify: `go.mod`

- [ ] **Step 1: Add dependency**

```bash
go get github.com/gorilla/websocket@v1.5.3
```

- [ ] **Step 2: Verify**

Run: `go mod tidy`
Expected: Clean, no errors.

- [ ] **Step 3: Commit**

```bash
git add go.mod go.sum
git commit -m "chore: add gorilla/websocket dependency"
```

---

## Task 2: Create WebSocket message types

**Files:**
- Create: `internal/ws/message.go`

- [ ] **Step 1: Write message types**

```go
package ws

import "time"

// AuthMessage is the first message a client sends after connecting.
type AuthMessage struct {
	DeviceID        string `json:"deviceId"`
	Timestamp       int64  `json:"timestamp"`
	Signature       string `json:"signature"`
	ProtocolVersion int    `json:"protocolVersion"`
}

// EventMessage is a server-to-client event broadcast.
type EventMessage struct {
	Type      string    `json:"type"`
	GroupID   string    `json:"groupId"`
	DeviceID  string    `json:"deviceId,omitempty"`
	Timestamp time.Time `json:"timestamp"`
	Data      any       `json:"data,omitempty"`
}

// PingMessage is a client-to-server heartbeat.
type PingMessage struct {
	Type string `json:"type"` // "ping"
}

// PongMessage is a server-to-client heartbeat response.
type PongMessage struct {
	Type string `json:"type"` // "pong"
}

// AuthSuccessMessage is sent after successful authentication.
type AuthSuccessMessage struct {
	Type    string `json:"type"` // "auth_success"
	GroupID string `json:"groupId"`
}

// AuthErrorMessage is sent when authentication fails.
type AuthErrorMessage struct {
	Type    string `json:"type"` // "auth_error"
	Message string `json:"message"`
}

// BroadcastMessage is used internally to send events to all clients in a group.
type BroadcastMessage struct {
	GroupID string
	Event   EventMessage
}
```

- [ ] **Step 2: Verify compilation**

Run: `go build ./internal/ws/`
Expected: Compiles successfully.

- [ ] **Step 3: Commit**

```bash
git add internal/ws/message.go
git commit -m "feat(ws): add WebSocket message type definitions"
```

---

## Task 3: Create Hub — connection manager

**Files:**
- Create: `internal/ws/hub.go`
- Create: `internal/ws/hub_test.go`

- [ ] **Step 1: Write failing Hub tests**

```go
package ws

import (
	"testing"
	"time"
)

func TestHub_RegisterAndUnregister(t *testing.T) {
	hub := NewHub()
	go hub.Run()
	defer hub.Stop()

	client := &Client{
		groupID:  "group-1",
		deviceID: "device-1",
		send:     make(chan []byte, 256),
	}

	hub.Register <- client

	// HasClient is thread-safe (goes through hub's event loop)
	if !hub.HasClient("group-1", "device-1") {
		t.Fatal("expected client to be registered")
	}

	hub.Unregister <- client

	if hub.HasClient("group-1", "device-1") {
		t.Fatal("expected client to be unregistered")
	}
}

func TestHub_Broadcast(t *testing.T) {
	hub := NewHub()
	go hub.Run()
	defer hub.Stop()

	client := &Client{
		groupID:  "group-1",
		deviceID: "device-1",
		send:     make(chan []byte, 256),
	}

	hub.Register <- client

	// Ensure registration is processed before broadcasting
	if !hub.HasClient("group-1", "device-1") {
		t.Fatal("client not registered")
	}

	hub.BroadcastCh <- BroadcastMessage{
		GroupID: "group-1",
		Event: EventMessage{
			Type:      "member_confirmed",
			GroupID:   "group-1",
			DeviceID:  "device-2",
			Timestamp: time.Now(),
		},
	}
	// Wait for broadcast to be delivered
	select {
	case msg := <-client.send:
		if len(msg) == 0 {
			t.Fatal("expected non-empty message")
		}
	default:
		t.Fatal("expected message in client send channel")
	}
}

func TestHub_BroadcastToCorrectGroup(t *testing.T) {
	hub := NewHub()
	go hub.Run()
	defer hub.Stop()

	client1 := &Client{
		groupID:  "group-1",
		deviceID: "device-1",
		send:     make(chan []byte, 256),
	}
	client2 := &Client{
		groupID:  "group-2",
		deviceID: "device-2",
		send:     make(chan []byte, 256),
	}

	hub.Register <- client1
	hub.Register <- client2

	// HasClient calls synchronize through the hub's event loop
	if !hub.HasClient("group-1", "device-1") {
		t.Fatal("client1 not registered")
	}

	hub.BroadcastCh <- BroadcastMessage{
		GroupID: "group-1",
		Event: EventMessage{
			Type:    "join_request",
			GroupID: "group-1",
		},
	}

	// client1 should receive the message
	select {
	case <-client1.send:
		// OK
	case <-time.After(time.Second):
		t.Fatal("timeout waiting for client1 message")
	}

	// client2 should NOT receive the message
	select {
	case <-client2.send:
		t.Fatal("client2 should not receive message for group-1")
	default:
		// OK
	}
}

func TestHub_DuplicateConnection_KicksOld(t *testing.T) {
	hub := NewHub()
	go hub.Run()
	defer hub.Stop()

	oldClient := &Client{
		groupID:  "group-1",
		deviceID: "device-1",
		send:     make(chan []byte, 256),
	}
	newClient := &Client{
		groupID:  "group-1",
		deviceID: "device-1",
		send:     make(chan []byte, 256),
	}

	hub.Register <- oldClient
	if !hub.HasClient("group-1", "device-1") {
		t.Fatal("old client not registered")
	}

	hub.Register <- newClient

	// Old client's send channel should be closed (kicked)
	_, ok := <-oldClient.send
	if ok {
		t.Fatal("expected old client send channel to be closed")
	}

	// New client should be registered
	if !hub.HasClient("group-1", "device-1") {
		t.Fatal("expected new client to be registered")
	}
}

func TestHub_CleanupEmptyGroup(t *testing.T) {
	hub := NewHub()
	go hub.Run()
	defer hub.Stop()

	client := &Client{
		groupID:  "group-1",
		deviceID: "device-1",
		send:     make(chan []byte, 256),
	}

	hub.Register <- client
	if !hub.HasClient("group-1", "device-1") {
		t.Fatal("client not registered")
	}

	hub.Unregister <- client

	if hub.GroupCount() != 0 {
		t.Fatalf("expected 0 groups, got %d", hub.GroupCount())
	}
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `go test ./internal/ws/ -run TestHub -v`
Expected: FAIL — `hub.go` does not exist.

- [ ] **Step 3: Write Hub implementation**

```go
package ws

import (
	"encoding/json"
	"log"
	"sync"
)

// Hub manages all WebSocket connections grouped by groupID.
//
// All mutations are serialized through channels — no locks needed
// for the groups map. The Hub runs as a single goroutine.
// queryMsg is used for thread-safe queries into the Hub's state.
type queryMsg struct {
	groupID  string
	deviceID string
	result   chan bool
}

type Hub struct {
	Register     chan *Client
	Unregister   chan *Client
	BroadcastCh  chan BroadcastMessage
	queries      chan queryMsg
	countQueries chan chan int

	groups map[string]map[*Client]bool
	stop   chan struct{}
	once   sync.Once
}

// NewHub creates a new Hub. Call Run() in a goroutine.
func NewHub() *Hub {
	return &Hub{
		Register:     make(chan *Client),
		Unregister:   make(chan *Client),
		BroadcastCh:  make(chan BroadcastMessage),
		queries:      make(chan queryMsg),
		countQueries: make(chan chan int),
		groups:       make(map[string]map[*Client]bool),
		stop:         make(chan struct{}),
	}
}

// Run starts the hub main loop. Blocks until Stop() is called.
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.register(client)
		case client := <-h.Unregister:
			h.unregister(client)
		case msg := <-h.BroadcastCh:
			h.broadcast(msg)
		case q := <-h.queries:
			q.result <- h.hasClient(q.groupID, q.deviceID)
		case ch := <-h.countQueries:
			ch <- len(h.groups)
		case <-h.stop:
			h.shutdown()
			return
		}
	}
}

// hasClient is the internal (non-thread-safe) check, called from Run() only.
func (h *Hub) hasClient(groupID, deviceID string) bool {
	group, ok := h.groups[groupID]
	if !ok {
		return false
	}
	for client := range group {
		if client.deviceID == deviceID {
			return true
		}
	}
	return false
}

// Stop gracefully shuts down the hub.
func (h *Hub) Stop() {
	h.once.Do(func() {
		close(h.stop)
	})
}

func (h *Hub) register(client *Client) {
	group, ok := h.groups[client.groupID]
	if !ok {
		group = make(map[*Client]bool)
		h.groups[client.groupID] = group
	}

	// Kick existing connection with same deviceID (anti-abuse)
	for existing := range group {
		if existing.deviceID == client.deviceID {
			close(existing.send)
			delete(group, existing)
			break
		}
	}

	group[client] = true
}

func (h *Hub) unregister(client *Client) {
	group, ok := h.groups[client.groupID]
	if !ok {
		return
	}

	if _, exists := group[client]; exists {
		delete(group, client)
		close(client.send)
	}

	// Clean up empty groups
	if len(group) == 0 {
		delete(h.groups, client.groupID)
	}
}

func (h *Hub) broadcast(msg BroadcastMessage) {
	group, ok := h.groups[msg.GroupID]
	if !ok {
		return
	}

	data, err := json.Marshal(msg.Event)
	if err != nil {
		log.Printf("ws hub: failed to marshal event: %v", err)
		return
	}

	for client := range group {
		select {
		case client.send <- data:
		default:
			// Client send buffer full — drop and disconnect
			close(client.send)
			delete(group, client)
		}
	}

	if len(group) == 0 {
		delete(h.groups, msg.GroupID)
	}
}

func (h *Hub) shutdown() {
	for groupID, group := range h.groups {
		for client := range group {
			close(client.send)
		}
		delete(h.groups, groupID)
	}
}

// HasClient checks if a device is connected to a group.
// Thread-safe: sends query through the hub's event loop via channel.
func (h *Hub) HasClient(groupID, deviceID string) bool {
	result := make(chan bool, 1)
	// Use a query channel (add to Hub struct: query chan queryMsg)
	// For simplicity, we use a synchronous approach with the main loop.
	// Implementation: add a `queries` channel to Hub that the Run() loop handles.
	h.queries <- queryMsg{
		groupID:  groupID,
		deviceID: deviceID,
		result:   result,
	}
	return <-result
}

// GroupCount returns the number of active groups. Thread-safe.
func (h *Hub) GroupCount() int {
	result := make(chan int, 1)
	h.countQueries <- result
	return <-result
}

// Broadcast sends an event to all connected clients in a group.
// This is the public API for REST handlers to call.
func (h *Hub) Broadcast(groupID string, event EventMessage) {
	h.BroadcastCh <- BroadcastMessage{
		GroupID: groupID,
		Event:   event,
	}
}
```

- [ ] **Step 4: Run tests**

Run: `go test ./internal/ws/ -run TestHub -v`
Expected: All 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add internal/ws/hub.go internal/ws/hub_test.go
git commit -m "feat(ws): add WebSocket Hub with channel-based connection management"
```

---

## Task 4: Create Client — read/write goroutines

**Files:**
- Create: `internal/ws/client.go`
- Create: `internal/ws/client_test.go`

- [ ] **Step 1: Write failing Client test**

```go
package ws

import (
	"encoding/json"
	"testing"
)

func TestClient_ParseAuthMessage(t *testing.T) {
	raw := `{"deviceId":"dev-1","timestamp":1712233200,"signature":"base64sig","protocolVersion":1}`
	var msg AuthMessage
	if err := json.Unmarshal([]byte(raw), &msg); err != nil {
		t.Fatalf("failed to parse auth message: %v", err)
	}
	if msg.DeviceID != "dev-1" {
		t.Errorf("expected deviceId dev-1, got %s", msg.DeviceID)
	}
	if msg.ProtocolVersion != 1 {
		t.Errorf("expected protocolVersion 1, got %d", msg.ProtocolVersion)
	}
}

func TestClient_ParsePingMessage(t *testing.T) {
	raw := `{"type":"ping"}`
	var msg map[string]string
	if err := json.Unmarshal([]byte(raw), &msg); err != nil {
		t.Fatalf("failed to parse ping: %v", err)
	}
	if msg["type"] != "ping" {
		t.Errorf("expected type ping, got %s", msg["type"])
	}
}
```

- [ ] **Step 2: Run test**

Run: `go test ./internal/ws/ -run TestClient -v`
Expected: PASS (message types already defined).

- [ ] **Step 3: Write Client implementation**

```go
package ws

import (
	"encoding/json"
	"log"
	"time"

	"github.com/gorilla/websocket"
)

const (
	// writeWait is the time allowed to write a message to the peer.
	writeWait = 10 * time.Second

	// pongWait is the time allowed to read the next pong message from the peer.
	pongWait = 45 * time.Second

	// pingPeriod sends pings with this period. Must be less than pongWait.
	pingPeriod = 30 * time.Second

	// maxMessageSize is the maximum message size allowed from peer (4KB).
	maxMessageSize = 4096

	// AuthTimeout is the time allowed for the client to send auth message.
	AuthTimeout = 5 * time.Second
)

// Client represents a single WebSocket connection.
type Client struct {
	hub      *Hub
	conn     *websocket.Conn
	groupID  string
	deviceID string
	send     chan []byte
}

// NewClient creates a new Client. Does not start read/write pumps.
func NewClient(hub *Hub, conn *websocket.Conn, groupID string) *Client {
	return &Client{
		hub:     hub,
		conn:    conn,
		groupID: groupID,
		send:    make(chan []byte, 256),
	}
}

// ReadPump reads messages from the WebSocket connection.
//
// Handles: ping messages (responds with pong), all other messages are logged.
// Runs in its own goroutine per client.
func (c *Client) ReadPump() {
	defer func() {
		c.hub.Unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(
				err,
				websocket.CloseGoingAway,
				websocket.CloseNormalClosure,
			) {
				log.Printf("ws client %s: read error: %v", c.deviceID, err)
			}
			break
		}

		var raw map[string]any
		if err := json.Unmarshal(message, &raw); err != nil {
			continue
		}

		msgType, _ := raw["type"].(string)
		if msgType == "ping" {
			pong, _ := json.Marshal(PongMessage{Type: "pong"})
			select {
			case c.send <- pong:
			default:
			}
		}
		// Other message types are handled at the handler level (auth)
		// or ignored after auth is complete.
	}
}

// WritePump writes messages to the WebSocket connection.
//
// Sends server-side pings and forwards messages from the send channel.
// Runs in its own goroutine per client.
func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// Hub closed the channel
				c.conn.WriteMessage(
					websocket.CloseMessage,
					websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""),
				)
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)
			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
```

- [ ] **Step 4: Verify compilation**

Run: `go build ./internal/ws/`
Expected: Compiles successfully.

- [ ] **Step 5: Commit**

```bash
git add internal/ws/client.go internal/ws/client_test.go
git commit -m "feat(ws): add Client with readPump/writePump goroutines"
```

---

## Task 5: Create WebSocket HTTP handler with auth

**Files:**
- Create: `internal/handler/ws_handler.go`
- Create: `internal/handler/ws_handler_test.go`

- [ ] **Step 1: Write failing handler test**

```go
package handler

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"yourmodule/internal/ws"
)

func TestWSHandler_RejectsNonWebSocket(t *testing.T) {
	hub := ws.NewHub()
	go hub.Run()
	defer hub.Stop()

	h := NewWSHandler(hub, nil) // nil device repo = will fail auth anyway

	r := chi.NewRouter()
	r.Get("/ws/group/{groupId}", h.HandleWebSocket)

	req := httptest.NewRequest(http.MethodGet, "/ws/group/group-1", nil)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	// Without WebSocket upgrade headers, this should fail
	if rec.Code == http.StatusSwitchingProtocols {
		t.Fatal("expected non-101 status for non-WebSocket request")
	}
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `go test ./internal/handler/ -run TestWSHandler -v`
Expected: FAIL — `ws_handler.go` does not exist.

- [ ] **Step 3: Write WebSocket handler**

```go
package handler

import (
	"crypto/ed25519"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/gorilla/websocket"
	"yourmodule/internal/ws"
)

// DeviceLookup retrieves a device's public key by device ID.
type DeviceLookup interface {
	GetPublicKey(deviceID string) (ed25519.PublicKey, error)
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  4096,
	WriteBufferSize: 4096,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

// WSHandler handles WebSocket connections for group status events.
type WSHandler struct {
	hub    *ws.Hub
	devices DeviceLookup
}

// NewWSHandler creates a new WebSocket handler.
func NewWSHandler(hub *ws.Hub, devices DeviceLookup) *WSHandler {
	return &WSHandler{hub: hub, devices: devices}
}

// HandleWebSocket upgrades the HTTP connection to WebSocket,
// authenticates the client, and registers it with the Hub.
func (h *WSHandler) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	groupID := chi.URLParam(r, "groupId")
	if groupID == "" {
		http.Error(w, "missing groupId", http.StatusBadRequest)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("ws: upgrade failed: %v", err)
		return
	}

	// Wait for auth message within timeout
	conn.SetReadDeadline(time.Now().Add(ws.AuthTimeout))
	_, message, err := conn.ReadMessage()
	if err != nil {
		log.Printf("ws: auth read failed: %v", err)
		conn.Close()
		return
	}

	var authMsg ws.AuthMessage
	if err := json.Unmarshal(message, &authMsg); err != nil {
		h.sendAuthError(conn, "invalid auth message format")
		conn.Close()
		return
	}

	// Verify timestamp tolerance (±30s)
	now := time.Now().Unix()
	if math.Abs(float64(now-authMsg.Timestamp)) > 30 {
		h.sendAuthError(conn, "timestamp out of range")
		conn.Close()
		return
	}

	// Verify Ed25519 signature
	pubKey, err := h.devices.GetPublicKey(authMsg.DeviceID)
	if err != nil {
		h.sendAuthError(conn, "unknown device")
		conn.Close()
		return
	}

	expectedMessage := fmt.Sprintf(
		"ws:connect:%s:%s:%d",
		groupID, authMsg.DeviceID, authMsg.Timestamp,
	)
	sigBytes, err := base64.StdEncoding.DecodeString(authMsg.Signature)
	if err != nil || !ed25519.Verify(pubKey, []byte(expectedMessage), sigBytes) {
		h.sendAuthError(conn, "invalid signature")
		conn.Close()
		return
	}

	// Auth success — register client
	conn.SetReadDeadline(time.Time{}) // Remove auth deadline

	client := ws.NewClient(h.hub, conn, groupID)
	client.SetDeviceID(authMsg.DeviceID)

	// Send auth success
	successMsg, _ := json.Marshal(ws.AuthSuccessMessage{
		Type:    "auth_success",
		GroupID: groupID,
	})
	conn.WriteMessage(websocket.TextMessage, successMsg)

	// Register with hub and start pumps
	h.hub.Register <- client
	go client.WritePump()
	go client.ReadPump()
}

func (h *WSHandler) sendAuthError(conn *websocket.Conn, msg string) {
	errMsg, _ := json.Marshal(ws.AuthErrorMessage{
		Type:    "auth_error",
		Message: msg,
	})
	conn.WriteMessage(websocket.TextMessage, errMsg)
	conn.WriteMessage(
		websocket.CloseMessage,
		websocket.FormatCloseMessage(4001, msg),
	)
}
```

Note: `client.SetDeviceID()` needs to be added to `client.go`:

```go
// SetDeviceID sets the device ID after authentication.
func (c *Client) SetDeviceID(id string) {
	c.deviceID = id
}
```

`AuthTimeout` is already exported as a constant in `client.go` (see above), so the handler can use `ws.AuthTimeout` directly.

- [ ] **Step 4: Run tests**

Run: `go test ./internal/handler/ -run TestWSHandler -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add internal/handler/ws_handler.go internal/handler/ws_handler_test.go internal/ws/client.go
git commit -m "feat(ws): add WebSocket HTTP handler with Ed25519 auth"
```

---

## Task 6: Wire Hub into server startup and routes

**Files:**
- Modify: `cmd/relay/main.go`
- Modify: `internal/handler/routes.go` (or equivalent routing file)

- [ ] **Step 1: Create Hub in main.go**

In `main.go`, before setting up routes:

```go
// Create and start WebSocket hub
hub := ws.NewHub()
go hub.Run()
defer hub.Stop()
```

Pass `hub` to handler constructors that need it.

- [ ] **Step 2: Add WebSocket route**

In the router setup:

```go
// WebSocket endpoint (no auth middleware — auth is in-band)
r.Get("/ws/group/{groupId}", wsHandler.HandleWebSocket)
```

This route must NOT have the Ed25519 HTTP auth middleware applied, because WebSocket auth happens in-band after the upgrade.

- [ ] **Step 3: Verify server starts**

Run: `go run ./cmd/relay/`
Expected: Server starts without errors.

- [ ] **Step 4: Commit**

```bash
git add cmd/relay/main.go internal/handler/routes.go
git commit -m "feat(ws): wire Hub into server startup and add /ws/group route"
```

---

## Task 7: Integrate Hub broadcasts into existing REST handlers

**Files:**
- Modify: `internal/handler/group_handler.go`

- [ ] **Step 1: Write failing integration test**

```go
func TestGroupConfirm_BroadcastsMemberConfirmed(t *testing.T) {
	hub := ws.NewHub()
	go hub.Run()
	defer hub.Stop()

	// Use NewTestClient to create a client with accessible send channel
	sendCh := make(chan []byte, 256)
	client := ws.NewTestClient(hub, "group-1", "device-1", sendCh)
	hub.Register <- client

	// Ensure registration is processed
	if !hub.HasClient("group-1", "device-1") {
		t.Fatal("client not registered")
	}

	// Call the confirm endpoint
	// ... HTTP test setup (POST /group/confirm) ...

	// Verify client received member_confirmed event
	select {
	case msg := <-sendCh:
		var event ws.EventMessage
		json.Unmarshal(msg, &event)
		if event.Type != "member_confirmed" {
			t.Errorf("expected member_confirmed, got %s", event.Type)
		}
	case <-time.After(time.Second):
		t.Fatal("timeout waiting for broadcast")
	}
}
```

**Note:** Add `NewTestClient` to `client.go` for test support:

```go
// NewTestClient creates a Client with an externally provided send channel. For testing only.
func NewTestClient(hub *Hub, groupID, deviceID string, send chan []byte) *Client {
	return &Client{
		hub:      hub,
		groupID:  groupID,
		deviceID: deviceID,
		send:     send,
	}
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `go test ./internal/handler/ -run TestGroupConfirm_Broadcasts -v`
Expected: FAIL — handler does not call hub.Broadcast.

- [ ] **Step 3: Add hub.Broadcast calls to group handler**

After each successful state change in the group handler, add the broadcast call:

**POST /group/confirm (owner confirms member):**
```go
hub.Broadcast(groupID, ws.EventMessage{
	Type:      "member_confirmed",
	GroupID:   groupID,
	DeviceID:  confirmedDeviceID,
	Timestamp: time.Now(),
})
```

**POST /group/{groupId}/confirm-join (joiner confirms):**
```go
hub.Broadcast(groupID, ws.EventMessage{
	Type:      "join_request",
	GroupID:   groupID,
	DeviceID:  joinerDeviceID,
	Timestamp: time.Now(),
})
```

**POST /group/{groupId}/leave:**
```go
hub.Broadcast(groupID, ws.EventMessage{
	Type:      "member_left",
	GroupID:   groupID,
	DeviceID:  leavingDeviceID,
	Timestamp: time.Now(),
})
```

**DELETE /group/{groupId}:**
```go
hub.Broadcast(groupID, ws.EventMessage{
	Type:      "group_dissolved",
	GroupID:   groupID,
	Timestamp: time.Now(),
})
```

The handler needs `hub` injected via constructor or context.

- [ ] **Step 4: Run tests**

Run: `go test ./internal/handler/ -v`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add internal/handler/group_handler.go internal/handler/group_handler_test.go
git commit -m "feat(ws): broadcast group events via Hub from REST handlers"
```

---

## Task 8: Add anti-abuse protections

**Files:**
- Modify: `internal/handler/ws_handler.go`

- [ ] **Step 1: Write test — unauthenticated timeout**

Test that a connection without auth message is closed after 5 seconds. This is already handled by `conn.SetReadDeadline(time.Now().Add(authTimeout))` in the handler.

- [ ] **Step 2: Add per-IP connection limit**

Add IP tracking to `WSHandler`:

```go
type WSHandler struct {
	hub     *ws.Hub
	devices DeviceLookup
	mu      sync.Mutex
	ipConns map[string]int
}

// clientIP extracts the IP address, handling X-Forwarded-For for reverse proxies (Cloud Run).
func clientIP(r *http.Request) string {
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		// Take the first IP (client IP before proxies)
		if idx := strings.Index(xff, ","); idx != -1 {
			return strings.TrimSpace(xff[:idx])
		}
		return strings.TrimSpace(xff)
	}
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

func (h *WSHandler) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	ip := clientIP(r)
	h.mu.Lock()
	if h.ipConns[ip] >= 10 {
		h.mu.Unlock()
		http.Error(w, "too many connections", http.StatusTooManyRequests)
		return
	}
	h.ipConns[ip]++
	h.mu.Unlock()

	// ... rest of handler ...

	// After client pumps start, decrement on disconnect:
	go func() {
		// ReadPump blocks until connection closes, then unregisters from Hub
		client.ReadPump()
		h.mu.Lock()
		h.ipConns[ip]--
		if h.ipConns[ip] <= 0 {
			delete(h.ipConns, ip)
		}
		h.mu.Unlock()
	}()
}
```

- [ ] **Step 3: Run tests**

Run: `go test ./internal/handler/ -v`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add internal/handler/ws_handler.go
git commit -m "feat(ws): add per-IP connection limit (max 10)"
```

---

## Task 9: Run full test suite

**Files:** None (verification only)

- [ ] **Step 1: Run all Go tests**

Run: `go test ./... -v`
Expected: All tests PASS.

- [ ] **Step 2: Run go vet**

Run: `go vet ./...`
Expected: No issues.

- [ ] **Step 3: Run linter (if configured)**

Run: `golangci-lint run`
Expected: No issues (or only pre-existing ones).
