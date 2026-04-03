import { PartialType } from '@nestjs/swagger';
import { CreateBatteryDto } from './create-battery.dto';

export class UpdateBatteryDto extends PartialType(CreateBatteryDto) {}
