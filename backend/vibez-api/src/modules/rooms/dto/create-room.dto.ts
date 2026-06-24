import z from "zod";

export const createRoomSchema = z.object({
    name: z.string().min(1),
    description: z.string().default(""),
    tags: z.string().array(),
    private: z.boolean(),
});

export type CreateRoomDto = z.infer<typeof createRoomSchema>;