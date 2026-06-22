import { Observable } from 'rxjs';

export interface SongRequest {
  id: string;
}

export interface SongArtist {
  id: string;
  name: string;
}

export interface SongResponse {
  id: string;
  title: string;
  artists: SongArtist[];
  album: string;
  albumId: string;
  duration: number;
  thumbnail: string;
  year: string;
}

export interface AudioRequest {
  id: string;
}

export interface AudioResponse {
  id: string;
  playbackUrl: string;
  mimeType: string;
}

export interface LyricsRequest {
  id: string;
}

export interface LyricBlock {
  text: string;
  startTime: number;
  endTime: number;
}

export interface LyricsResponse {
  lyrics: LyricBlock[];
  source: string;
  hasTimestamps: boolean;
}

export interface RelatedRequest {
  id: string;
  limit: number;
}

export interface RelatedSongs {
  id: string;
  title: string;
  thumbnail: string;
  artists: string;
}

export interface RelatedResponse {
  related: RelatedSongs[];
}

export interface CreditsRequest {
  id: string;
}

export interface CreditEntity {
  name: string;
  id: string;
}

export interface Credit {
  role: string;
  entities: CreditEntity[];
}

export interface CreditsResponse {
  credits: Credit[];
}

export interface SongGrpcService {
  Song(data: SongRequest): Observable<SongResponse>;
  Audio(data: AudioRequest): Observable<AudioResponse>;
  Lyrics(data: LyricsRequest): Observable<LyricsResponse>;
  Related(data: RelatedRequest): Observable<RelatedResponse>;
  Credits(data: CreditsRequest): Observable<CreditsResponse>;
}

