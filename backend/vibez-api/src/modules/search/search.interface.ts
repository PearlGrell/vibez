import { Observable } from 'rxjs';

export enum Filter {
  ALL = 0,
  SONG = 1,
  ARTIST = 2,
  ALBUM = 3,
}

export enum SearchType {
  ALL = 'all',
  SONG = 'song',
  ARTIST = 'artist',
  ALBUM = 'album',
  PLAYLIST = 'playlist',
  ROOM = 'room',
  USER = 'user',
}

export interface SearchRequest {
  query: string;
  filter: Filter;
  limit: number;
}

export interface SearchSong {
  id: string;
  title: string;
  album: string;
  artists: string;
  duration: number;
  thumbnail: string;
}

export interface SearchArtist {
  id: string;
  name: string;
  thumbnail: string;
}

export interface SearchAlbum {
  id: string;
  title: string;
  artists: string;
  thumbnail: string;
  type: string;
  year: string;
}

export interface SearchResult {
  songs: SearchSong[];
  artists: SearchArtist[];
  albums: SearchAlbum[];
}

export interface SearchGrpcService {
  Search(data: SearchRequest): Observable<SearchResult>;
}
