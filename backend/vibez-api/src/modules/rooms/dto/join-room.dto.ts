import z from "zod";

export const joinRoomSchema = z.object({
    roomId: z.string(),
});

export type JoinRoomDto = z.infer<typeof joinRoomSchema>;