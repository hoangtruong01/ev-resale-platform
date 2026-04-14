import {
  BadRequestException,
  Controller,
  Post,
  UploadedFiles,
  UseInterceptors,
} from '@nestjs/common';
import {
  ApiConsumes,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { FilesInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';

interface UploadedMulterFile {
  filename: string;
  originalname: string;
  mimetype: string;
  size: number;
}

const listingStorage = diskStorage({
  destination: (_req, _file, callback) => {
    const uploadPath = join(process.cwd(), 'uploads', 'listings');
    if (!existsSync(uploadPath)) {
      mkdirSync(uploadPath, { recursive: true });
    }
    callback(null, uploadPath);
  },
  filename: (_req, file, callback) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1_000_000)}`;
    callback(null, `${uniqueSuffix}${extname(file.originalname)}`);
  },
});

const imageFilter = (_req: any, file: any, callback: any) => {
  if (!file.mimetype.startsWith('image/')) {
    return callback(
      new BadRequestException('Chỉ chấp nhận file ảnh.') as any,
      false,
    );
  }
  callback(null, true);
};

@ApiTags('Files')
@Controller('uploads')
export class UploadsController {
  @Post('listing-images')
  @UseInterceptors(
    FilesInterceptor('files', 10, {
      storage: listingStorage,
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: imageFilter,
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Upload listing images',
    description: 'Upload up to 10 images for listings.',
  })
  @ApiResponse({ status: 201, description: 'Images uploaded successfully' })
  uploadListingImages(@UploadedFiles() files: UploadedMulterFile[]) {
    if (!files?.length) {
      throw new BadRequestException('No files uploaded');
    }

    return {
      images: files.map((file) => ({
        url: `/uploads/listings/${file.filename}`,
        originalName: file.originalname,
        size: file.size,
        mimeType: file.mimetype,
      })),
    };
  }
}
