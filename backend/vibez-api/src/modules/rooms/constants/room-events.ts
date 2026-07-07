export const RoomEvents = {
  ROOMS: 'rooms',
  JOIN: 'room:join',
  LEAVE: 'room:leave',
  USER_JOINED: 'room:user_joined',
  USER_LEFT: 'room:user_left',

  DETAILS: 'room:details',
  QUEUE: 'room:queue',
  STOP_SONG: 'room:stop',

  ADD_SONG: 'room:add_song',
  REMOVE_SONG: 'room:remove_song',
  SONG_ADDED: 'room:song_added',
  SONG_REMOVED: 'room:song_removed',

  REQUEST_DJ: 'room:request_dj',
  DJ_REQUESTED: 'room:dj_requested',
  JOIN_DJ: 'room:join_dj',
  DJ_JOINED: 'room:dj_joined',
  LEAVE_DJ: 'room:leave_dj',
  DJ_LEFT: 'room:dj_left',
  ASSIGN_DJ: 'room:assign_dj',
  DJ_ASSIGNED: 'room:dj_assigned',
  
  REQUEST_SONG: 'room:request_song',
  SONG_REQUESTED: 'room:song_requested',
  
  SONG_CHANGED: 'room:song_changed',
  STATE_UPDATE: 'room:state_update',
  QUEUE_UPDATE: 'room:queue_update',
  ROOMS_UPDATE: 'rooms:update',

  SEND_MESSAGE: 'room:send_message',
  MESSAGES_SENT: 'room:messages_sent'
};
