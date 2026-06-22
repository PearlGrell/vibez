import { z } from 'zod';

export const envSchema = z
  .object({
    NODE_ENV: z.enum(['production', 'development']).default('development'),
    PORT: z.coerce.number().default(3000),

    PGHOST: z.string(),
    PGPORT: z.coerce.number(),
    PGDATABASE: z.string(),
    PGUSER: z.string(),
    PGPASSWORD: z.string(),
    PGSSL: z.coerce.boolean().default(false),

    JWT_SECRET: z.string().min(1),
    JWT_EXPIRES_IN: z.string(),
  })
  .required();

export type Env = z.infer<typeof envSchema>;

export function validate(config: Record<string, unknown>) {
  const result = envSchema.safeParse(config);

  if (!result.success) {
    throw new Error('Invalid environment variables');
  }

  return result.data;
}
