import { UsersService } from './users.service';

describe('UsersService profile avatar', () => {
  const user = {
    id: 'user-1',
    email: 'duy@example.com',
    fullName: 'Nguyen Bao Duy',
    name: 'Nguyen Bao Duy',
    avatar: '/uploads/avatars/new-avatar.jpg',
    role: 'USER',
    isProfileComplete: true,
    phone: '0901234567',
    address: 'Ho Chi Minh City',
    rating: null,
    totalRatings: 0,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  let prisma: {
    user: {
      findUnique: jest.Mock;
      update: jest.Mock;
    };
  };
  let service: UsersService;

  beforeEach(() => {
    prisma = {
      user: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
    };
    service = new UsersService(prisma as never);
  });

  it('updates the avatar and returns fields required by the mobile profile', async () => {
    prisma.user.findUnique.mockResolvedValue({
      ...user,
      avatar: null,
    });
    prisma.user.update.mockResolvedValue(user);

    await expect(service.updateAvatar(user.id, user.avatar)).resolves.toEqual(
      user,
    );

    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: user.id },
        data: { avatar: user.avatar },
        select: expect.objectContaining({
          phone: true,
          address: true,
          rating: true,
          totalRatings: true,
        }),
      }),
    );
  });

  it('removes the avatar without deleting non-local provider images', async () => {
    prisma.user.findUnique.mockResolvedValue({
      avatar: 'https://example.com/google-avatar.jpg',
    });
    prisma.user.update.mockResolvedValue({
      ...user,
      avatar: null,
    });

    await expect(service.removeAvatar(user.id)).resolves.toEqual({
      ...user,
      avatar: null,
    });

    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: user.id },
        data: { avatar: null },
      }),
    );
  });
});
