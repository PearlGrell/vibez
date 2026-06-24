# Vibez WebSocket API

## Connection

**URL:** `ws://<host>:<port>`
**Transport:** Socket.IO

### Authentication

Pass a JWT token in the handshake auth object. All events require authentication.

```js
const socket = io("ws://localhost:3000", {
  auth: { token: "<jwt_token>" }
});
```

Connection is rejected with `"Authentication error"` if the token is missing or invalid.

---

## Object Schemas

### Room

```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "tags": ["string"],
  "private": false,
  "currentDj": User | null,
  "createdBy": User | null,
  "createdById": "string | null",
  "currentSong": Song | null,
  "startedAt": "ISO8601 | null",
  "playing": false,
  "createdAt": "ISO8601",
  "updatedAt": "ISO8601"
}
```

### User

```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "username": "string",
  "profileUrl": "string | null",
  "bio": "string | null",
  "tags": ["string"]
}
```

### Song

```json
{
  "id": "string",
  "title": "string",
  "duration": 0,
  "thumbnail": "string | null",
  "year": "string | null",
  "albumId": "string",
  "artists": [Artist]
}
```

### QueueItem

```json
{
  "id": "string",
  "roomId": "string",
  "song": Song,
  "songId": "string",
  "addedBy": User,
  "addedById": "string",
  "position": 0,
  "addedAt": "ISO8601"
}
```

---

## Permission Model

| Role | Can do |
|------|--------|
| **DJ** | Add/remove songs from queue, play, pause, change song, assign DJ to someone else, leave DJ |
| **Non-DJ participant** | Request songs, request to become DJ, join as DJ (if seat is empty) |
| **Any participant** | List rooms, get room details, join/leave room, get queue |

---

## Events

### Emit (Client → Server)

These are events the client sends. Each returns an **ack response** to the caller and may **broadcast** to the room.

---

#### Room Listing & Details

##### `rooms`

List all public rooms with optional sorting and pagination.

**Payload:**
```json
{
  "limit?": 20,
  "page?": 1,
  "sort?": "trending" | "newest" | "related"
}
```

| Sort | Behavior |
|------|----------|
| *(omitted)* | Default DB order (no sorting) |
| `trending` | Most active participants first |
| `newest` | Most recently started rooms first |
| `related` | Rooms whose tags overlap the authenticated user's tags (most overlap first) |

**Ack Response:**
```json
{
  "rooms": [
    {
      "id": "string",
      "name": "string",
      "description": "string",
      "tags": ["string"],
      "currentDj": User | null,
      "createdBy": User | null,
      "participants": 0,
      "currentSong": Song | null,
      "playing": false,
      "startedAt": "ISO8601 | null"
    }
  ],
  "total": 0,
  "limit": 20,
  "page": 1,
  "totalPages": 1
}
```

##### `room:details`

Get full details for a single room.

**Payload:**
```json
{ "roomId": "string" }
```

**Ack Response:**
```json
{
  "room": Room,
  "participants": 0
}
```

---

#### Join & Leave

##### `room:join`

Join a room. Automatically leaves any previously joined room (including DJ auto-reassignment if the user was DJ there).

**Payload:**
```json
{ "roomId": "string" }
```

**Ack Response:**
```json
{
  "success": true,
  "room": Room,
  "participants": 0
}
```

**Broadcasts to room:**
- `room:user_joined` — `{ userId, room, participants }`
- If user was DJ in old room: `room:state_update` + `room:user_left` to old room

##### `room:leave`

Leave a room. If the user is the current DJ, a random remaining participant is auto-assigned as the new DJ.

**Payload:**
```json
{ "roomId": "string" }
```

**Ack Response:**
```json
{
  "success": true,
  "roomId": "string"
}
```

**Broadcasts to room:**
- `room:user_left` — `{ userId, room, participants }`
- If user was DJ: `room:state_update` — `{ room, participants }` (with new DJ or cleared)

---

#### Queue

##### `room:queue`

Get the current queue for a room. Anyone can call this.

**Payload:**
```json
{ "roomId": "string" }
```

**Ack Response:**
```json
{
  "queue": [QueueItem]
}
```

##### `room:add_song`

Add a song to the queue. **DJ only.**

**Payload:**
```json
{ "roomId": "string", "songId": "string" }
```

**Ack Response:**
```json
{ "item": QueueItem }
```

**Broadcasts to room:**
- `room:song_added` — `{ item: QueueItem }`

**Error:** `NOT_DJ` if caller is not the DJ.

##### `room:remove_song`

Remove a song from the queue. **DJ only.**

**Payload:**
```json
{ "roomId": "string", "queueItemId": "string" }
```

**Ack Response:**
```json
{ "item": QueueItem }
```

**Broadcasts to room:**
- `room:song_removed` — `{ item: QueueItem }`

