import z from 'zod';

export const registerSchema = z.object({
  name: z.string(),
  email: z.email('Invalid email address'),
  password: z
    .string()
    .min(8)
    .regex(/[A-Z]/, 'Must contain an uppercase letter')
    .regex(/[a-z]/, 'Must contain a lowercase letter')
    .regex(/[0-9]/, 'Must contain a number'),
});

export type RegisterDto = z.infer<typeof registerSchema>;
