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
}
