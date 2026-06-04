import { Injectable, Logger } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, VerifyCallback } from 'passport-google-oauth20';
import { AuthService } from './auth.service';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  private readonly logger = new Logger(GoogleStrategy.name);

  constructor(private authService: AuthService) {
    super({
      clientID: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      callbackURL: process.env.GOOGLE_CALLBACK_URL!,
      scope: ['email', 'profile'],
    });
  }

  async validate(
    accessToken: string,
    refreshToken: string,
    profile: any,
    done: VerifyCallback,
  ): Promise<any> {
    try {
      this.logger.log(`Validating Google OAuth profile for user: ${profile?.id}`);
      
      const { id, name, emails, photos } = profile;

      const email = emails && emails.length > 0 ? emails[0].value : '';
      const firstName = name ? (name.givenName || '') : '';
      const lastName = name ? (name.familyName || '') : '';
      const picture = photos && photos.length > 0 ? photos[0].value : '';

      if (!email) {
        throw new Error('Google profile does not contain an email address.');
      }

      const user = {
        googleId: id,
        email,
        firstName,
        lastName,
        picture,
        accessToken,
      };

      const validatedUser = await this.authService.validateGoogleUser(user);
      done(null, validatedUser);
    } catch (error) {
      this.logger.error('Error validating Google OAuth user:', error.stack || error.message || error);
      done(error, null);
    }
  }
}

