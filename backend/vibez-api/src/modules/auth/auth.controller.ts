import { Body, Controller, Get, Patch, Post, Req, Res, UseGuards, UsePipes } from '@nestjs/common';
import { AuthService } from './auth.service';
import { ZodPipe } from 'src/common/pipes/zod/zod.pipe';
import { type Request, type Response } from 'express';
import { type LoginDto, loginSchema } from './dto/login.dto';
import { type RegisterDto, registerSchema } from './dto/register.dto';
import { type ResetPasswordDto, resetPasswordSchema } from './dto/reset-password.dto';
import { type ForgotPasswordDto, forgotPasswordSchema } from './dto/forgot-password.dto';
import { type ResendOtpDto, resendOtpSchema } from './dto/resend-otp.dto';
import { type VerifyOtpDto, verifyOtpSchema } from './dto/verify-otp.dto';
import { type UpdateEmailDto, updateEmailSchema } from './dto/update-email.dto';
import { type ChangePasswordDto, changePasswordSchema } from './dto/change-password.dto';
import { AuthGuard } from './guards/auth.guard';
import { CurrentUser, type UserPayload } from 'src/common/decorators/current-user.decorator';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';

// Credential-guessing targets get a tight per-IP budget; everything else on
// this controller falls back to the module default (20/min).
const STRICT_RATE_LIMIT = { default: { ttl: 60_000, limit: 8 } };

@Controller('auth')
@UseGuards(ThrottlerGuard)
export class AuthController {
  constructor(private auth: AuthService) {}

  @Post('login')
  @Throttle(STRICT_RATE_LIMIT)
  @UsePipes(new ZodPipe(loginSchema))
  async login(
    @Body() body: LoginDto,
    @Req() req: Request,
    @Res({
      passthrough: true,
    })
    response: Response,
  ) {
    const metadata = {
      deviceName: (req.headers['x-device-name'] as string) || undefined,
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    };
    const res = await this.auth.login(body.email, body.password, metadata);

    response.cookie('refreshToken', res.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 30 * 24 * 60 * 60 * 1000,
    });

    return {
      token: res.accessToken,
    };
  }

  @Post('register')
  @Throttle(STRICT_RATE_LIMIT)
  @UsePipes(new ZodPipe(registerSchema))
  async register(
    @Body() body: RegisterDto,
    @Req() req: Request,
    @Res({
      passthrough: true,
    })
    response: Response,
  ) {
    const metadata = {
      deviceName: (req.headers['x-device-name'] as string) || undefined,
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    };
    const res = await this.auth.register(body.name, body.email, body.password, metadata);

    response.cookie('refreshToken', res.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 30 * 24 * 60 * 60 * 1000,
    });

    return {
      token: res.accessToken,
    };
  }

  @Post('forgot')
  @Throttle(STRICT_RATE_LIMIT)
  @UsePipes(new ZodPipe(forgotPasswordSchema))
  async forgot(@Body() body: ForgotPasswordDto) {
    return this.auth.forgot(body.email);
  }

  @Post('forgot/resend')
  @Throttle(STRICT_RATE_LIMIT)
  @UsePipes(new ZodPipe(resendOtpSchema))
  async resend(@Body() body: ResendOtpDto) {
    return this.auth.resend(body.email);
  }

  @Post('verify')
  @Throttle(STRICT_RATE_LIMIT)
  @UsePipes(new ZodPipe(verifyOtpSchema))
  async verify(@Body() body: VerifyOtpDto) {
    return this.auth.verify(body.email, body.otp);
  }

  @Post('reset')
  @Throttle(STRICT_RATE_LIMIT)
  @UsePipes(new ZodPipe(resetPasswordSchema))
  async reset(@Body() body: ResetPasswordDto) {
    return this.auth.reset(body.resetToken, body.password);
  }

  @Post('refresh')
  async refresh(@Req() request: Request, @Res({ passthrough: true }) response: Response) {
    const refreshToken = request.cookies['refreshToken'];
    const res = await this.auth.refresh(refreshToken);

    response.cookie('refreshToken', res.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 30 * 24 * 60 * 60 * 1000,
    });

    return {
      token: res.accessToken,
    };
  }

  @Post('logout')
  @UseGuards(AuthGuard)
  logout(@Req() req: Request) {
    return this.auth.logout(req);
  }

  @Get('sessions')
  @UseGuards(AuthGuard)
  getSessions(@CurrentUser() user: UserPayload) {
    return this.auth.getSessions(user.sub);
  }

  @Patch('email')
  @UseGuards(AuthGuard)
  @UsePipes(new ZodPipe(updateEmailSchema))
  updateEmail(@CurrentUser() user: UserPayload, @Body() updateEmailDto: UpdateEmailDto) {
    return this.auth.updateEmail(user.sub, updateEmailDto);
  }

  @Patch('password')
  @UseGuards(AuthGuard)
  @UsePipes(new ZodPipe(changePasswordSchema))
  changePassword(@CurrentUser() user: UserPayload, @Body() changePasswordDto: ChangePasswordDto) {
    return this.auth.changePassword(user.sub, changePasswordDto);
  }
}
