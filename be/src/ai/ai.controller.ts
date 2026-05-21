import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
  ValidationPipe,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AiService } from './ai.service';
import { AiChatRequestDto } from './dto/ai-chat.dto';
import {
  AiAccessoryPriceSuggestionDto,
  AiBatteryPriceSuggestionDto,
  AiVehiclePriceSuggestionDto,
} from './dto/ai-price-suggestion.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@ApiTags('AI')
@Controller('ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('chat')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Shared AI chat endpoint for web and mobile' })
  @ApiBody({ type: AiChatRequestDto })
  @ApiResponse({ status: 200, description: 'AI response returned' })
  @ApiResponse({ status: 400, description: 'Invalid request body' })
  @ApiResponse({ status: 401, description: 'Authentication required' })
  @ApiResponse({ status: 503, description: 'AI provider unavailable' })
  chat(
    @Body(new ValidationPipe({ whitelist: true, transform: true }))
    payload: AiChatRequestDto,
  ) {
    return this.aiService.chat(payload);
  }

  @Post('vehicles/suggest-price')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Deterministic AI vehicle price suggestion' })
  @ApiBody({ type: AiVehiclePriceSuggestionDto })
  @ApiResponse({
    status: 200,
    description: 'Vehicle price suggestion returned',
  })
  @ApiResponse({ status: 400, description: 'Invalid request body' })
  @ApiResponse({ status: 401, description: 'Authentication required' })
  suggestVehiclePrice(
    @Body(new ValidationPipe({ whitelist: true, transform: true }))
    payload: AiVehiclePriceSuggestionDto,
  ) {
    return this.aiService.suggestVehiclePrice(payload);
  }

  @Post('batteries/suggest-price')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Deterministic AI battery price suggestion' })
  @ApiBody({ type: AiBatteryPriceSuggestionDto })
  @ApiResponse({
    status: 200,
    description: 'Battery price suggestion returned',
  })
  @ApiResponse({ status: 400, description: 'Invalid request body' })
  @ApiResponse({ status: 401, description: 'Authentication required' })
  suggestBatteryPrice(
    @Body(new ValidationPipe({ whitelist: true, transform: true }))
    payload: AiBatteryPriceSuggestionDto,
  ) {
    return this.aiService.suggestBatteryPrice(payload);
  }

  @Post('accessories/suggest-price')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Deterministic AI accessory price suggestion' })
  @ApiBody({ type: AiAccessoryPriceSuggestionDto })
  @ApiResponse({
    status: 200,
    description: 'Accessory price suggestion returned',
  })
  @ApiResponse({ status: 400, description: 'Invalid request body' })
  @ApiResponse({ status: 401, description: 'Authentication required' })
  suggestAccessoryPrice(
    @Body(new ValidationPipe({ whitelist: true, transform: true }))
    payload: AiAccessoryPriceSuggestionDto,
  ) {
    return this.aiService.suggestAccessoryPrice(payload);
  }
}
