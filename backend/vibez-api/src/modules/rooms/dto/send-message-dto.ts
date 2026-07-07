import z from "zod";

export const sendMessageSchema = z.object({
    roomId: z.string(),
    message: z.string(),
});

export type SendMessageDto = z.infer<typeof sendMessageSchema>;