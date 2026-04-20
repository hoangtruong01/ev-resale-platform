import { SetMetadata } from '@nestjs/common';
import type { ModeratorPermission } from './permissions';

export const PERMISSIONS_KEY = 'permissions';
export const Permissions = (...permissions: ModeratorPermission[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);
