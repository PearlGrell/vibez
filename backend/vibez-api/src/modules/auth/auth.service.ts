import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import bcrypt from 'bcrypt';
import crypto from 'crypto';
import { User } from '../users/entities/user.entity';
import { Session } from './entities/session.entity';
import { JwtService } from '@nestjs/jwt';
import { TooManyRequestsException } from 'src/common/exceptions/too-many-requests.exception';
import { type Request } from 'express';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateEmailDto } from './dto/update-email.dto';
import { generateNanoId } from 'src/utils/nanoid';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Session)
    private readonly sessionRepository: Repository<Session>,
    private readonly jwtService: JwtService,
  ) {}

  async login(
    email: string,
    password: string,
    metadata?: { deviceName?: string; ipAddress?: string; userAgent?: string },
  ) {
    if (!email || !password) {
      throw new BadRequestException('Email and password are required.');
    }

    const user = await this.userRepository
      .createQueryBuilder('user')
      .addSelect('user.password')
      .where('user.email=:email', {
        email,
      })
      .getOne();

    if (!user) {
      throw new UnauthorizedException('Invalid Credentials');
    }

    const valid = await bcrypt.compare(password, user.password);

    if (!valid) {
      throw new UnauthorizedException('Invalid Credentials');
    }

    const session = this.sessionRepository.create({
      user,
      refreshToken: '',
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      deviceName: metadata?.deviceName,
      ipAddress: metadata?.ipAddress,
      userAgent: metadata?.userAgent,
    });
    await this.sessionRepository.save(session);

    const refreshToken = await this.jwtService.signAsync(
      {
        sub: user.id,
        sid: session.id,
      },
      {
        expiresIn: '30d',
      },
    );

    const accessToken = await this.jwtService.signAsync({
      sub: user.id,
      sid: session.id,
      jti: crypto.randomUUID(),
    });

    const hashedRefreshToken = await bcrypt.hash(refreshToken, 10);
    session.refreshToken = hashedRefreshToken;
    await this.sessionRepository.save(session);

    return { accessToken, refreshToken };
  }

  async register(
    name: string,
    email: string,
    password: string,
    metadata?: { deviceName?: string; ipAddress?: string; userAgent?: string },
  ) {
    if (!name || !email || !password) {
      throw new BadRequestException('Name, email, and password are required.');
    }

    const existingUser = await this.userRepository.findOne({
      where: { email },
    });

    if (existingUser) {
      throw new ConflictException('User already exists');
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const base = email.split('@')[0].split(/[._-]/)[0];
    const username = `${base}_${generateNanoId(6)}`;

    const user = await this.userRepository.save(
      this.userRepository.create({
        name,
        email,
        username,
        password: hashedPassword,
      }),
    );

    const session = this.sessionRepository.create({
      user,
      refreshToken: '',
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      deviceName: metadata?.deviceName,
      ipAddress: metadata?.ipAddress,
      userAgent: metadata?.userAgent,
    });
    await this.sessionRepository.save(session);

    const accessToken = await this.jwtService.signAsync({
      sub: user.id,
      email: user.email,
      sid: session.id,
      jti: crypto.randomUUID(),
    });

    const refreshToken = await this.jwtService.signAsync(
      {
        sub: user.id,
        sid: session.id,
      },
      {
        expiresIn: '30d',
      },
    );

    const hashedRefreshToken = await bcrypt.hash(refreshToken, 10);
    session.refreshToken = hashedRefreshToken;
    await this.sessionRepository.save(session);

    return { accessToken, refreshToken };
  }

  async forgot(email: string) {
    if (!email) {
      throw new BadRequestException('Invalid email address.');
    }

    const user = await this.userRepository.findOne({ where: { email } });

    if (user) {
      const otp = crypto.randomInt(100000, 1000000);
      console.log(`[DEV ONLY] OTP for ${email}: ${otp}`);
      const hashedOtp = await bcrypt.hash(`${otp}`, 10);

      user.otp = hashedOtp;
      user.lastOtpSentAt = new Date();
      user.otpExpiredAt = new Date(Date.now() + 10 * 60 * 1000);
      user.otpResendCount = 0;

      await this.userRepository.save(user);
      /** TODO: send the email */
    }

    return {
      message: 'If the email exists, a reset code has been sent. The code is valid for 10 minutes.',
    };
  }

  async resend(email: string) {
    if (!email) {
      throw new BadRequestException('Invalid email address.');
    }

    const user = await this.userRepository.findOne({
      where: { email },
      select: {
        id: true,
        email: true,
        otp: true,
        otpExpiredAt: true,
        lastOtpSentAt: true,
        otpResendCount: true,
      },
    });

    const cooldownTime = [1 * 60 * 1000, 2 * 60 * 1000, 5 * 60 * 1000, 10 * 60 * 1000, 30 * 60 * 1000];

    if (user) {
      if (!user.otp) {
        throw new BadRequestException('Please initiate the forgot password process first.');
      }

      const resendCount = user.otpResendCount ?? 0;
      if (resendCount >= 5) {
        throw new TooManyRequestsException('Maximum OTP resend attempts reached.');
      }

      const cooldown: number = cooldownTime[resendCount] ?? 30 * 60 * 1000;

      if (user.lastOtpSentAt) {
        const elapsed = Date.now() - user.lastOtpSentAt.getTime();

        if (elapsed < cooldown) {
          const remainingSeconds = Math.ceil((cooldown - elapsed) / 1000);

          throw new BadRequestException(`Please wait ${remainingSeconds} seconds before requesting another OTP.`);
        }
      }

      if (user.otpExpiredAt && user.otpExpiredAt.getTime() < Date.now()) {
        throw new BadRequestException('OTP session expired. Please start the forgot password process again.');
      }

      const otp = crypto.randomInt(100000, 1000000);
      console.log(`[DEV ONLY] Resent OTP for ${email}: ${otp}`);
      const hashedOtp = await bcrypt.hash(`${otp}`, 10);

      user.otp = hashedOtp;
      user.lastOtpSentAt = new Date();
      user.otpExpiredAt = new Date(Date.now() + 10 * 60 * 1000);
      user.otpResendCount = resendCount + 1;

      await this.userRepository.save(user);
      /** TODO: send the email */
    }

    return {
      message: 'If the email exists, a reset code has been sent. The code is valid for 10 minutes.',
    };
  }

  async verify(email: string, otp: string) {
    if (!email || !otp) {
      throw new BadRequestException('Email and OTP are required.');
    }

    const user = await this.userRepository
      .createQueryBuilder('user')
      .addSelect('user.otp')
      .addSelect('user.otpExpiredAt')
      .where('user.email = :email', { email })
      .getOne();

    if (!user || !user.otp) {
      throw new BadRequestException('Invalid OTP');
    }

    if (!user.otpExpiredAt || user.otpExpiredAt.getTime() < Date.now()) {
      throw new BadRequestException('OTP expired');
    }

    const valid = await bcrypt.compare(otp, user.otp);

    if (!valid) {
      throw new BadRequestException('Invalid OTP');
    }

    user.otp = null;
    user.otpExpiredAt = null;
    user.otpResendCount = 0;
    user.lastOtpSentAt = null;

    await this.userRepository.save(user);

    const resetToken = await this.jwtService.signAsync(
      {
        sub: user.id,
        purpose: 'password-reset',
      },
      {
        expiresIn: '10m',
      },
    );

    return {
      resetToken,
    };
  }

  async reset(resetToken: string, password: string) {
    if (!resetToken || !password) {
      throw new BadRequestException('Reset token and password are required.');
    }

    let payload: { sub: string; purpose: 'password-reset' };

    try {
      payload = await this.jwtService.verifyAsync(resetToken);
    } catch {
      throw new UnauthorizedException('Invalid or expired reset token');
    }

    if (payload.purpose !== 'password-reset') {
      throw new UnauthorizedException('Invalid reset token');
    }

    const user = await this.userRepository.findOne({
      where: { id: payload.sub },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid Credentials');
    }

    user.password = await bcrypt.hash(password, 10);

    await this.userRepository.save(user);

    await this.sessionRepository.delete({ userId: user.id });

    return {
      message: 'Password reset successfully.',
    };
  }

  async refresh(refreshToken: string) {
    if (!refreshToken) {
      throw new BadRequestException('Refresh token is required');
    }

    let payload: { sub: string; sid?: string };
    try {
      payload = await this.jwtService.verifyAsync(refreshToken);
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    if (!payload.sid) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const session = await this.sessionRepository.findOne({
      where: { id: payload.sid, userId: payload.sub },
    });

    if (!session || session.expiresAt.getTime() < Date.now()) {
      throw new UnauthorizedException('Invalid or expired session');
    }

    const valid = await bcrypt.compare(refreshToken, session.refreshToken);
    if (!valid) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const newRefreshToken = await this.jwtService.signAsync(
      { sub: session.userId, sid: session.id },
      { expiresIn: '30d' },
    );
    const accessToken = await this.jwtService.signAsync({
      sub: session.userId,
      sid: session.id,
      jti: crypto.randomUUID(),
    });

    const hashedRefreshToken = await bcrypt.hash(newRefreshToken, 10);
    session.refreshToken = hashedRefreshToken;
    session.expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    await this.sessionRepository.save(session);

    return { accessToken, refreshToken: newRefreshToken };
  }

  async logout(req: Request) {
    const user = (req as any).user;
    const all = req.query?.all === 'true';

    if (user) {
      if (all) {
        await this.sessionRepository.delete({ userId: user.sub });
      } else if (user.sid) {
        await this.sessionRepository.delete({ id: user.sid });
      }
    }

    return { message: 'Logged out successfully' };
  }

  async getSessions(userId: string) {
    return this.sessionRepository.find({
      where: { userId },
      select: {
        id: true,
        expiresAt: true,
        deviceName: true,
        ipAddress: true,
        userAgent: true,
        createdAt: true,
        updatedAt: true,
      },
    });
  }

  async updateEmail(userId: string, updateEmailDto: UpdateEmailDto) {
    if (userId == undefined || userId == null) {
      throw new BadRequestException();
    }

    const user = await this.userRepository
      .createQueryBuilder('user')
      .addSelect('user.password')
      .where('user.id = :id', { id: userId })
      .getOne();

    if (!user) {
      throw new NotFoundException('User not found.');
    }

    const isMatch = await bcrypt.compare(updateEmailDto.password, user.password);
    if (!isMatch) {
      throw new BadRequestException('Incorrect password.');
    }

    if (updateEmailDto.email === user.email) {
      return user;
    }

    const existingUser = await this.userRepository.findOne({
      where: { email: updateEmailDto.email },
    });

    if (existingUser) {
      throw new ConflictException('Email already in use.');
    }

    user.email = updateEmailDto.email;
    return this.userRepository.save(user);
  }

  async changePassword(userId: string, changePasswordDto: ChangePasswordDto) {
    if (userId == undefined || userId == null) {
      throw new BadRequestException();
    }

    const user = await this.userRepository
      .createQueryBuilder('user')
      .addSelect('user.password')
      .where('user.id = :id', { id: userId })
      .getOne();

    if (!user) {
      throw new NotFoundException('User not found.');
    }

    const isMatch = await bcrypt.compare(changePasswordDto.oldPassword, user.password);
    if (!isMatch) {
      throw new BadRequestException('Incorrect current password.');
    }

    user.password = await bcrypt.hash(changePasswordDto.newPassword, 10);

    await this.sessionRepository.delete({ userId: user.id });
    await this.userRepository.save(user);

    return { message: 'Password changed successfully.' };
  }
}
