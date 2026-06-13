import { Injectable, Inject, UnauthorizedException } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService {
  constructor(@Inject('FIREBASE_ADMIN') private firebaseAdmin: any) {}

  /**
   * Verify Firebase ID Token
   * @param idToken - Firebase ID token from client
   * @returns Decoded token payload
   */
  async verifyIdToken(idToken: string): Promise<admin.auth.DecodedIdToken> {
    try {
      const decodedToken = await this.firebaseAdmin.auth().verifyIdToken(idToken);
      return decodedToken;
    } catch (error) {
      console.error('Firebase ID token verification failed:', error);
      throw new UnauthorizedException('Invalid Firebase ID token');
    }
  }

  /**
   * Get user by Firebase UID
   * @param uid - Firebase user ID
   * @returns Firebase user record
   */
  async getUserByUid(uid: string): Promise<admin.auth.UserRecord> {
    try {
      return await this.firebaseAdmin.auth().getUser(uid);
    } catch (error) {
      console.error('Failed to get Firebase user:', error);
      throw new UnauthorizedException('Firebase user not found');
    }
  }

  /**
   * Revoke Firebase user refresh tokens
   * @param uid - Firebase user ID
   */
  async revokeRefreshTokens(uid: string): Promise<void> {
    try {
      await this.firebaseAdmin.auth().revokeRefreshTokens(uid);
    } catch (error) {
      console.error('Failed to revoke refresh tokens:', error);
    }
  }
}
