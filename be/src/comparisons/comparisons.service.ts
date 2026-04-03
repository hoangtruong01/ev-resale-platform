import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateComparisonDto, UpdateComparisonDto } from './dto';

@Injectable()
export class ComparisonsService {
  constructor(private prisma: PrismaService) {}

  async create(createComparisonDto: CreateComparisonDto) {
    const { name, vehicleIds, batteryIds } = createComparisonDto;

    // Check if at least one of vehicleIds or batteryIds is provided
    if (
      (!vehicleIds || vehicleIds.length === 0) &&
      (!batteryIds || batteryIds.length === 0)
    ) {
      throw new BadRequestException(
        'Ít nhất một xe hoặc một pin phải được chọn để so sánh',
      );
    }

    // Validate that all vehicle IDs exist
    if (vehicleIds && vehicleIds.length > 0) {
      const vehicles = await this.prisma.vehicle.findMany({
        where: {
          id: { in: vehicleIds },
        },
      });

      if (vehicles.length !== vehicleIds.length) {
        throw new NotFoundException('Một hoặc nhiều xe không tồn tại');
      }
    }

    // Validate that all battery IDs exist
    if (batteryIds && batteryIds.length > 0) {
      const batteries = await this.prisma.battery.findMany({
        where: {
          id: { in: batteryIds },
        },
      });

      if (batteries.length !== batteryIds.length) {
        throw new NotFoundException('Một hoặc nhiều pin không tồn tại');
      }
    }

    // Create the comparison
    const comparison = await this.prisma.comparison.create({
      data: {
        name,
      },
    });

    // Connect vehicles
    if (vehicleIds && vehicleIds.length > 0) {
      await this.prisma.comparison.update({
        where: { id: comparison.id },
        data: {
          vehicles: {
            connect: vehicleIds.map((id) => ({ id })),
          },
        },
      });
    }

    // Connect batteries
    if (batteryIds && batteryIds.length > 0) {
      await this.prisma.comparison.update({
        where: { id: comparison.id },
        data: {
          batteries: {
            connect: batteryIds.map((id) => ({ id })),
          },
        },
      });
    }

    // Return the comparison with related entities
    return this.findOne(comparison.id);
  }

  async findAll(page = 1, limit = 10) {
    const skip = (page - 1) * limit;

    // Get total count for pagination
    const totalCount = await this.prisma.comparison.count();

    // Get comparisons with pagination
    const comparisons = await this.prisma.comparison.findMany({
      skip,
      take: limit,
      include: {
        vehicles: true,
        batteries: true,
      },
      orderBy: {
        updatedAt: 'desc',
      },
    });

    return {
      data: comparisons,
      meta: {
        totalCount,
        page,
        limit,
        pageCount: Math.ceil(totalCount / limit),
      },
    };
  }

  async findOne(id: string) {
    const comparison = await this.prisma.comparison.findUnique({
      where: { id },
      include: {
        vehicles: true,
        batteries: true,
      },
    });

    if (!comparison) {
      throw new NotFoundException('So sánh không tồn tại');
    }

    return comparison;
  }

  async update(id: string, updateComparisonDto: UpdateComparisonDto) {
    const { name, vehicleIds, batteryIds } = updateComparisonDto;

    // Check if the comparison exists
    const comparison = await this.prisma.comparison.findUnique({
      where: { id },
      include: {
        vehicles: true,
        batteries: true,
      },
    });

    if (!comparison) {
      throw new NotFoundException('So sánh không tồn tại');
    }

    // Start building the update data
    const updateData: any = {};

    if (name) {
      updateData.name = name;
    }

    // Update the comparison's name
    await this.prisma.comparison.update({
      where: { id },
      data: updateData,
    });

    // Handle vehicles update if provided
    if (vehicleIds !== undefined) {
      // Check if the vehicles exist
      if (vehicleIds.length > 0) {
        const vehicles = await this.prisma.vehicle.findMany({
          where: {
            id: { in: vehicleIds },
          },
        });

        if (vehicles.length !== vehicleIds.length) {
          throw new NotFoundException('Một hoặc nhiều xe không tồn tại');
        }
      }

      // Disconnect all current vehicles
      await this.prisma.comparison.update({
        where: { id },
        data: {
          vehicles: {
            set: [], // Remove all existing connections
          },
        },
      });

      // Connect new vehicles if any
      if (vehicleIds.length > 0) {
        await this.prisma.comparison.update({
          where: { id },
          data: {
            vehicles: {
              connect: vehicleIds.map((id) => ({ id })),
            },
          },
        });
      }
    }

    // Handle batteries update if provided
    if (batteryIds !== undefined) {
      // Check if the batteries exist
      if (batteryIds.length > 0) {
        const batteries = await this.prisma.battery.findMany({
          where: {
            id: { in: batteryIds },
          },
        });

        if (batteries.length !== batteryIds.length) {
          throw new NotFoundException('Một hoặc nhiều pin không tồn tại');
        }
      }

      // Disconnect all current batteries
      await this.prisma.comparison.update({
        where: { id },
        data: {
          batteries: {
            set: [], // Remove all existing connections
          },
        },
      });

      // Connect new batteries if any
      if (batteryIds.length > 0) {
        await this.prisma.comparison.update({
          where: { id },
          data: {
            batteries: {
              connect: batteryIds.map((id) => ({ id })),
            },
          },
        });
      }
    }

    // Return the updated comparison
    return this.findOne(id);
  }

