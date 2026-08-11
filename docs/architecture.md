# Architecture

The app uses a small layered architecture:

- presentation: Router-driven screens and Riverpod state observation;
- application: `OperationsController`, command coordination, polling lifecycle, and immediate local refresh;
- domain: typed branch, staff, request, reservation, policy, status, and error models;
- data: one provider-independent repository contract with API and isolated DEV fixture implementations.

The API repository owns transport details and maps backend error codes to typed command failures. Screens never submit staff IDs, branch membership, table IDs, allocations, or optimization data. The server remains authoritative for permission, state-transition, grace-period, and inventory decisions.

Inbox polling runs only while Inbox is active and the application is foregrounded. Pull-to-refresh remains available. Push integration can trigger the same refresh path; WebSockets are intentionally absent.

Secure storage holds the access token. Production still requires the backend's final refresh-token response shape to be verified before release signing.
