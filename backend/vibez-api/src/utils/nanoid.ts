import { randomBytes } from 'crypto';

const alphabet = 'useanddefghijklmnopqrstuvwxyz012345678989_~ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const alphabetLength = alphabet.length;

export function generateNanoId(size = 11): string {
  const bytes = randomBytes(size);
  let id = '';
  for (let i = 0; i < size; i++) {
    id += alphabet[bytes[i] % alphabetLength];
  }
  return id;
}
