import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'package:seat_restaurant/src/app.dart';
import 'package:seat_restaurant/src/config.dart';
import 'package:seat_restaurant/src/formatting.dart';
import 'package:seat_restaurant/src/models.dart';
import 'package:seat_restaurant/src/operations.dart';

void main() {
  test('release manifest permits staging HTTPS traffic', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android.permission.INTERNET'));
  });
  late FixtureRestaurantRepository repository;
  setUpAll(initializeDateFormatting);
  setUp(() => repository = FixtureRestaurantRepository());

  test(
    '01 login accepts fixture OTP',
    () async => expectLater(
      (await repository.login('+973 3333', '123456')).role,
      StaffRole.host,
    ),
  );
  test(
    '02 invalid OTP is rejected',
    () async => expect(
      repository.login('+973 3333', '000000'),
      throwsA(isA<CommandException>()),
    ),
  );
  test('03 one branch can be auto selected', () async {
    repository.branchesData.removeLast();
    expect((await repository.branches()).single.id, 'branch-manama');
  });
  test(
    '04 multiple branches require selection',
    () async => expect((await repository.branches()).length, 2),
  );
  test('05 inactive branch is removed', () async {
    repository.branchesData.add(
      const Branch(id: 'x', restaurantName: 'X', name: 'X', active: false),
    );
    expect((await repository.branches()).any((b) => b.id == 'x'), isFalse);
  });
  test(
    '06 inbox loads',
    () async => expect(await repository.inbox('branch-manama'), isNotEmpty),
  );
  test(
    '07 inbox empty for unrelated branch',
    () async => expect(await repository.inbox('none'), isEmpty),
  );
  test('08 inbox sorts oldest first', () async {
    final rows = await repository.inbox('branch-manama');
    expect(rows.first.createdAt.isBefore(rows.last.createdAt), isTrue);
  });
  test('09 request detail is read only', () async {
    final before = repository.requests.length;
    await repository.request('request-1');
    expect(repository.requests.length, before);
  });
  test('10 confirm moves request to today', () async {
    await repository.confirm('request-1');
    expect(repository.todayData.any((r) => r.id == 'request-1'), isTrue);
  });
  test(
    '11 confirm conflict is structured',
    () async => expect(
      repository.confirm('request-3'),
      throwsA(
        predicate(
          (e) =>
              e is CommandException &&
              e.code == 'RESERVATION_ALREADY_PROCESSED',
        ),
      ),
    ),
  );
  test(
    '12 alternative list is capped at five',
    () async => expect((await repository.alternatives('request-1')).length, 5),
  );
  test('13 propose changes status', () async {
    final t = (await repository.alternatives('request-1')).first;
    expect(
      (await repository.propose('request-1', t)).status,
      RequestStatus.alternativeProposed,
    );
  });
  test('14 decline removes request', () async {
    await repository.decline('request-1', null);
    expect(repository.requests.any((r) => r.id == 'request-1'), isFalse);
  });
  test('15 viewer cannot act', () async {
    repository.role = StaffRole.viewer;
    expect(repository.confirm('request-1'), throwsA(isA<CommandException>()));
  });
  test('16 host can act', () async {
    repository.role = StaffRole.host;
    await repository.confirm('request-1');
    expect(repository.todayData.any((r) => r.id == 'request-1'), isTrue);
  });
  test('17 today list sorts by time', () async {
    final rows = await repository.today('branch-manama');
    expect(rows.first.startsAt.isBefore(rows.last.startsAt), isTrue);
  });
  test(
    '18 check in transitions',
    () async => expect(
      (await repository.checkIn('today-1')).status,
      TodayStatus.checkedIn,
    ),
  );
  test(
    '19 complete transitions',
    () async => expect(
      (await repository.complete('today-2')).status,
      TodayStatus.completed,
    ),
  );
  test(
    '20 early no show is blocked',
    () async => expect(
      () => repository.noShow('today-1'),
      throwsA(
        predicate(
          (e) => e is CommandException && e.code == 'NO_SHOW_NOT_YET_ALLOWED',
        ),
      ),
    ),
  );
  test('21 allowed no show transitions', () async {
    repository.todayData.add(
      TodayReservation(
        id: 'late',
        branchId: 'branch-manama',
        guestName: 'Guest',
        startsAt: DateTime.now().subtract(const Duration(hours: 1)),
        partySize: 2,
        status: TodayStatus.confirmed,
      ),
    );
    expect((await repository.noShow('late')).status, TodayStatus.noShow);
  });
  test(
    '22 policy reads defaults',
    () async => expect(
      (await repository.policy('branch-manama')).mode,
      ReservationMode.requestFirst,
    ),
  );
  test(
    '23 grace period defaults to 15',
    () async => expect(
      (await repository.policy('branch-manama')).gracePeriodMinutes,
      15,
    ),
  );
  test('24 policy updates', () async {
    await repository.updatePolicy(
      'branch-manama',
      const BranchPolicy(mode: ReservationMode.instantConfirmation),
    );
    expect(repository.policyData.mode, ReservationMode.instantConfirmation);
  });
  test(
    '25 English date hides raw timestamp',
    () => expect(
      seatDateTime(DateTime(2026, 8, 11, 19, 30), 'en'),
      isNot(contains('2026-')),
    ),
  );
  test(
    '26 Arabic date keeps Latin digits',
    () => expect(
      seatDateTime(DateTime(2026, 8, 11, 19, 30), 'ar'),
      isNot(matches(RegExp(r'[٠-٩]'))),
    ),
  );
  test('27 polling starts and stops', () {
    final c = OperationsController(repository);
    c.startPolling();
    expect(c.polling, isTrue);
    c.stopPolling();
    expect(c.polling, isFalse);
    c.dispose();
  });
  test('28 controller logout clears session', () async {
    final c = OperationsController(repository);
    await c.login('+973 3333', '123456');
    await c.logout();
    expect(c.session, isNull);
  });
  test(
    '29 fixtures cannot activate in production',
    () => expect(
      () => AppConfig(
        environment: AppEnvironment.prod,
        apiBaseUrl: 'x',
        fixtures: true,
      ),
      throwsAssertionError,
    ),
  );
  testWidgets('30 app renders bilingual login architecture', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.dev,
              apiBaseUrl: 'x',
              fixtures: true,
            ),
          ),
        ],
        child: const SeatRestaurantApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Restaurant staff login'), findsOneWidget);
  });
}
