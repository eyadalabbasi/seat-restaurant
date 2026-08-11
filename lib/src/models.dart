enum StaffRole { owner, manager, host, viewer }

enum RequestStatus { requested, underReview, alternativeProposed }

enum TodayStatus { confirmed, checkedIn, completed, noShow }

enum ReservationMode { requestFirst, instantConfirmation, smartHybrid }

class Branch {
  const Branch({
    required this.id,
    required this.restaurantName,
    required this.name,
    this.active = true,
  });
  final String id;
  final String restaurantName;
  final String name;
  final bool active;
}

class StaffSession {
  const StaffSession({
    required this.name,
    required this.role,
    required this.branchIds,
  });
  final String name;
  final StaffRole role;
  final Set<String> branchIds;
  bool get canAct => role != StaffRole.viewer;
}

class ReservationRequest {
  const ReservationRequest({
    required this.id,
    required this.branchId,
    required this.guestName,
    this.guestPhone,
    required this.startsAt,
    required this.partySize,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.specialRequest,
    this.alternativeStartsAt,
  });
  final String id;
  final String branchId;
  final String guestName;
  final String? guestPhone;
  final DateTime startsAt;
  final int partySize;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? specialRequest;
  final DateTime? alternativeStartsAt;
  ReservationRequest copyWith({
    RequestStatus? status,
    DateTime? alternativeStartsAt,
  }) => ReservationRequest(
    id: id,
    branchId: branchId,
    guestName: guestName,
    guestPhone: guestPhone,
    startsAt: startsAt,
    partySize: partySize,
    status: status ?? this.status,
    createdAt: createdAt,
    expiresAt: expiresAt,
    specialRequest: specialRequest,
    alternativeStartsAt: alternativeStartsAt ?? this.alternativeStartsAt,
  );
}

class TodayReservation {
  const TodayReservation({
    required this.id,
    required this.branchId,
    required this.guestName,
    this.guestPhone,
    required this.startsAt,
    required this.partySize,
    required this.status,
    this.specialRequest,
  });
  final String id;
  final String branchId;
  final String guestName;
  final String? guestPhone;
  final DateTime startsAt;
  final int partySize;
  final TodayStatus status;
  final String? specialRequest;
  TodayReservation copyWith({TodayStatus? status}) => TodayReservation(
    id: id,
    branchId: branchId,
    guestName: guestName,
    guestPhone: guestPhone,
    startsAt: startsAt,
    partySize: partySize,
    status: status ?? this.status,
    specialRequest: specialRequest,
  );
}

class BranchPolicy {
  const BranchPolicy({
    this.mode = ReservationMode.requestFirst,
    this.gracePeriodMinutes = 15,
  });
  final ReservationMode mode;
  final int gracePeriodMinutes;
  BranchPolicy copyWith({ReservationMode? mode, int? gracePeriodMinutes}) =>
      BranchPolicy(
        mode: mode ?? this.mode,
        gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      );
}

class CommandException implements Exception {
  const CommandException(this.code);
  final String code;
}
