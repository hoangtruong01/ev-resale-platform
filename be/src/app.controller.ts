import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AppService } from './app.service';

@ApiTags('Health')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @ApiOperation({
    summary: 'Get Hello Message',
    description: 'Returns a simple hello message from the application',
  })
  @ApiResponse({
    status: 200,
    description: 'Hello message returned successfully',
    schema: {
      type: 'string',
      example: 'Hello World!',
    },
  })
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  @ApiOperation({
    summary: 'Health Check',
    description: 'Returns the health status of the backend API',
  })
  @ApiResponse({
    status: 200,
    description: 'Health check successful',
    schema: {
      type: 'object',
      properties: {
        status: {
          type: 'string',
          example: 'ok',
        },
        message: {
          type: 'string',
          example: 'Backend is running successfully',
        },
        timestamp: {
          type: 'string',
          format: 'date-time',
          example: '2025-09-22T10:30:00.000Z',
        },
        environment: {
          type: 'string',
          example: 'development',
        },
      },
    },
  })
  getHealth() {
    return {
      status: 'ok',
      message: 'Backend is running successfully',
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV || 'development',
    };
  }
}
