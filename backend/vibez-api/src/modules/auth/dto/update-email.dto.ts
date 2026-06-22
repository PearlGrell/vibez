import z from 'zod';

export const updateEmailSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string(),
});

export type UpdateEmailDto = z.infer<typeof updateEmailSchema>;
