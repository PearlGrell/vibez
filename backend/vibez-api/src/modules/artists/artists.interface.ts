import { Observable } from 'rxjs';

export interface ArtistRequest {
  id: string;
}

export interface ArtistBrowseRequest {
  channelId: string;
  browseId: string;
  params: string;
}

export interface ArtistSongArtist {
  id: string;
  name: string;
}

export interface ArtistSong {
  id: string;
  title: string;
  artists: ArtistSongArtist[];
  album: string;
  albumId: string;
  thumbnail: string;
  duration: number;
}

export interface ArtistAlbum {
  id: string;
  title: string;
  thumbnail: string;
  type: string;
  year: string;
}

export interface ArtistSingle {
  id: string;
  title: string;
  thumbnail: string;
  type: string;
  year: string;
}

export interface ArtistVideo {
  id: string;
  title: string;
  thumbnail: string;
  views: string;
}

export interface RelatedArtist {
  id: string;
  name: string;
  thumbnail: string;
  subscribers: string;
}

export interface ArtistResponse {
  id: string;
  name: string;
  description: string;
  views: string;
  subscribers: string;
  monthlyListeners: string;
  thumbnail: string;
  songs: ArtistSong[];
  albums: ArtistAlbum[];
  singles: ArtistSingle[];
  videos: ArtistVideo[];
  related: RelatedArtist[];
  songsBrowseId: string;
  albumsBrowseId: string;
  albumsParams: string;
}

export interface ArtistSongsResponse {
  songs: ArtistSong[];
}

export interface ArtistAlbumsResponse {
  albums: ArtistAlbum[];
}

export interface ArtistGrpcService {
  Artist(data: ArtistRequest): Observable<ArtistResponse>;
  ArtistSongs(data: ArtistBrowseRequest): Observable<ArtistSongsResponse>;
  ArtistAlbums(data: ArtistBrowseRequest): Observable<ArtistAlbumsResponse>;
}
