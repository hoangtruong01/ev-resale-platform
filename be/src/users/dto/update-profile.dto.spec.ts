import { validate } from 'class-validator';
import { UpdateProfileDto } from './update-profile.dto';

describe('UpdateProfileDto', () => {
  it('accepts editable profile fields', async () => {
    const dto = Object.assign(new UpdateProfileDto(), {
      fullName: 'Nguyen Bao Duy',
      phone: '0901234567',
      streetAddress: '123 Nguyen Van Linh',
    });

    await expect(validate(dto)).resolves.toHaveLength(0);
  });

  it('allows an empty phone so users can remove it', async () => {
    const dto = Object.assign(new UpdateProfileDto(), {
      fullName: 'Nguyen Bao Duy',
      phone: '',
    });

    await expect(validate(dto)).resolves.toHaveLength(0);
  });

  it('rejects an invalid full name and phone number', async () => {
    const dto = Object.assign(new UpdateProfileDto(), {
      fullName: 'D',
      phone: '123',
    });

    const errors = await validate(dto);
    expect(errors.map((error) => error.property)).toEqual(
      expect.arrayContaining(['fullName', 'phone']),
    );
  });
});
