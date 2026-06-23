import z from "zod";

export const createRoomSchema = z.object({
    name: z.string(),
    description: z.string().min(1),
    tags: z.string().array(),
    private: z.boolean(),
});

export type CreateRoomDto = z.infer<typeof createRoomSchema>;