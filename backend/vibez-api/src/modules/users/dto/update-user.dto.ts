import z from 'zod';

export const updateUserSchema = z
  .object({
    username: z.string().optional(),
    bio: z.string().optional(),
    profileUrl: z.string().optional(),
    tags: z.array(z.string()).optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'At least one field must be provided',
  });

export type UpdateUserDto = z.infer<typeof updateUserSchema>;
