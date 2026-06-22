import z from 'zod';

export const updateRoomSchema = z
  .object({
    name: z.string().optional(),
    description: z.string().min(1).optional(),
    tags: z.string().array().optional(),
    private: z.boolean().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'At least one field must be provided',
  });

export type UpdateRoomDto = z.infer<typeof updateRoomSchema>;
