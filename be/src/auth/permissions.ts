export const MODERATOR_PERMISSIONS = [
  'MODERATE_POSTS',
  'HANDLE_SUPPORT_TICKETS',
  'MARK_SPAM',
] as const;

export type ModeratorPermission = (typeof MODERATOR_PERMISSIONS)[number];

export const moderatorPermissionSet = new Set<string>(MODERATOR_PERMISSIONS);

export const normalizePermissions = (
  permissions: unknown,
): ModeratorPermission[] => {
  if (!Array.isArray(permissions)) {
    return [];
  }

  const normalized = permissions
    .map((permission) =>
      String(permission || '')
        .trim()
        .toUpperCase(),
    )
    .filter((permission) => moderatorPermissionSet.has(permission));

  return Array.from(new Set(normalized)) as ModeratorPermission[];
};
