import { PartialType } from '@nestjs/swagger';
import { CreateAccessoryDto } from './create-accessory.dto';

export class UpdateAccessoryDto extends PartialType(CreateAccessoryDto) {}
