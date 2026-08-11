# Two-app demo

Run the API on a host reachable by both emulators/devices, then run each app with the same `API_BASE_URL`.

```sh
# Customer
cd seat-mobile
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Restaurant staff
cd seat-restaurant
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Confirm flow:

1. Sign into the customer app and request a reservation at a REQUEST_FIRST branch.
2. Sign into the restaurant app as branch-authorized HOST, MANAGER, or OWNER.
3. Pull to refresh Inbox; open the request and choose Confirm.
4. Pull to refresh the customer reservation detail. It shows Confirmed.

Suggest-time flow:

1. Submit another customer request.
2. In the restaurant Inbox, open it, choose Suggest another time, select one server-provided option, and submit.
3. Refresh the customer detail and accept the proposal.
4. Refresh both apps; the customer reservation and restaurant Today entry show Confirmed.

Fixture mode demonstrates each app independently and cannot synchronize between repositories. The cross-app flow requires the shared API and database.
