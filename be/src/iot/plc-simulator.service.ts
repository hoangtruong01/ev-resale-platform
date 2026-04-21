import { Injectable, Logger } from '@nestjs/common';
import { Interval } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { IotGateway } from './iot.gateway';
import { BatteryStatus } from '@prisma/client';

@Injectable()
export class PlcSimulatorService {
  private readonly logger = new Logger(PlcSimulatorService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly iotGateway: IotGateway,
  ) {}

  @Interval(5000) // 5 seconds frequency as requested
  async handleSimulation() {
    this.logger.debug('Running PLC Simulation cycle...');

    // Fetch active batteries (AVAILABLE or in active transactions)
    // For simplicity, we jitter all AVAILABLE batteries
    const batteries = await this.prisma.battery.findMany({
      where: {
        status: BatteryStatus.AVAILABLE,
        isActive: true,
      },
    });

    if (batteries.length === 0) return;

    for (const battery of batteries) {
      const telemetry = this.generateJitterData(battery);

      // Update DB (optional, but good for persistence)
      await this.prisma.battery.update({
        where: { id: battery.id },
        data: {
          voltage: telemetry.voltage,
          current: telemetry.current,
          temperature: telemetry.temperature,
          soc: telemetry.soc,
          soh: telemetry.soh,
        },
      });

      // Broadcast to clients
      this.iotGateway.broadcastTelemetry(battery.id, {
        batteryId: battery.id,
        ...telemetry,
        timestamp: new Date().toISOString(),
      });
    }
  }

  private generateJitterData(battery: any) {
    // Base values or previous values
    const prevVoltage = Number(battery.voltage) || 52.0;
    const prevSoc = battery.soc ?? 85;
    const prevTemp = Number(battery.temperature) || 32.0;

    // Simulate small changes
    const voltage = parseFloat(
      (prevVoltage + (Math.random() - 0.5) * 0.5).toFixed(2),
    );
    const current = parseFloat((Math.random() * 5).toFixed(2)); // 0-5A
    const temperature = parseFloat(
      (prevTemp + (Math.random() - 0.5) * 0.2).toFixed(1),
    );

    // SOC slowly drains if current > 0 (simulated discharge)
    let soc = prevSoc;
    if (current > 0 && Math.random() > 0.7) {
      soc = Math.max(0, soc - 1);
    }

    return {
      voltage: Math.max(42, Math.min(58, voltage)), // Range 42-58V
      current,
      temperature: Math.max(20, Math.min(60, temperature)), // Range 20-60C
      soc,
      soh: battery.soh ?? 95, // Health stays stable
    };
  }
}
