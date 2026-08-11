import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';
import 'models.dart';

abstract interface class RestaurantRepository {
  Future<StaffSession> login(String phone, String otp);
  Future<List<Branch>> branches();
  Future<List<ReservationRequest>> inbox(String branchId);
  Future<ReservationRequest> request(String id);
  Future<ReservationRequest> confirm(String id);
  Future<List<DateTime>> alternatives(String id);
  Future<ReservationRequest> propose(String id, DateTime startsAt);
  Future<void> decline(String id, String? reason);
  Future<List<TodayReservation>> today(String branchId);
  Future<TodayReservation> checkIn(String id);
  Future<TodayReservation> complete(String id);
  Future<TodayReservation> noShow(String id);
  Future<BranchPolicy> policy(String branchId);
  Future<BranchPolicy> updatePolicy(String branchId, BranchPolicy policy);
  Future<void> logout();
}

class ApiRestaurantRepository implements RestaurantRepository {
  ApiRestaurantRepository(String baseUrl)
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 12),
        ),
      );
  final Dio _dio;
  final _storage = const FlutterSecureStorage();
  Options get _auth =>
      Options(headers: {'Authorization': 'Bearer ${_token ?? ''}'});
  String? _token;
  Never _fail(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      Object? code;
      if (data is Map) {
        final nested = data['error'];
        code = nested is Map ? nested['code'] : data['code'];
      }
      throw CommandException(code?.toString() ?? 'NETWORK_ERROR');
    }
    throw const CommandException('NETWORK_ERROR');
  }

  @override
  Future<StaffSession> login(String phone, String otp) async {
    try {
      final r = await _dio.post(
        '/api/v1/auth/verify-otp',
        data: {'phone': phone, 'otp': otp},
      );
      _token = r.data['accessToken'] as String;
      await _storage.write(key: 'accessToken', value: _token);
      return const StaffSession(
        name: 'Staff',
        role: StaffRole.host,
        branchIds: {},
      );
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<Branch>> branches() async {
    try {
      final r = await _dio.get(
        '/api/v1/restaurant/me/branches',
        options: _auth,
      );
      return (r.data['data'] as List)
          .map(
            (e) => Branch(
              id: e['branchId'],
              restaurantName: e['restaurantName'],
              name: e['branchName'],
              active: e['status'] == 'ACTIVE',
            ),
          )
          .toList();
    } catch (e) {
      _fail(e);
    }
  }

  ReservationRequest _request(Map<String, dynamic> e) => ReservationRequest(
    id: e['reservationId'],
    branchId: e['branchId'] ?? '',
    guestName: e['guestDisplayName'] ?? e['guestName'],
    guestPhone: e['guestPhone'],
    startsAt: DateTime.parse(e['requestedStartsAt']),
    partySize: e['partySize'],
    status: {
      'REQUESTED': RequestStatus.requested,
      'UNDER_REVIEW': RequestStatus.underReview,
      'ALTERNATIVE_PROPOSED': RequestStatus.alternativeProposed,
    }[e['status']]!,
    createdAt: DateTime.parse(e['createdAt']),
    expiresAt: DateTime.parse(e['requestExpiresAt']),
    specialRequest: e['specialRequest'],
    alternativeStartsAt: e['alternativeStartsAt'] == null
        ? null
        : DateTime.parse(e['alternativeStartsAt']),
  );
  @override
  Future<List<ReservationRequest>> inbox(String branchId) async {
    try {
      final r = await _dio.get(
        '/api/v1/restaurant/branches/$branchId/requests',
        options: _auth,
      );
      return (r.data['data'] as List)
          .map((e) => _request(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<ReservationRequest> request(String id) async {
    try {
      final r = await _dio.get(
        '/api/v1/restaurant/reservations/$id',
        options: _auth,
      );
      return _request(Map<String, dynamic>.from(r.data['data']));
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<ReservationRequest> confirm(String id) =>
      _requestCommand(id, 'confirm');
  Future<ReservationRequest> _requestCommand(
    String id,
    String action, {
    Object? data,
  }) async {
    try {
      final r = await _dio.post(
        '/api/v1/restaurant/reservations/$id/$action',
        data: data,
        options: _auth,
      );
      return _request(Map<String, dynamic>.from(r.data['data']));
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<List<DateTime>> alternatives(String id) async {
    try {
      final r = await _dio.get(
        '/api/v1/restaurant/reservations/$id/alternative-times',
        options: _auth,
      );
      return (r.data['data'] as List)
          .map((e) => DateTime.parse(e['startsAt']))
          .toList();
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<ReservationRequest> propose(String id, DateTime startsAt) =>
      _requestCommand(
        id,
        'propose-time',
        data: {'startsAt': startsAt.toUtc().toIso8601String()},
      );
  @override
  Future<void> decline(String id, String? reason) async {
    await _requestCommand(
      id,
      'decline',
      data: {if (reason?.isNotEmpty == true) 'reason': reason},
    );
  }

  TodayReservation _today(Map<String, dynamic> e) => TodayReservation(
    id: e['reservationId'],
    branchId: e['branchId'] ?? '',
    guestName: e['guestName'],
    guestPhone: e['guestPhone'],
    startsAt: DateTime.parse(e['startsAt']),
    partySize: e['partySize'],
    status: switch (e['status']) {
      'CONFIRMED' => TodayStatus.confirmed,
      'CHECKED_IN' => TodayStatus.checkedIn,
      'COMPLETED' => TodayStatus.completed,
      'NO_SHOW' => TodayStatus.noShow,
      _ => throw const CommandException('INVALID_RESERVATION_TRANSITION'),
    },
  );
  @override
  Future<List<TodayReservation>> today(String branchId) async {
    try {
      final r = await _dio.get(
        '/api/v1/restaurant/branches/$branchId/today',
        options: _auth,
      );
      return (r.data['data'] as List)
          .map((e) => _today(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      _fail(e);
    }
  }

  Future<TodayReservation> _todayCommand(String id, String action) async {
    try {
      final r = await _dio.post(
        '/api/v1/restaurant/reservations/$id/$action',
        options: _auth,
      );
      return _today(Map<String, dynamic>.from(r.data['data']));
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<TodayReservation> checkIn(String id) => _todayCommand(id, 'check-in');
  @override
  Future<TodayReservation> complete(String id) => _todayCommand(id, 'complete');
  @override
  Future<TodayReservation> noShow(String id) => _todayCommand(id, 'no-show');
  @override
  Future<BranchPolicy> policy(String branchId) async {
    try {
      final r = await _dio.get(
        '/api/v1/restaurant/branches/$branchId/reservation-policy',
        options: _auth,
      );
      final d = r.data['data'];
      return BranchPolicy(
        mode: {
          'REQUEST_FIRST': ReservationMode.requestFirst,
          'INSTANT_CONFIRMATION': ReservationMode.instantConfirmation,
          'SMART_HYBRID': ReservationMode.smartHybrid,
        }[d['reservationMode']]!,
        gracePeriodMinutes: d['gracePeriodMinutes'] ?? 15,
      );
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<BranchPolicy> updatePolicy(String branchId, BranchPolicy p) async {
    try {
      await _dio.patch(
        '/api/v1/restaurant/branches/$branchId/reservation-policy',
        data: {
          'reservationMode': p.mode == ReservationMode.requestFirst
              ? 'REQUEST_FIRST'
              : 'INSTANT_CONFIRMATION',
          'gracePeriodMinutes': p.gracePeriodMinutes,
          'noShowAction': 'NOTIFY_STAFF',
        },
        options: _auth,
      );
      return p;
    } catch (e) {
      _fail(e);
    }
  }

  @override
  Future<void> logout() async {
    _token = null;
    await _storage.deleteAll();
  }
}

class FixtureRestaurantRepository implements RestaurantRepository {
  FixtureRestaurantRepository({this.role = StaffRole.host});
  StaffRole role;
  final branchesData = <Branch>[
    const Branch(
      id: 'branch-manama',
      restaurantName: 'Saffron House',
      name: 'Manama',
    ),
    const Branch(
      id: 'branch-seef',
      restaurantName: 'Saffron House',
      name: 'Seef District',
    ),
  ];
  late StaffSession session;
  late final List<ReservationRequest> requests = [
    ReservationRequest(
      id: 'request-1',
      branchId: 'branch-manama',
      guestName: 'Noor Ahmed',
      guestPhone: '+973 3900 1122',
      startsAt: DateTime.now().add(const Duration(hours: 2)),
      partySize: 4,
      status: RequestStatus.requested,
      createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
      expiresAt: DateTime.now().add(const Duration(minutes: 3)),
      specialRequest: 'Birthday dinner',
    ),
    ReservationRequest(
      id: 'request-2',
      branchId: 'branch-manama',
      guestName: 'Ali Hasan',
      startsAt: DateTime.now().add(const Duration(hours: 3)),
      partySize: 2,
      status: RequestStatus.underReview,
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
      expiresAt: DateTime.now().add(const Duration(minutes: 6)),
    ),
    ReservationRequest(
      id: 'request-3',
      branchId: 'branch-manama',
      guestName: 'Mariam Isa',
      startsAt: DateTime.now().add(const Duration(hours: 4)),
      partySize: 6,
      status: RequestStatus.alternativeProposed,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      expiresAt: DateTime.now().add(const Duration(minutes: 8)),
      alternativeStartsAt: DateTime.now().add(const Duration(hours: 5)),
    ),
  ];
  late final List<TodayReservation> todayData = [
    TodayReservation(
      id: 'today-1',
      branchId: 'branch-manama',
      guestName: 'Fatima Salman',
      guestPhone: '+973 3777 2010',
      startsAt: DateTime.now().add(const Duration(hours: 1)),
      partySize: 3,
      status: TodayStatus.confirmed,
    ),
    TodayReservation(
      id: 'today-2',
      branchId: 'branch-manama',
      guestName: 'Omar Khalid',
      startsAt: DateTime.now().add(const Duration(hours: 2)),
      partySize: 2,
      status: TodayStatus.checkedIn,
    ),
    TodayReservation(
      id: 'today-3',
      branchId: 'branch-manama',
      guestName: 'Sara Nasser',
      startsAt: DateTime.now().subtract(const Duration(hours: 2)),
      partySize: 5,
      status: TodayStatus.completed,
    ),
    TodayReservation(
      id: 'today-4',
      branchId: 'branch-manama',
      guestName: 'Hamad Yousif',
      startsAt: DateTime.now().subtract(const Duration(hours: 1)),
      partySize: 2,
      status: TodayStatus.noShow,
    ),
  ];
  BranchPolicy policyData = const BranchPolicy();
  @override
  Future<StaffSession> login(String phone, String otp) async {
    if (otp != '123456') throw const CommandException('OTP_INVALID');
    role =
        {
              '1111': StaffRole.owner,
              '2222': StaffRole.manager,
              '3333': StaffRole.host,
              '4444': StaffRole.viewer,
            }.entries
            .firstWhere(
              (e) => phone.endsWith(e.key),
              orElse: () => const MapEntry('3333', StaffRole.host),
            )
            .value;
    session = StaffSession(
      name: 'Layla Hassan',
      role: role,
      branchIds: {'branch-manama', 'branch-seef'},
    );
    return session;
  }

  @override
  Future<List<Branch>> branches() async =>
      branchesData.where((b) => b.active).toList();
  @override
  Future<List<ReservationRequest>> inbox(String branchId) async {
    final list = requests.where((r) => r.branchId == branchId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<ReservationRequest> request(String id) async =>
      requests.firstWhere((r) => r.id == id);
  void _guard() {
    if (role == StaffRole.viewer)
      throw const CommandException('INSUFFICIENT_PERMISSION');
  }

  @override
  Future<ReservationRequest> confirm(String id) async {
    _guard();
    final i = requests.indexWhere((r) => r.id == id);
    if (i < 0) throw const CommandException('RESERVATION_NOT_FOUND');
    if (requests[i].status == RequestStatus.alternativeProposed)
      throw const CommandException('RESERVATION_ALREADY_PROCESSED');
    final result = requests.removeAt(i);
    todayData.add(
      TodayReservation(
        id: result.id,
        branchId: result.branchId,
        guestName: result.guestName,
        guestPhone: result.guestPhone,
        startsAt: result.startsAt,
        partySize: result.partySize,
        status: TodayStatus.confirmed,
        specialRequest: result.specialRequest,
      ),
    );
    return result;
  }

  @override
  Future<List<DateTime>> alternatives(String id) async {
    final r = await request(id);
    return List.generate(
      5,
      (i) => r.startsAt.add(Duration(minutes: 30 * (i + 1))),
    );
  }

  @override
  Future<ReservationRequest> propose(String id, DateTime startsAt) async {
    _guard();
    final i = requests.indexWhere((r) => r.id == id);
    requests[i] = requests[i].copyWith(
      status: RequestStatus.alternativeProposed,
      alternativeStartsAt: startsAt,
    );
    return requests[i];
  }

  @override
  Future<void> decline(String id, String? reason) async {
    _guard();
    requests.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<TodayReservation>> today(String branchId) async {
    final list = todayData.where((r) => r.branchId == branchId).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return list;
  }

  Future<TodayReservation> _setToday(String id, TodayStatus next) {
    _guard();
    final i = todayData.indexWhere((r) => r.id == id);
    todayData[i] = todayData[i].copyWith(status: next);
    return Future.value(todayData[i]);
  }

  @override
  Future<TodayReservation> checkIn(String id) =>
      _setToday(id, TodayStatus.checkedIn);
  @override
  Future<TodayReservation> complete(String id) =>
      _setToday(id, TodayStatus.completed);
  @override
  Future<TodayReservation> noShow(String id) {
    final r = todayData.firstWhere((e) => e.id == id);
    if (DateTime.now().isBefore(
      r.startsAt.add(Duration(minutes: policyData.gracePeriodMinutes)),
    ))
      throw const CommandException('NO_SHOW_NOT_YET_ALLOWED');
    return _setToday(id, TodayStatus.noShow);
  }

  @override
  Future<BranchPolicy> policy(String branchId) async => policyData;
  @override
  Future<BranchPolicy> updatePolicy(
    String branchId,
    BranchPolicy policy,
  ) async {
    _guard();
    policyData = policy;
    return policy;
  }

  @override
  Future<void> logout() async {}
}

final repositoryProvider = Provider<RestaurantRepository>((ref) {
  final c = ref.watch(appConfigProvider);
  return c.fixtures
      ? FixtureRestaurantRepository()
      : ApiRestaurantRepository(c.apiBaseUrl);
});

class OperationsController extends ChangeNotifier {
  OperationsController(this.repository);
  final RestaurantRepository repository;
  StaffSession? session;
  List<Branch> branches = [];
  Branch? selectedBranch;
  List<ReservationRequest> inbox = [];
  List<TodayReservation> today = [];
  BranchPolicy policy = const BranchPolicy();
  bool busy = false;
  String? errorCode;
  Timer? _poll;
  Future<void> login(String phone, String otp) async {
    await _run(() async {
      session = await repository.login(phone, otp);
      branches = await repository.branches();
      selectedBranch = branches.length == 1 ? branches.first : null;
    });
  }

  Future<void> selectBranch(Branch branch) async {
    selectedBranch = branch;
    await refresh();
  }

  Future<void> refresh() async {
    final b = selectedBranch;
    if (b == null) return;
    await _run(() async {
      inbox = await repository.inbox(b.id);
      today = await repository.today(b.id);
      policy = await repository.policy(b.id);
    });
  }

  void startPolling() {
    stopPolling();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  bool get polling => _poll?.isActive ?? false;
  Future<void> confirm(String id) => _command(() => repository.confirm(id));
  Future<void> propose(String id, DateTime time) =>
      _command(() => repository.propose(id, time));
  Future<void> decline(String id, String? reason) =>
      _command(() => repository.decline(id, reason));
  Future<void> checkIn(String id) => _command(() => repository.checkIn(id));
  Future<void> complete(String id) => _command(() => repository.complete(id));
  Future<void> noShow(String id) => _command(() => repository.noShow(id));
  Future<void> savePolicy(BranchPolicy value) async {
    final b = selectedBranch;
    if (b == null) return;
    await _run(() async {
      policy = await repository.updatePolicy(b.id, value);
    });
  }

  Future<void> logout() async {
    stopPolling();
    await repository.logout();
    session = null;
    selectedBranch = null;
    inbox = [];
    today = [];
    notifyListeners();
  }

  Future<void> _command(Future<Object?> Function() action) async {
    await _run(() async {
      await action();
      final b = selectedBranch;
      if (b != null) {
        inbox = await repository.inbox(b.id);
        today = await repository.today(b.id);
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    busy = true;
    errorCode = null;
    notifyListeners();
    try {
      await action();
    } on CommandException catch (e) {
      errorCode = e.code;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

final operationsProvider = ChangeNotifierProvider<OperationsController>(
  (ref) => OperationsController(ref.watch(repositoryProvider)),
);
