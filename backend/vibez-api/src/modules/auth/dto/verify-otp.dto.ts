import { z } from 'zod';

export const verifyOtpSchema = z.object({
  email: z.email('Invalid email address'),
  otp: z.string().length(6, 'OTP must be exactly 6 characters'),
});

export type VerifyOtpDto = z.infer<typeof verifyOtpSchema>;