  async remove(id: string) {
    // Check if the comparison exists
    const comparison = await this.prisma.comparison.findUnique({
      where: { id },
    });

    if (!comparison) {
      throw new NotFoundException('So sánh không tồn tại');
    }

    // Delete the comparison (many-to-many relationships will be handled automatically)
    await this.prisma.comparison.delete({
      where: { id },
    });

    return { message: 'So sánh đã được xóa thành công' };
  }

  // Additional methods

  async addVehicleToComparison(id: string, vehicleId: string) {
    // Check if the comparison exists
    const comparison = await this.prisma.comparison.findUnique({
      where: { id },
      include: { vehicles: true },
    });

    if (!comparison) {
      throw new NotFoundException('So sánh không tồn tại');
    }

    // Check if the vehicle exists
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id: vehicleId },
    });

    if (!vehicle) {
      throw new NotFoundException('Xe không tồn tại');
    }

    // Check if vehicle is already in the comparison
    const vehicleExists = comparison.vehicles.some((v) => v.id === vehicleId);
    if (vehicleExists) {
      throw new BadRequestException('Xe đã có trong so sánh này');
    }

    // Add the vehicle to the comparison
    await this.prisma.comparison.update({
      where: { id },
      data: {
        vehicles: {
          connect: { id: vehicleId },
        },
      },
    });

    return this.findOne(id);
  }

  async removeVehicleFromComparison(id: string, vehicleId: string) {
    // Check if the comparison exists
    const comparison = await this.prisma.comparison.findUnique({
      where: { id },
      include: { vehicles: true, batteries: true },
    });

    if (!comparison) {
      throw new NotFoundException('So sánh không tồn tại');
    }

    // Check if the vehicle exists in the comparison
    const vehicleExists = comparison.vehicles.some((v) => v.id === vehicleId);
    if (!vehicleExists) {
      throw new BadRequestException('Xe không có trong so sánh này');
    }

    // Check if this would leave the comparison empty
    if (comparison.vehicles.length === 1 && comparison.batteries.length === 0) {
      throw new BadRequestException(
        'Không thể xóa xe duy nhất trong so sánh. Phải giữ ít nhất một xe hoặc một pin.',
      );
    }

    // Remove the vehicle from the comparison
    await this.prisma.comparison.update({
      where: { id },
      data: {
        vehicles: {
          disconnect: { id: vehicleId },
        },
      },
    });

    return this.findOne(id);
  }

  async addBatteryToComparison(id: string, batteryId: string) {
    // Check if the comparison exists
    const comparison = await this.prisma.comparison.findUnique({
      where: { id },
      include: { batteries: true },
    });

    if (!comparison) {
      throw new NotFoundException('So sánh không tồn tại');
    }

    // Check if the battery exists
    const battery = await this.prisma.battery.findUnique({
      where: { id: batteryId },
    });

    if (!battery) {
      throw new NotFoundException('Pin không tồn tại');
    }

    // Check if battery is already in the comparison
    const batteryExists = comparison.batteries.some((b) => b.id === batteryId);
    if (batteryExists) {
      throw new BadRequestException('Pin đã có trong so sánh này');
    }

    // Add the battery to the comparison
    await this.prisma.comparison.update({
      where: { id },
      data: {
        batteries: {
          connect: { id: batteryId },
        },
      },
    });

    return this.findOne(id);
  }

  async removeBatteryFromComparison(id: string, batteryId: string) {
    // Check if the comparison exists
    const comparison = await this.prisma.comparison.findUnique({
      where: { id },
      include: { vehicles: true, batteries: true },
    });

    if (!comparison) {
      throw new NotFoundException('So sánh không tồn tại');
    }

    // Check if the battery exists in the comparison
    const batteryExists = comparison.batteries.some((b) => b.id === batteryId);
    if (!batteryExists) {
      throw new BadRequestException('Pin không có trong so sánh này');
    }

    // Check if this would leave the comparison empty
    if (comparison.batteries.length === 1 && comparison.vehicles.length === 0) {
      throw new BadRequestException(
        'Không thể xóa pin duy nhất trong so sánh. Phải giữ ít nhất một xe hoặc một pin.',
      );
    }

    // Remove the battery from the comparison
    await this.prisma.comparison.update({
      where: { id },
      data: {
        batteries: {
          disconnect: { id: batteryId },
        },
      },
    });

    return this.findOne(id);
  }
}
