import z from 'zod';

export const loginSchema = z.object({
  email: z.email('Invalid email address'),
  password: z
    .string()
    .min(8)
    .regex(/[A-Z]/, 'Must contain an uppercase letter')
    .regex(/[a-z]/, 'Must contain a lowercase letter')
    .regex(/[0-9]/, 'Must contain a number'),
});

export type LoginDto = z.infer<typeof loginSchema>;
