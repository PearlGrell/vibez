import { Observable } from 'rxjs';

export interface AlbumRequest {
  id: string;
}

export interface AlbumArtist {
  id: string;
  name: string;
}

export interface AlbumTrack {
  videoId: string;
  title: string;
  artists: AlbumArtist[];
  album: string;
  durationSeconds: number;
  thumbnail: string;
  isExplicit: boolean;
  trackNumber: number;
}

export interface AlbumVersion {
  id: string;
  title: string;
  artists: AlbumArtist[];
  thumbnail: string;
  isExplicit: boolean;
  type: string;
}

export interface RelatedAlbum {
  id: string;
  title: string;
  artists: AlbumArtist[];
  thumbnail: string;
  isExplicit: boolean;
  type: string;
}

export interface AlbumResponse {
  id: string;
  title: string;
  type: string;
  thumbnail: string;
  isExplicit: boolean;
  description: string;
  year: string;
  artists: AlbumArtist[];
  trackCount: number;
  durationSeconds: number;
  tracks: AlbumTrack[];
  otherVersions: AlbumVersion[];
  relatedAlbums: RelatedAlbum[];
}

export interface AlbumGrpcService {
  Album(data: AlbumRequest): Observable<AlbumResponse>;
}
