import z from 'zod';

export const checkUsernameSchema = z.object({
  username: z
    .string()
    .min(3, 'Username must be at least 3 characters')
    .max(16, 'Username must be at most 16 characters')
    .regex(/^[a-zA-Z0-9_.]+$/, 'Only letters, numbers, underscores, and dots are allowed'),
});

export type CheckUsernameDto = z.infer<typeof checkUsernameSchema>;
