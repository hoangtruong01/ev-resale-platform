import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { FirebaseService } from './firebase.service';
import { ServiceAccount } from 'firebase-admin';
@Module({
  imports: [ConfigModule],
  providers: [
    {
      provide: 'FIREBASE_ADMIN',
      useFactory: (configService: ConfigService) => {
        const firebaseConfig: ServiceAccount = {
          projectId: configService.get<string>('FIREBASE_PROJECT_ID')!,
          clientEmail: configService.get<string>('FIREBASE_CLIENT_EMAIL')!,
          privateKey: configService
            .get<string>('FIREBASE_PRIVATE_KEY')!
            .replace(/\\n/g, '\n'),
        };

        if (!admin.apps.length) {
          admin.initializeApp({
            credential: admin.credential.cert(firebaseConfig),
          });
        }

        if (!admin.apps.length) {
          admin.initializeApp({
            credential: admin.credential.cert(firebaseConfig),
          });
        }

        return admin;
      },
      inject: [ConfigService],
    },
    FirebaseService,
  ],
  exports: ['FIREBASE_ADMIN', FirebaseService],
})
export class FirebaseModule { }
