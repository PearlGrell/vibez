import z from "zod";

export const leaveRoomSchema = z.object({
    roomId: z.string(),
});

export type LeaveRoomDto = z.infer<typeof leaveRoomSchema>;