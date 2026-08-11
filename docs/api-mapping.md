# V1 API mapping

| Experience | Endpoint |
|---|---|
| Staff OTP | `POST /api/v1/auth/verify-otp` |
| Accessible branches | `GET /api/v1/restaurant/me/branches` |
| Inbox | `GET /api/v1/restaurant/branches/:branchId/requests` |
| Request/reservation detail | `GET /api/v1/restaurant/reservations/:id` |
| Confirm | `POST /api/v1/restaurant/reservations/:id/confirm` |
| Alternative suggestions | `GET /api/v1/restaurant/reservations/:id/alternative-times` |
| Propose time | `POST /api/v1/restaurant/reservations/:id/propose-time` |
| Decline | `POST /api/v1/restaurant/reservations/:id/decline` |
| Today | `GET /api/v1/restaurant/branches/:branchId/today` |
| Check in | `POST /api/v1/restaurant/reservations/:id/check-in` |
| Complete | `POST /api/v1/restaurant/reservations/:id/complete` |
| No show | `POST /api/v1/restaurant/reservations/:id/no-show` |
| Policy | `GET/PATCH /api/v1/restaurant/branches/:branchId/reservation-policy` |

The production API remains the source of truth. API responses must match the v0.12.0 OpenAPI document. Push registration uses `POST /api/v1/me/devices` with `appType: RESTAURANT`; a real mobile push adapter is deliberately deferred until platform credentials exist.
