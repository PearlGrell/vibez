// Vibez API Endpoint Dataset (45 endpoints)
const endpoints = [
  // ==========================================
  // AUTH MODULE (/api/auth)
  // ==========================================
  {
    id: "auth-login",
    module: "Auth",
    name: "Login User",
    method: "POST",
    path: "/api/auth/login",
    description: "Authenticates a user with email and password, returning an access token and setting a secure HttpOnly refresh token cookie.",
    auth: false,
    headers: [
      { name: "x-device-name", type: "string", required: false, description: "Name of the device performing the login (e.g., iPhone 15)" }
    ],
    body: [
      { name: "email", type: "string", required: true, description: "Valid email address of the user." },
      { name: "password", type: "string", required: true, description: "User's password (min 8 chars, must contain uppercase, lowercase, and number)." }
    ],
    bodyExample: JSON.stringify({ email: "user@example.com", password: "Password123" }, null, 2),
    responseExample: { token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." }
  },
  {
    id: "auth-register",
    module: "Auth",
    name: "Register User",
    method: "POST",
    path: "/api/auth/register",
    description: "Registers a new user account with a name, email, and password.",
    auth: false,
    headers: [
      { name: "x-device-name", type: "string", required: false, description: "Name of the device performing the registration." }
    ],
    body: [
      { name: "name", type: "string", required: true, description: "Full name of the user." },
      { name: "email", type: "string", required: true, description: "Valid and unique email address." },
      { name: "password", type: "string", required: true, description: "Strong password (min 8 chars, uppercase, lowercase, and digit)." }
    ],
    bodyExample: JSON.stringify({ name: "Jane Doe", email: "jane@example.com", password: "Password123" }, null, 2),
    responseExample: { token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." }
  },
  {
    id: "auth-forgot",
    module: "Auth",
    name: "Forgot Password",
    method: "POST",
    path: "/api/auth/forgot",
    description: "Sends an OTP code to the registered email address to initiate password recovery.",
    auth: false,
    body: [
      { name: "email", type: "string", required: true, description: "Registered email address." }
    ],
    bodyExample: JSON.stringify({ email: "user@example.com" }, null, 2),
    responseExample: { success: true, message: "OTP sent successfully" }
  },
  {
    id: "auth-forgot-resend",
    module: "Auth",
    name: "Resend Recovery OTP",
    method: "POST",
    path: "/api/auth/forgot/resend",
    description: "Resends the password recovery OTP to the email address.",
    auth: false,
    body: [
      { name: "email", type: "string", required: true, description: "Registered email address." }
    ],
    bodyExample: JSON.stringify({ email: "user@example.com" }, null, 2),
    responseExample: { success: true, message: "OTP resent successfully" }
  },
  {
    id: "auth-verify",
    module: "Auth",
    name: "Verify OTP",
    method: "POST",
    path: "/api/auth/verify",
    description: "Verifies the recovery OTP received via email.",
    auth: false,
    body: [
      { name: "email", type: "string", required: true, description: "Registered email address." },
      { name: "otp", type: "string", required: true, description: "6-digit OTP code." }
    ],
    bodyExample: JSON.stringify({ email: "user@example.com", otp: "123456" }, null, 2),
    responseExample: { success: true, resetToken: "reset_token_abc123" }
  },
  {
    id: "auth-reset",
    module: "Auth",
    name: "Reset Password",
    method: "POST",
    path: "/api/auth/reset",
    description: "Resets the user's password using the token received after OTP verification.",
    auth: false,
    body: [
      { name: "resetToken", type: "string", required: true, description: "Token obtained from verifying OTP." },
      { name: "password", type: "string", required: true, description: "New password (min 8 chars, uppercase, lowercase, and digit)." }
    ],
    bodyExample: JSON.stringify({ resetToken: "reset_token_abc123", password: "NewPassword123" }, null, 2),
    responseExample: { success: true, message: "Password updated successfully" }
  },
  {
    id: "auth-refresh",
    module: "Auth",
    name: "Refresh Access Token",
    method: "POST",
    path: "/api/auth/refresh",
    description: "Refreshes the access token using the HttpOnly refresh token cookie.",
    auth: false,
    responseExample: { token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." }
  },
  {
    id: "auth-logout",
    module: "Auth",
    name: "Logout User",
    method: "POST",
    path: "/api/auth/logout",
    description: "Logs out the user and revokes the active session.",
    auth: true,
    responseExample: { success: true, message: "Logged out successfully" }
  },
  {
    id: "auth-sessions",
    module: "Auth",
    name: "Get Active Sessions",
    method: "GET",
    path: "/api/auth/sessions",
    description: "Lists all active login sessions/devices for the current authenticated user.",
    auth: true,
    responseExample: [
      { id: "sess_1", deviceName: "iPhone 15", ipAddress: "127.0.0.1", lastActive: "2026-06-16T13:00:00Z" }
    ]
  },
  {
    id: "auth-email-update",
    module: "Auth",
    name: "Update Email Address",
    method: "PATCH",
    path: "/api/auth/email",
    description: "Updates the authenticated user's email address.",
    auth: true,
    body: [
      { name: "email", type: "string", required: true, description: "New email address." }
    ],
    bodyExample: JSON.stringify({ email: "newemail@example.com" }, null, 2),
    responseExample: { success: true, message: "Email updated successfully" }
  },
  {
    id: "auth-password-change",
    module: "Auth",
    name: "Change Password",
    method: "PATCH",
    path: "/api/auth/password",
    description: "Changes the authenticated user's password.",
    auth: true,
    body: [
      { name: "oldPassword", type: "string", required: true, description: "Current password." },
      { name: "newPassword", type: "string", required: true, description: "New password (min 8 chars, uppercase, lowercase, and digit)." }
    ],
    bodyExample: JSON.stringify({ oldPassword: "Password123", newPassword: "NewPassword123" }, null, 2),
    responseExample: { success: true, message: "Password updated successfully" }
  },

  // ==========================================
  // USERS MODULE (/api/users)
  // ==========================================
  {
    id: "users-me",
    module: "Users",
    name: "Get My Profile",
    method: "GET",
    path: "/api/users/me",
    description: "Retrieves the profile information for the currently authenticated user.",
    auth: true,
    responseExample: { id: "user_abc123", name: "Jane Doe", email: "jane@example.com", username: "janedoe", bio: "Music lover" }
  },
  {
    id: "users-check-username",
    module: "Users",
    name: "Check Username",
    method: "GET",
    path: "/api/users/check-username",
    description: "Checks if a desired username is available. Length 3-16, letters, numbers, dots, and underscores only.",
    auth: false,
    query: [
      { name: "username", type: "string", required: true, description: "Desired username." }
    ],
    responseExample: { available: true }
  },
  {
    id: "users-find-all",
    module: "Users",
    name: "List/Search Users",
    method: "GET",
    path: "/api/users",
    description: "Retrieves a paginated list of users, optionally filtered by username.",
    auth: false,
    query: [
      { name: "username", type: "string", required: false, description: "Filter by matching username." },
      { name: "page", type: "integer", required: false, description: "Page number (default: 1)." },
      { name: "limit", type: "integer", required: false, description: "Records per page (default: 10)." }
    ],
    responseExample: {
      data: [{ id: "user_1", name: "Alice", username: "alice" }],
      meta: { total: 1, page: 1, limit: 10 }
    }
  },
  {
    id: "users-follow",
    module: "Users",
    name: "Follow User",
    method: "POST",
    path: "/api/users/:id/follow",
    description: "Follows a target user by ID.",
    auth: true,
    params: [
      { name: "id", type: "string", required: true, description: "ID of the user to follow." }
    ],
    responseExample: { success: true, message: "Successfully followed user" }
  },
  {
    id: "users-unfollow",
    module: "Users",
    name: "Unfollow User",
    method: "POST",
    path: "/api/users/:id/unfollow",
    description: "Unfollows a target user by ID.",
    auth: true,
    params: [
      { name: "id", type: "string", required: true, description: "ID of the user to unfollow." }
    ],
    responseExample: { success: true, message: "Successfully unfollowed user" }
  },
  {
    id: "users-followers",
    module: "Users",
    name: "Get Followers",
    method: "GET",
    path: "/api/users/:id/followers",
    description: "Gets the followers list for the user with the specified ID.",
    auth: false,
    params: [
      { name: "id", type: "string", required: true, description: "User ID." }
    ],
    query: [
      { name: "page", type: "integer", required: false, description: "Page number (default: 1)." },
      { name: "limit", type: "integer", required: false, description: "Records per page (default: 10)." }
    ],
    responseExample: [{ id: "user_2", name: "Bob", username: "bob" }]
  },
  {
    id: "users-following",
    module: "Users",
    name: "Get Following",
    method: "GET",
    path: "/api/users/:id/following",
    description: "Gets the list of users that the specified user is following.",
    auth: false,
    params: [
      { name: "id", type: "string", required: true, description: "User ID." }
    ],
    query: [
      { name: "page", type: "integer", required: false, description: "Page number (default: 1)." },
      { name: "limit", type: "integer", required: false, description: "Records per page (default: 10)." }
    ],
    responseExample: [{ id: "user_3", name: "Charlie", username: "charlie" }]
  },
  {
    id: "users-find-one",
    module: "Users",
    name: "Get User By ID",
    method: "GET",
    path: "/api/users/:id",
    description: "Retrieves public profile details for a specific user ID.",
    auth: false,
    params: [
      { name: "id", type: "string", required: true, description: "User ID." }
    ],
    responseExample: { id: "user_abc123", name: "Jane Doe", username: "janedoe", bio: "Artist & Coder" }
  },
  {
    id: "users-update",
    module: "Users",
    name: "Update User",
    method: "PATCH",
    path: "/api/users/:id",
    description: "Updates profile fields for a user. Requires at least one field.",
    auth: false,
    params: [
      { name: "id", type: "string", required: true, description: "User ID." }
    ],
    body: [
      { name: "username", type: "string", required: false, description: "New username (must be unique)." },
      { name: "bio", type: "string", required: false, description: "Short user bio description." },
      { name: "profileUrl", type: "string", required: false, description: "URL to the user's profile image." },
      { name: "tags", type: "array of strings", required: false, description: "Interests or genres tags (e.g., ['lofi', 'rock'])." }
    ],
    bodyExample: JSON.stringify({ bio: "New bio details!", tags: ["lofi", "jazz"] }, null, 2),
    responseExample: { id: "user_abc123", name: "Jane Doe", username: "janedoe", bio: "New bio details!", tags: ["lofi", "jazz"] }
  },
  {
    id: "users-delete",
    module: "Users",
    name: "Delete User",
    method: "DELETE",
    path: "/api/users/:id",
    description: "Deletes a user account.",
    auth: false,
    params: [
      { name: "id", type: "string", required: true, description: "User ID." }
    ],
    responseExample: { success: true, message: "User deleted successfully" }
  },
  {
    id: "users-like-song",
    module: "Users",
    name: "Like Song",
    method: "POST",
    path: "/api/users/liked-songs/:songId",
    description: "Adds a song to the authenticated user's liked list.",
    auth: true,
    params: [
      { name: "songId", type: "string", required: true, description: "ID of the song to like." }
    ],
    responseExample: { success: true, message: "Song liked" }
  },
  {
    id: "users-unlike-song",
    module: "Users",
    name: "Unlike Song",
    method: "DELETE",
    path: "/api/users/liked-songs/:songId",
    description: "Removes a song from the authenticated user's liked list.",
    auth: true,
    params: [
      { name: "songId", type: "string", required: true, description: "ID of the song to unlike." }
    ],
    responseExample: { success: true, message: "Song unliked" }
  },
  {
    id: "users-like-album",
    module: "Users",
    name: "Like Album",
    method: "POST",
    path: "/api/users/liked-albums/:albumId",
    description: "Adds an album to the authenticated user's liked list.",
    auth: true,
    params: [
      { name: "albumId", type: "string", required: true, description: "ID of the album to like." }
    ],
    responseExample: { success: true, message: "Album liked" }
  },
  {
    id: "users-unlike-album",
    module: "Users",
    name: "Unlike Album",
    method: "DELETE",
    path: "/api/users/liked-albums/:albumId",
    description: "Removes an album from the authenticated user's liked list.",
    auth: true,
    params: [
      { name: "albumId", type: "string", required: true, description: "ID of the album to unlike." }
    ],
    responseExample: { success: true, message: "Album unliked" }
  },
  {
    id: "users-join-room",
    module: "Users",
    name: "Join Listening Room",
    method: "POST",
    path: "/api/users/rooms/:roomId/join",
    description: "Allows the authenticated user to join a listening room.",
    auth: true,
    params: [
      { name: "roomId", type: "string", required: true, description: "ID of the room to join." }
    ],
    responseExample: { success: true, message: "Joined room" }
  },
  {
    id: "users-leave-room",
    module: "Users",
    name: "Leave Listening Room",
    method: "DELETE",
    path: "/api/users/rooms/:roomId/leave",
    description: "Allows the authenticated user to leave a listening room.",
    auth: true,
    params: [
      { name: "roomId", type: "string", required: true, description: "ID of the room to leave." }
    ],
    responseExample: { success: true, message: "Left room" }
  },

  // ==========================================
  // PLAYLISTS MODULE (/api/users/playlists)
  // ==========================================
  {
    id: "playlists-create",
    module: "Playlists",
    name: "Create Playlist",
    method: "POST",
    path: "/api/users/playlists",
    description: "Creates a new custom playlist for the authenticated user.",
    auth: true,
    body: [
      { name: "name", type: "string", required: true, description: "Name of the playlist." },
      { name: "thumbnail", type: "string", required: true, description: "URL to playlist thumbnail." },
      { name: "tags", type: "array of strings", required: true, description: "Array of tags describing genres/moods." },
      { name: "private", type: "boolean", required: true, description: "Whether the playlist is private to the user." }
    ],
    bodyExample: JSON.stringify({ name: "My Summer Vibez", thumbnail: "https://example.com/thumb.jpg", tags: ["chill", "summer"], private: false }, null, 2),
    responseExample: { id: "playlist_1", name: "My Summer Vibez", creatorId: "user_1", songs: [] }
  },
  {
    id: "playlists-update",
    module: "Playlists",
    name: "Update Playlist",
    method: "POST",
    path: "/api/users/playlists/:id",
    description: "Updates an existing playlist's details. Note: Uses POST method under the hood.",
    auth: true,
    params: [
      { name: "id", type: "string", required: true, description: "Playlist ID." }
    ],
    body: [
      { name: "name", type: "string", required: false, description: "New name." },
      { name: "thumbnail", type: "string", required: false, description: "New thumbnail URL." },
      { name: "tags", type: "array of strings", required: false, description: "New array of tags." },
      { name: "private", type: "boolean", required: false, description: "New privacy status." }
    ],
    bodyExample: JSON.stringify({ name: "My Updated Summer Vibez", private: true }, null, 2),
    responseExample: { id: "playlist_1", name: "My Updated Summer Vibez", private: true }
  },
  {
    id: "playlists-find-one",
    module: "Playlists",
    name: "Get Playlist Details",
    method: "GET",
    path: "/api/users/playlists/:id",
    description: "Retrieves metadata and song list of a specific playlist.",
    auth: true,
    params: [
      { name: "id", type: "string", required: true, description: "Playlist ID." }
    ],
    responseExample: { id: "playlist_1", name: "My Summer Vibez", songs: [{ id: "song_1", title: "Midnight Sun" }] }
  },
  {
    id: "playlists-add-song",
    module: "Playlists",
    name: "Add Song to Playlist",
    method: "POST",
    path: "/api/users/playlists/:id/songs",
    description: "Adds a song to the specified playlist.",
    auth: true,
    params: [
      { name: "id", type: "string", required: true, description: "Playlist ID." }
    ],
    body: [
      { name: "songId", type: "string", required: true, description: "ID of the song to add." }
    ],
    bodyExample: JSON.stringify({ songId: "song_123" }, null, 2),
    responseExample: { success: true, message: "Song added to playlist" }
  },

  // ==========================================
  // SONGS MODULE (/api/songs)
  // ==========================================
  {
    id: "songs-find-one",
    module: "Songs",
    name: "Get Song Details",
    method: "GET",
    path: "/api/songs/:id",
    description: "Retrieves metadata for a specific song, including artists and album associations.",
    auth: false,
    params: [
      { name: "id", type: "string", required: true, description: "Song ID." }
    ],
    responseExample: { id: "song_123", title: "After Hours", artistId: "art_1", albumId: "alb_1", durationSeconds: 240 }
  },
  {
    id: "songs-play",
    module: "Songs",
    name: "Stream Song Audio",
    method: "GET",
    path: "/api/songs/:id/play",
    description: "Retrieves the streaming audio URL or file details for a song.",
    auth: true,
    params: [
      { name: "id", type: "string", required: true, description: "Song ID to play." }
    ],
    responseExample: { audioUrl: "https://stream.vibez.app/songs/song_123.mp3", streamType: "mp3" }
  },
  {
    id: "songs-lyrics",
    module: "Songs",
    name: "Get Song Lyrics",
    method: "GET",
    path: "/api/songs/:id/lyrics",
    description: "Gets synchronized or plain-text lyrics for the song.",
    auth: true,
    params: [
      { name: "id", type: "string", required: true, description: "Song ID." }
    ],
    responseExample: { lyrics: "[00:12.50] In the middle of the night...\n[00:15.80] You call my name..." }
  },
  {
    id: "songs-related",
    module: "Songs",
    name: "Get Related Songs",
    method: "GET",
    path: "/api/songs/:id/related",
    description: "Retrieves recommended songs matching the mood/genre of the specified song.",
    auth: true,
    params: [
      { name: "id", type: "string", required: true, description: "Song ID." }
    ],
    responseExample: [
      { id: "song_456", title: "Save Your Tears", artist: "The Weeknd" }
    ]
  },
  {
    id: "songs-credits",
    module: "Songs",
    name: "Get Song Credits",
    method: "GET",
    path: "/api/songs/:id/credits",
    description: "Retrieves technical credits for a song (composers, producers, writers, mixing engineers).",
    auth: true,
    params: [
      { name: "id", type: "string", required: true, description: "Song ID." }
    ],
    responseExample: { producers: ["Max Martin"], writers: ["Abel Tesfaye"], mixing: ["Serban Ghenea"] }
  },

  // ==========================================
  // SEARCH MODULE (/api/search)
  // ==========================================
  {
    id: "search-query",
    module: "Search",
    name: "Search Catalog",
    method: "GET",
    path: "/api/search",
    description: "Searches the Vibez audio catalog for matching songs, artists, or albums.",
    auth: false,
    query: [
      { name: "q", type: "string", required: true, description: "Search query string." },
      { name: "filter", type: "string", required: false, description: "Filter results. Valid values: SONG, ARTIST, ALBUM." }
    ],
    responseExample: {
      songs: [{ id: "song_1", title: "Midnight City" }],
      artists: [{ id: "art_1", name: "M83" }],
      albums: []
    }
  },

  // ==========================================
  // ROOMS MODULE (/api/rooms)
  // ==========================================
  {
    id: "rooms-get-all",
    module: "Rooms",
    name: "List Rooms",
    method: "GET",
    path: "/api/rooms",
    description: "Gets all active listening rooms.",
    auth: false,
    responseExample: [
      { id: "room_1", name: "Lofi Chill Beats", description: "Studying vibez", currentListeners: 42 }
    ]
  },
  {
    id: "rooms-me",
    module: "Rooms",
    name: "Get My Rooms",
    method: "GET",
    path: "/api/rooms/me",
    description: "Retrieves a list of listening rooms created by the currently authenticated user.",
    auth: true,
    responseExample: [
      { id: "room_custom", name: "My Party Room", description: "Bangers only", private: false }
    ]
  },
  {
    id: "rooms-find-one",
    module: "Rooms",
    name: "Get Room Details",
    method: "GET",
    path: "/api/rooms/:id",
    description: "Retrieves connection details and user list for a specific room ID.",
    auth: true,
    params: [
      { name: "id", type: "string", required: true, description: "Room ID." }
    ],
    responseExample: { id: "room_1", name: "Lofi Chill Beats", creatorId: "user_9", activeUsers: ["user_1", "user_2"] }
  },
  {
    id: "rooms-create",
    module: "Rooms",
    name: "Create Room",
    method: "POST",
    path: "/api/rooms",
    description: "Creates a new listen-along room.",
    auth: true,
    body: [
      { name: "name", type: "string", required: true, description: "Name of the room." },
      { name: "description", type: "string", required: true, description: "Brief description of the room." },
      { name: "tags", type: "array of strings", required: true, description: "Array of tags for categorization." },
      { name: "private", type: "boolean", required: true, description: "Whether the room is password-protected or private." }
    ],
    bodyExample: JSON.stringify({ name: "Jazz Café", description: "Coffee shop jazz tunes", tags: ["jazz", "study"], private: false }, null, 2),
    responseExample: { id: "room_101", name: "Jazz Café", creatorId: "user_me", activeUsers: [] }
  },
  {
    id: "rooms-update",
    module: "Rooms",
    name: "Update Room",
    method: "PATCH",
    path: "/api/rooms/:id",
    description: "Updates room settings. Can only be done by the room creator.",
    auth: true,
    params: [
      { name: "id", type: "string", required: true, description: "Room ID to update." }
    ],
    body: [
      { name: "name", type: "string", required: false, description: "New room name." },
      { name: "description", type: "string", required: false, description: "New description." },
      { name: "tags", type: "array of strings", required: false, description: "New tags array." },
      { name: "private", type: "boolean", required: false, description: "New privacy status." }
    ],
    bodyExample: JSON.stringify({ description: "Updated coffee cafe jazz vibes" }, null, 2),
    responseExample: { id: "room_101", name: "Jazz Café", description: "Updated coffee cafe jazz vibes" }
  },
  {
    id: "rooms-delete",
    module: "Rooms",
    name: "Delete Room",
    method: "DELETE",
    path: "/api/rooms/:id",
    description: "Permanently deletes a listening room. Can only be done by the room creator.",
    auth: true,
    params: [
      { name: "id", type: "string", required: true, description: "Room ID to delete." }
    ],
    responseExample: { success: true, message: "Room deleted successfully" }
  },

  // ==========================================
  // ARTISTS MODULE (/api/artists)
  // ==========================================
  {
    id: "artists-find-one",
    module: "Artists",
    name: "Get Artist Details",
    method: "GET",
    path: "/api/artists/:id",
    description: "Retrieves profile page information for a musical artist, including top tracks and albums.",
    auth: false,
    params: [
      { name: "id", type: "string", required: true, description: "Artist ID." }
    ],
    responseExample: { id: "art_1", name: "The Weeknd", genres: ["R&B", "Pop"], followersCount: 15000000 }
  },

  // ==========================================
  // ALBUMS MODULE (/api/albums)
  // ==========================================
  {
    id: "albums-find-one",
    module: "Albums",
    name: "Get Album Details",
    method: "GET",
    path: "/api/albums/:id",
    description: "Retrieves metadata, artist credits, tracklisting, and release information for an album.",
    auth: false,
    params: [
      { name: "id", type: "string", required: true, description: "Album ID." }
    ],
    responseExample: { id: "alb_1", title: "After Hours", artistId: "art_1", tracksCount: 14, releaseYear: 2020 }
  }
];

// Active State
let activeEndpoint = endpoints[0];
let activeLang = "curl";

// DOM Elements
const searchEl = document.getElementById("search");
const navGroupsEl = document.getElementById("nav-groups");
const endpointsContainer = document.getElementById("endpoints-container");
const codeSnippetEl = document.getElementById("code-snippet");
const copyBtnEl = document.getElementById("copy-btn");
const dynamicInputsEl = document.getElementById("dynamic-inputs");
const btnSendRequest = document.getElementById("btn-send-request");
const btnResetSandbox = document.getElementById("btn-reset-sandbox");
const apiBaseUrlEl = document.getElementById("api-base-url");
const apiTokenEl = document.getElementById("api-token");
const responseBlock = document.getElementById("response-block");
const responseStatus = document.getElementById("response-status");
const responseTime = document.getElementById("response-time");
const responseJson = document.getElementById("response-json");
const hamburgerToggle = document.getElementById("hamburger-toggle");
const sidebarEl = document.getElementById("sidebar");

// Initialize LocalStorage values
if (localStorage.getItem("vibez_api_base_url")) {
  apiBaseUrlEl.value = localStorage.getItem("vibez_api_base_url");
}
if (localStorage.getItem("vibez_api_token")) {
  apiTokenEl.value = localStorage.getItem("vibez_api_token");
}

// Save inputs on change
apiBaseUrlEl.addEventListener("input", () => {
  localStorage.setItem("vibez_api_base_url", apiBaseUrlEl.value);
  updateSnippet();
});
apiTokenEl.addEventListener("input", () => {
  localStorage.setItem("vibez_api_token", apiTokenEl.value);
  updateSnippet();
});

// Render UI Components
function renderSidebar(filterQuery = "") {
  navGroupsEl.innerHTML = "";
  
  // Group endpoints by module
  const groups = {};
  endpoints.forEach(ep => {
    // Filter check
    if (filterQuery) {
      const query = filterQuery.toLowerCase();
      const matchName = ep.name.toLowerCase().includes(query);
      const matchPath = ep.path.toLowerCase().includes(query);
      const matchDesc = ep.description.toLowerCase().includes(query);
      const matchModule = ep.module.toLowerCase().includes(query);
      if (!matchName && !matchPath && !matchDesc && !matchModule) return;
    }

    if (!groups[ep.module]) {
      groups[ep.module] = [];
    }
    groups[ep.module].push(ep);
  });

  if (Object.keys(groups).length === 0) {
    navGroupsEl.innerHTML = `<div style="padding: 16px; color: var(--text-muted); font-size: 13px;">No endpoints found</div>`;
    return;
  }

  Object.entries(groups).forEach(([moduleName, eps]) => {
    const groupDiv = document.createElement("div");
    groupDiv.className = "nav-group";

    const groupTitle = document.createElement("div");
    groupTitle.className = "nav-group-title";
    groupTitle.innerText = moduleName;
    groupDiv.appendChild(groupTitle);

    const list = document.createElement("ul");
    list.className = "nav-list";

    eps.forEach(ep => {
      const item = document.createElement("li");
      item.className = "nav-item";

      const link = document.createElement("a");
      link.className = `nav-link ${activeEndpoint.id === ep.id ? "active" : ""}`;
      link.dataset.id = ep.id;
      
      const textSpan = document.createElement("span");
      textSpan.innerText = ep.name;
      link.appendChild(textSpan);

      const methodBadge = document.createElement("span");
      methodBadge.className = `badge ${ep.method.toLowerCase()}`;
      methodBadge.innerText = ep.method;
      link.appendChild(methodBadge);

      link.addEventListener("click", (e) => {
        e.preventDefault();
        selectEndpoint(ep.id);
        
        // Mobile menu close on click
        if (sidebarEl.classList.contains("open")) {
          sidebarEl.classList.remove("open");
        }
      });

      item.appendChild(link);
      list.appendChild(item);
    });

    groupDiv.appendChild(list);
    navGroupsEl.appendChild(groupDiv);
  });
}

function renderEndpoints(filterQuery = "") {
  endpointsContainer.innerHTML = "";
  
  endpoints.forEach(ep => {
    // Filter check
    if (filterQuery) {
      const query = filterQuery.toLowerCase();
      const matchName = ep.name.toLowerCase().includes(query);
      const matchPath = ep.path.toLowerCase().includes(query);
      const matchDesc = ep.description.toLowerCase().includes(query);
      const matchModule = ep.module.toLowerCase().includes(query);
      if (!matchName && !matchPath && !matchDesc && !matchModule) return;
    }

    const card = document.createElement("div");
    card.className = "endpoint-card";
    card.id = `card-${ep.id}`;
    if (activeEndpoint.id === ep.id) {
      card.style.borderColor = "var(--accent-primary)";
    }

    const header = document.createElement("div");
    header.className = "endpoint-header";

    const tag = document.createElement("span");
    tag.className = `method-tag ${ep.method.toLowerCase()}`;
    tag.innerText = ep.method;
    header.appendChild(tag);

    const pathSpan = document.createElement("span");
    pathSpan.className = "endpoint-path";
    pathSpan.innerText = ep.path;
    header.appendChild(pathSpan);

    if (ep.auth) {
      const authBadge = document.createElement("span");
      authBadge.className = "endpoint-auth-indicator";
      authBadge.innerHTML = `
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
        Auth Required
      `;
      header.appendChild(authBadge);
    }

    card.appendChild(header);

    const title = document.createElement("h2");
    title.innerText = ep.name;
    title.style.fontSize = "20px";
    title.style.marginBottom = "8px";
    card.appendChild(title);

    const desc = document.createElement("div");
    desc.className = "endpoint-description";
    desc.innerText = ep.description;
    card.appendChild(desc);

    // Headers Table
    if (ep.headers && ep.headers.length > 0) {
      const title = document.createElement("div");
      title.className = "section-title";
      title.innerText = "Headers";
      card.appendChild(title);
      card.appendChild(createParamsTable(ep.headers));
    }

    // Path Parameters Table
    if (ep.params && ep.params.length > 0) {
      const title = document.createElement("div");
      title.className = "section-title";
      title.innerText = "Path Parameters";
      card.appendChild(title);
      card.appendChild(createParamsTable(ep.params));
    }

    // Query Parameters Table
    if (ep.query && ep.query.length > 0) {
      const title = document.createElement("div");
      title.className = "section-title";
      title.innerText = "Query Parameters";
      card.appendChild(title);
      card.appendChild(createParamsTable(ep.query));
    }

    // Body Parameters Table
    if (ep.body && ep.body.length > 0) {
      const title = document.createElement("div");
      title.className = "section-title";
      title.innerText = "Request Body Fields";
      card.appendChild(title);
      card.appendChild(createParamsTable(ep.body));
    }

    // Response Preview
    if (ep.responseExample) {
      const respTitle = document.createElement("div");
      respTitle.className = "section-title";
      respTitle.innerText = "Response Preview";
      card.appendChild(respTitle);

      const codePre = document.createElement("pre");
      codePre.style.backgroundColor = "#05080f";
      codePre.style.padding = "16px";
      codePre.style.borderRadius = "8px";
      codePre.style.border = "1px solid var(--border-color)";
      codePre.style.fontSize = "12.5px";
      codePre.style.fontFamily = "var(--font-mono)";
      codePre.style.overflowX = "auto";
      codePre.innerText = JSON.stringify(ep.responseExample, null, 2);
      card.appendChild(codePre);
    }

    // Card click sets sandbox context
    card.addEventListener("click", () => {
      selectEndpoint(ep.id, false); // Don't scroll, user already clicked it
    });

    endpointsContainer.appendChild(card);
  });
}

function createParamsTable(paramsList) {
  const table = document.createElement("table");
  table.className = "param-table";

  table.innerHTML = `
    <thead>
      <tr>
        <th style="width: 25%">Field</th>
        <th style="width: 20%">Type</th>
        <th>Description</th>
      </tr>
    </thead>
    <tbody>
    </tbody>
  `;
  const tbody = table.querySelector("tbody");

  paramsList.forEach(p => {
    const tr = document.createElement("tr");

    const tdName = document.createElement("td");
    tdName.className = "param-name";
    tdName.innerHTML = `${p.name} ${p.required ? '<span class="param-required">*</span>' : '<span class="param-optional">optional</span>'}`;
    tr.appendChild(tdName);

    const tdType = document.createElement("td");
    tdType.className = "param-type";
    tdType.innerText = p.type;
    tr.appendChild(tdType);

    const tdDesc = document.createElement("td");
    tdDesc.className = "param-desc";
    tdDesc.innerText = p.description;
    tr.appendChild(tdDesc);

    tbody.appendChild(tr);
  });

  return table;
}

// Select an active endpoint
function selectEndpoint(id, triggerScroll = true) {
  const selected = endpoints.find(e => e.id === id);
  if (!selected) return;

  // Un-highlight previous
  const prevActiveCard = document.getElementById(`card-${activeEndpoint.id}`);
  if (prevActiveCard) prevActiveCard.style.borderColor = "var(--border-color)";

  activeEndpoint = selected;

  // Highlight new
  const activeCard = document.getElementById(`card-${id}`);
  if (activeCard) activeCard.style.borderColor = "var(--accent-primary)";

  // Update Sidebar active state
  document.querySelectorAll(".nav-link").forEach(link => {
    if (link.dataset.id === id) {
      link.classList.add("active");
    } else {
      link.classList.remove("active");
    }
  });

  if (triggerScroll && activeCard) {
    activeCard.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  // Populate dynamic inputs in Explorer
  renderSandboxInputs();

  // Update code snippets
  updateSnippet();

  // Reset Response
  responseBlock.style.display = "none";
}

// Render dynamic sandbox input controls
function renderSandboxInputs() {
  dynamicInputsEl.innerHTML = "";

  // 1. Path Params
  if (activeEndpoint.params && activeEndpoint.params.length > 0) {
    const grp = document.createElement("div");
    grp.innerHTML = `<h4 style="font-size:12px; margin-top: 12px; margin-bottom: 8px; color: var(--text-primary); text-transform:uppercase;">Path Variables</h4>`;
    activeEndpoint.params.forEach(p => {
      const fieldDiv = document.createElement("div");
      fieldDiv.className = "explorer-input-group";
      fieldDiv.innerHTML = `
        <label class="explorer-label">${p.name} <span style="color:var(--color-delete)">*</span></label>
        <input type="text" class="explorer-input sandbox-path-input" data-param-name="${p.name}" placeholder="${p.description}" value="test_${p.name}">
      `;
      // Update snippet on change
      fieldDiv.querySelector("input").addEventListener("input", updateSnippet);
      grp.appendChild(fieldDiv);
    });
    dynamicInputsEl.appendChild(grp);
  }

  // 2. Query Params
  if (activeEndpoint.query && activeEndpoint.query.length > 0) {
    const grp = document.createElement("div");
    grp.innerHTML = `<h4 style="font-size:12px; margin-top: 12px; margin-bottom: 8px; color: var(--text-primary); text-transform:uppercase;">Query Parameters</h4>`;
    activeEndpoint.query.forEach(q => {
      const fieldDiv = document.createElement("div");
      fieldDiv.className = "explorer-input-group";
      fieldDiv.innerHTML = `
        <label class="explorer-label">${q.name} ${q.required ? '<span style="color:var(--color-delete)">*</span>' : '<span style="color:var(--text-muted)">(optional)</span>'}</label>
        <input type="text" class="explorer-input sandbox-query-input" data-query-name="${q.name}" placeholder="${q.description}">
      `;
      fieldDiv.querySelector("input").addEventListener("input", updateSnippet);
      grp.appendChild(fieldDiv);
    });
    dynamicInputsEl.appendChild(grp);
  }

  // 3. Request Body Textarea
  if (activeEndpoint.body && activeEndpoint.body.length > 0) {
    const grp = document.createElement("div");
    grp.innerHTML = `<h4 style="font-size:12px; margin-top: 12px; margin-bottom: 8px; color: var(--text-primary); text-transform:uppercase;">Request Body (JSON)</h4>`;
    
    const fieldDiv = document.createElement("div");
    fieldDiv.className = "explorer-input-group";
    
    const textarea = document.createElement("textarea");
    textarea.className = "explorer-textarea";
    textarea.id = "sandbox-body-json";
    textarea.value = activeEndpoint.bodyExample || "{\n  \n}";
    textarea.addEventListener("input", updateSnippet);
    
    fieldDiv.appendChild(textarea);
    grp.appendChild(fieldDiv);
    dynamicInputsEl.appendChild(grp);
  }
}

// Generate code snippet dynamically
function updateSnippet() {
  const base = apiBaseUrlEl.value.replace(/\/$/, "");
  const token = apiTokenEl.value.trim();

  // Gather values
  const pathParams = {};
  document.querySelectorAll(".sandbox-path-input").forEach(el => {
    pathParams[el.dataset.paramName] = el.value || `:${el.dataset.paramName}`;
  });

  const queryParams = {};
  document.querySelectorAll(".sandbox-query-input").forEach(el => {
    if (el.value) {
      queryParams[el.dataset.queryName] = el.value;
    }
  });

  let bodyVal = "";
  const bodyEl = document.getElementById("sandbox-body-json");
  if (bodyEl) {
    bodyVal = bodyEl.value;
  }

  // Construct absolute URL
  let resolvedPath = activeEndpoint.path;
  Object.entries(pathParams).forEach(([k, v]) => {
    resolvedPath = resolvedPath.replace(`:${k}`, encodeURIComponent(v));
  });

  const queryKeys = Object.keys(queryParams);
  let resolvedUrl = base + resolvedPath;
  if (queryKeys.length > 0) {
    const queryStr = queryKeys.map(k => `${encodeURIComponent(k)}=${encodeURIComponent(queryParams[k])}`).join("&");
    resolvedUrl += `?${queryStr}`;
  }

  // Generate for active language
  if (activeLang === "curl") {
    let curl = `curl -X ${activeEndpoint.method} "${resolvedUrl}"`;
    if (token) {
      curl += ` \\\n  -H "Authorization: Bearer ${token}"`;
    }
    if (activeEndpoint.headers) {
      activeEndpoint.headers.forEach(h => {
        curl += ` \\\n  -H "${h.name}: value"`;
      });
    }
    if (bodyVal && bodyVal.trim() !== "{}" && bodyVal.trim() !== "") {
      curl += ` \\\n  -H "Content-Type: application/json" \\\n  -d '${bodyVal.replace(/\n/g, "").replace(/\s+/g, " ")}'`;
    }
    codeSnippetEl.innerText = curl;
  } else if (activeLang === "javascript") {
    const headers = { "Content-Type": "application/json" };
    if (token) {
      headers["Authorization"] = `Bearer ${token}`;
    }
    let options = {
      method: activeEndpoint.method,
      headers
    };
    if (bodyVal && bodyVal.trim() !== "{}" && bodyVal.trim() !== "") {
      try {
        options.body = JSON.parse(bodyVal);
      } catch (e) {
        options.body = "INVALID_JSON";
      }
    }
    let codeStr = `fetch("${resolvedUrl}", {\n`;
    codeStr += `  method: "${options.method}",\n`;
    codeStr += `  headers: {\n`;
    Object.entries(headers).forEach(([k, v]) => {
      codeStr += `    "${k}": "${v}",\n`;
    });
    codeStr += `  }${options.body ? `,\n  body: JSON.stringify(${JSON.stringify(options.body, null, 4).replace(/\n/g, "\n  ")})` : ""}\n`;
    codeStr += `})\n.then(response => response.json())\n.then(data => console.log(data))\n.catch(error => console.error("Error:", error));`;
    codeSnippetEl.innerText = codeStr;
  } else if (activeLang === "dart") {
    let dart = `import 'dart:convert';\nimport 'package:http/http.dart' as http;\n\nvoid callApi() async {\n  final url = Uri.parse('${resolvedUrl}');\n`;
    const headers = { 'Content-Type': 'application/json' };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    
    dart += `  final headers = {\n`;
    Object.entries(headers).forEach(([k, v]) => {
      dart += `    '${k}': '${v}',\n`;
    });
    dart += `  };\n\n`;

    if (bodyVal && bodyVal.trim() !== "{}" && bodyVal.trim() !== "") {
      dart += `  final body = jsonEncode(${bodyVal.replace(/\n/g, "\n  ")});\n`;
    }

    const m = activeEndpoint.method.toLowerCase();
    if (m === "get") {
      dart += `  final response = await http.get(url, headers: headers);\n`;
    } else if (m === "post") {
      dart += `  final response = await http.post(url, headers: headers, body: ${bodyVal ? 'body' : 'null'});\n`;
    } else if (m === "patch") {
      dart += `  final response = await http.patch(url, headers: headers, body: ${bodyVal ? 'body' : 'null'});\n`;
    } else if (m === "delete") {
      dart += `  final response = await http.delete(url, headers: headers);\n`;
    }
    
    dart += `\n  if (response.statusCode == 200) {\n    final data = jsonDecode(response.body);\n    print(data);\n  } else {\n    print('Request failed: \${response.statusCode}');\n  }\n}`;
    codeSnippetEl.innerText = dart;
  } else if (activeLang === "python") {
    let py = `import requests\nimport json\n\nurl = "${resolvedUrl}"\n`;
    const headers = { 'Content-Type': 'application/json' };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    
    py += `headers = {\n`;
    Object.entries(headers).forEach(([k, v]) => {
      py += `    "${k}": "${v}",\n`;
    });
    py += `}\n\n`;

    if (bodyVal && bodyVal.trim() !== "{}" && bodyVal.trim() !== "") {
      py += `payload = ${bodyVal}\n\n`;
    }

    const m = activeEndpoint.method.toUpperCase();
    if (m === "GET") {
      py += `response = requests.get(url, headers=headers)\n`;
    } else if (m === "POST") {
      py += `response = requests.post(url, headers=headers, json=${bodyVal ? 'payload' : 'None'})\n`;
    } else if (m === "PATCH") {
      py += `response = requests.patch(url, headers=headers, json=${bodyVal ? 'payload' : 'None'})\n`;
    } else if (m === "DELETE") {
      py += `response = requests.delete(url, headers=headers)\n`;
    }
    
    py += `\ntry:\n    print(response.json())\nexcept Exception:\n    print(response.text)`;
    codeSnippetEl.innerText = py;
  }
}

// Execute request through sandbox
async function executeRequest() {
  const base = apiBaseUrlEl.value.replace(/\/$/, "");
  const token = apiTokenEl.value.trim();

  // Gather path variables
  const pathParams = {};
  document.querySelectorAll(".sandbox-path-input").forEach(el => {
    pathParams[el.dataset.paramName] = el.value.trim();
  });

  // Gather query parameters
  const queryParams = {};
  document.querySelectorAll(".sandbox-query-input").forEach(el => {
    if (el.value.trim()) {
      queryParams[el.dataset.queryName] = el.value.trim();
    }
  });

  // Resolve path
  let resolvedPath = activeEndpoint.path;
  let hasMissingParam = false;
  Object.entries(pathParams).forEach(([k, v]) => {
    if (!v) {
      hasMissingParam = true;
    }
    resolvedPath = resolvedPath.replace(`:${k}`, encodeURIComponent(v));
  });

  if (hasMissingParam) {
    alert("Please fill in all required path parameters.");
    return;
  }

  // Resolve full query URL
  let resolvedUrl = base + resolvedPath;
  const qKeys = Object.keys(queryParams);
  if (qKeys.length > 0) {
    const qStr = qKeys.map(k => `${encodeURIComponent(k)}=${encodeURIComponent(queryParams[k])}`).join("&");
    resolvedUrl += `?${qStr}`;
  }

  // Prep headers
  const headers = {
    "Accept": "application/json"
  };
  if (token) {
    headers["Authorization"] = token.startsWith("Bearer ") ? token : `Bearer ${token}`;
  }

  let body = undefined;
  const bodyEl = document.getElementById("sandbox-body-json");
  if (bodyEl) {
    const bodyStr = bodyEl.value.trim();
    if (bodyStr && bodyStr !== "{}") {
      try {
        JSON.parse(bodyStr); // validate JSON
        body = bodyStr;
        headers["Content-Type"] = "application/json";
      } catch (e) {
        alert("Invalid JSON format in request body.");
        return;
      }
    }
  }

  // UI state
  btnSendRequest.disabled = true;
  btnSendRequest.innerText = "Sending...";
  responseBlock.style.display = "none";

  const startTime = performance.now();

  try {
    const res = await fetch(resolvedUrl, {
      method: activeEndpoint.method,
      headers,
      body
    });

    const duration = Math.round(performance.now() - startTime);
    const isJson = res.headers.get("content-type")?.includes("application/json");
    
    let responseText = "";
    if (isJson) {
      const data = await res.json();
      responseText = JSON.stringify(data, null, 2);
    } else {
      responseText = await res.text();
    }

    // Status classes
    responseStatus.innerText = `${res.status} ${res.statusText}`;
    if (res.status >= 200 && res.status < 300) {
      responseStatus.className = "meta-pill status-success";
    } else {
      responseStatus.className = "meta-pill status-error";
    }

    responseTime.innerText = `${duration}ms`;
    responseJson.innerText = responseText;
    responseBlock.style.display = "block";
  } catch (error) {
    const duration = Math.round(performance.now() - startTime);
    responseStatus.innerText = "Connection Failed";
    responseStatus.className = "meta-pill status-error";
    responseTime.innerText = `${duration}ms`;
    responseJson.innerText = `Network Error:\nUnable to connect to the server at ${resolvedUrl}.\n\nSuggestions:\n1. Ensure the backend API server is running.\n2. Verify the Base URL is correct.\n3. Make sure CORS is enabled on the server.\n\nDetails: ${error.message}`;
    responseBlock.style.display = "block";
  } finally {
    btnSendRequest.disabled = false;
    btnSendRequest.innerHTML = `
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>
      Send Request
    `;
  }
}

// Reset sandbox to defaults
function resetSandbox() {
  renderSandboxInputs();
  updateSnippet();
  responseBlock.style.display = "none";
}

// Sidebar Scroll Spy (highlight closest endpoint card on scroll)
let isScrolling = null;
function handleScrollSpy() {
  const cards = document.querySelectorAll(".endpoint-card");
  let closestCard = null;
  let minDistance = Infinity;

  cards.forEach(card => {
    const rect = card.getBoundingClientRect();
    const distance = Math.abs(rect.top - 80); // Offset header/padding
    if (distance < minDistance) {
      minDistance = distance;
      closestCard = card;
    }
  });

  if (closestCard) {
    const epId = closestCard.id.replace("card-", "");
    if (activeEndpoint.id !== epId) {
      // Light highlight update in sidebar without changing code inputs
      document.querySelectorAll(".nav-link").forEach(link => {
        if (link.dataset.id === epId) {
          link.classList.add("active");
        } else {
          link.classList.remove("active");
        }
      });
      // Soft change background border
      document.querySelectorAll(".endpoint-card").forEach(c => {
        c.style.borderColor = c.id === closestCard.id ? "var(--accent-primary)" : "var(--border-color)";
      });
      
      // Keep active state matching scroll
      activeEndpoint = endpoints.find(e => e.id === epId);
    }
  }
}

// Copy Code Snippet
function copyCode() {
  const text = codeSnippetEl.innerText;
  navigator.clipboard.writeText(text).then(() => {
    copyBtnEl.innerText = "Copied!";
    setTimeout(() => {
      copyBtnEl.innerText = "Copy";
    }, 2000);
  }).catch(err => {
    console.error("Failed to copy text: ", err);
  });
}

// Set up event listeners
searchEl.addEventListener("input", (e) => {
  const query = e.target.value;
  renderSidebar(query);
  renderEndpoints(query);
});

document.querySelectorAll(".tab-btn").forEach(btn => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".tab-btn").forEach(b => b.classList.remove("active"));
    btn.classList.add("active");
    activeLang = btn.dataset.lang;
    updateSnippet();
  });
});

copyBtnEl.addEventListener("click", copyCode);
btnSendRequest.addEventListener("click", executeRequest);
btnResetSandbox.addEventListener("click", resetSandbox);

// Mobile Hamburger Toggle
hamburgerToggle.addEventListener("click", () => {
  sidebarEl.classList.toggle("open");
});

// Window Scroll Listener for Scroll Spy
document.getElementById("endpoints-container").addEventListener("scroll", () => {
  clearTimeout(isScrolling);
  isScrolling = setTimeout(handleScrollSpy, 80);
});

// Initialize on page load
renderSidebar();
renderEndpoints();
selectEndpoint(endpoints[0].id);