**Error:** `NOT_DJ` if caller is not the DJ.

##### `room:request_song`

Request a song to be played. **Anyone except the DJ.**

**Payload:**
```json
{ "roomId": "string", "songId": "string" }
```

**Ack Response:**
```json
{
  "roomId": "string",
  "song": Song,
  "requestedBy": User
}
```

**Broadcasts to room:**
- `room:song_requested` — `{ roomId, song, requestedBy }`

**Error:** `IS_DJ` if the DJ tries to request (they should add directly).

---

#### Playback

##### `room:play`

Resume playback. **DJ only.**

**Payload:**
```json
{ "roomId": "string" }
```

**Ack Response:**
```json
{ "room": Room, "participants": 0 }
```

**Broadcasts to room:**
- `room:state_update` — `{ room, participants }`

##### `room:pause`

Pause playback. **DJ only.**

**Payload:**
```json
{ "roomId": "string" }
```

**Ack Response:**
```json
{ "room": Room, "participants": 0 }
```

**Broadcasts to room:**
- `room:state_update` — `{ room, participants }`

##### `room:song_changed`

Change the currently playing song. Auto-sets `playing=true` and `startedAt=now`. **DJ only.**

**Payload:**
```json
{ "roomId": "string", "songId": "string" }
```

**Ack Response:**
```json
{ "room": Room, "participants": 0 }
```

**Broadcasts to room:**
- `room:state_update` — `{ room, participants }`

---

#### DJ Management

##### `room:request_dj`

Request to become the DJ. Broadcasts to the room so the current DJ / room members can see.

**Payload:**
```json
{ "roomId": "string" }
```

**Ack Response:**
```json
{ "success": true }
```

**Broadcasts to room:**
- `room:dj_requested` — `{ user: User }`

##### `room:join_dj`

Claim the DJ seat. Fails if someone is already DJ.

**Payload:**
```json
{ "roomId": "string" }
```

**Ack Response:**
```json
{ "room": Room, "participants": 0 }
```

**Broadcasts to room:**
- `room:state_update` — `{ room, participants }`

**Error:** `FORBIDDEN` if room already has a DJ.

##### `room:leave_dj`

Step down as DJ. A random remaining participant is auto-assigned as the new DJ. If no participants remain, playback state is cleared.

**Payload:**
```json
{ "roomId": "string" }
```

**Ack Response:**
```json
{ "room": Room, "participants": 0 }
```

**Broadcasts to room:**
- `room:state_update` — `{ room, participants }`

**Error:** `FORBIDDEN` if caller is not the current DJ.

##### `room:assign_dj`

Hand off the DJ seat to another user. **Current DJ only.**

**Payload:**
```json
{ "roomId": "string", "userId": "string" }
```

**Ack Response:**
```json
{ "room": Room, "participants": 0 }
```

**Broadcasts to room:**
- `room:state_update` — `{ room, participants }`

**Error:** `FORBIDDEN` if caller is not the current DJ.

---

### Listen (Server → Client)

These are events broadcast to all participants in a room. Subscribe to these for real-time state.

| Event | Payload | When |
|-------|---------|------|
| `room:state_update` | `{ room: Room, participants: number }` | Any room state change: DJ join/leave/assign, play/pause, song change |
| `room:user_joined` | `{ userId: string, room: Room, participants: number }` | A user joins the room |
| `room:user_left` | `{ userId: string, room: Room, participants: number }` | A user leaves the room or disconnects |
| `room:song_added` | `{ item: QueueItem }` | DJ adds a song to the queue |
| `room:song_removed` | `{ item: QueueItem }` | DJ removes a song from the queue |
| `room:song_requested` | `{ roomId: string, song: Song, requestedBy: User }` | A participant requests a song |
| `room:dj_requested` | `{ user: User }` | A participant requests to become DJ |

---

## Auto-Behaviors

### DJ auto-reassignment

When the current DJ **leaves the room**, **disconnects**, or **switches to another room**:

1. A random remaining participant is selected as the new DJ
2. `room:state_update` is broadcast with the updated room (new DJ assigned)
3. If no participants remain, `currentDj`, `currentSong`, `playing`, and `startedAt` are all cleared

### Single-room enforcement

A client can only be in one room at a time. Joining a new room automatically leaves the previous one (including DJ cleanup).

---

## Error Codes

Errors are delivered as Socket.IO exceptions:

| Code | Message | When |
|------|---------|------|
| `ROOM_NOT_FOUND` | Room not found | Invalid `roomId` |
| `NOT_DJ` | Only the DJ can perform this action | Non-DJ tries add/remove song, play, pause, change song |
| `IS_DJ` | The DJ cannot perform this action | DJ tries to request a song |
| `FORBIDDEN` | Various | Join DJ when seat taken, leave DJ when not DJ, assign DJ when not DJ |
