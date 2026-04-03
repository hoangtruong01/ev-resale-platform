import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSettingDto, UpdateSettingDto } from './dto';
import { Settings } from '@prisma/client';

@Injectable()
export class SettingsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(createSettingDto: CreateSettingDto): Promise<Settings> {
    return this.prisma.settings.create({
      data: createSettingDto,
    });
  }

  async findAll(): Promise<Settings[]> {
    return this.prisma.settings.findMany();
  }

  async findOne(key: string): Promise<Settings> {
    const setting = await this.prisma.settings.findUnique({
      where: { key },
    });

    if (!setting) {
      throw new NotFoundException(`Setting with key '${key}' not found`);
    }

    return setting;
  }

  async update(
    key: string,
    updateSettingDto: UpdateSettingDto,
  ): Promise<Settings> {
    try {
      return await this.prisma.settings.update({
        where: { key },
        data: updateSettingDto,
      });
    } catch (error) {
      throw new NotFoundException(`Setting with key '${key}' not found`);
    }
  }

  async remove(key: string): Promise<Settings> {
    try {
      return await this.prisma.settings.delete({
        where: { key },
      });
    } catch (error) {
      throw new NotFoundException(`Setting with key '${key}' not found`);
    }
  }

  // Utility method to get setting value by key
  async getValue(key: string): Promise<string> {
    const setting = await this.findOne(key);
    return setting.value;
  }
}
