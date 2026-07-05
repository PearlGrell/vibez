import { Controller, Get } from '@nestjs/common';

// Cheap liveness endpoint for uptime pingers / platform health checks.
// Deliberately touches nothing (no DB, no gRPC) so a keep-alive ping stays
// fast and can't be starved by a slow dependency.
@Controller('health')
export class HealthController {
  @Get()
  check() {
    return { status: 'ok', uptime: process.uptime() };
  }
}
