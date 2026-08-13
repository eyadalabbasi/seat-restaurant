import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app.dart';
import 'copy.dart';
import 'formatting.dart';
import 'models.dart';
import 'operations.dart';
import 'theme.dart';

String _requestStatus(RequestStatus s, SeatCopy c) => switch (s) {
  RequestStatus.requested => c.t('New request', 'طلب جديد'),
  RequestStatus.underReview => c.t('Under review', 'قيد المراجعة'),
  RequestStatus.alternativeProposed => c.t('Time suggested', 'تم اقتراح وقت'),
};
String _todayStatus(TodayStatus s, SeatCopy c) => switch (s) {
  TodayStatus.confirmed => c.t('Confirmed', 'مؤكد'),
  TodayStatus.checkedIn => c.t('Checked in', 'تم تسجيل الحضور'),
  TodayStatus.completed => c.t('Completed', 'مكتمل'),
  TodayStatus.noShow => c.t('No show', 'لم يحضر'),
};
Color _statusColor(Object status) => status == RequestStatus.requested
    ? SeatColors.warning
    : status == TodayStatus.confirmed
    ? SeatColors.success
    : status == TodayStatus.noShow
    ? SeatColors.destructive
    : SeatColors.secondaryText;
Widget _chip(String label, Object status) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: _statusColor(status).withValues(alpha: .1),
    borderRadius: BorderRadius.circular(99),
  ),
  child: Text(
    label,
    style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w700),
  ),
);
void _error(BuildContext context, String? code) {
  if (code == null) return;
  final c = SeatCopy.of(context);
  final message = switch (code) {
    'RESERVATION_NOT_AVAILABLE' => c.t(
      'This time is no longer available. Suggest another time.',
      'هذا الوقت لم يعد متاحاً. اقترح وقتاً آخر.',
    ),
    'RESERVATION_ALREADY_PROCESSED' => c.t(
      'This request was already processed.',
      'تمت معالجة هذا الطلب بالفعل.',
    ),
    'NO_SHOW_NOT_YET_ALLOWED' => c.t(
      'No-show is available after the grace period.',
      'يمكن تسجيل عدم الحضور بعد فترة السماح.',
    ),
    'INSUFFICIENT_PERMISSION' => c.t(
      'You do not have permission for this action.',
      'ليس لديك صلاحية لهذا الإجراء.',
    ),
    _ => c.t(
      'Something went wrong. Please try again.',
      'حدث خطأ. حاول مرة أخرى.',
    ),
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 700), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SeatColors.primaryText,
    body: Center(
      child: Semantics(
        label: 'SEAT Restaurant',
        child: Image.asset(
          'assets/branding/seat-mark-transparent.png',
          width: 180,
          height: 180,
        ),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phone = TextEditingController(text: '+973 3333');
  @override
  Widget build(BuildContext context) {
    final c = SeatCopy.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'SEAT',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: SeatColors.accent,
                  letterSpacing: 5,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                c.t('Restaurant staff login', 'دخول موظفي المطعم'),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                c.t(
                  'Use your authorized staff phone number.',
                  'استخدم رقم هاتف الموظف المصرح له.',
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: c.t('Phone number', 'رقم الهاتف'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push(
                  '/otp?phone=${Uri.encodeComponent(phone.text)}',
                ),
                child: Text(c.t('Continue', 'متابعة')),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  final container = ProviderScope.containerOf(context);
                  container.read(localeProvider.notifier).state =
                      Localizations.localeOf(context).languageCode == 'en'
                      ? const Locale('ar')
                      : const Locale('en');
                },
                child: Text(c.t('العربية', 'English')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});
  final String phone;
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final otp = TextEditingController(text: '123456');
  @override
  Widget build(BuildContext context) {
    final c = SeatCopy.of(context);
    final state = ref.watch(operationsProvider);
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              c.t('Enter verification code', 'أدخل رمز التحقق'),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(
              c.t('Sent to ${widget.phone}', 'تم إرساله إلى ${widget.phone}'),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: otp,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: c.t('6-digit code', 'رمز من 6 أرقام'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.busy
                  ? null
                  : () async {
                      await ref
                          .read(operationsProvider)
                          .login(widget.phone, otp.text);
                      if (!context.mounted) return;
                      _error(context, ref.read(operationsProvider).errorCode);
                      final s = ref.read(operationsProvider);
                      if (s.session != null)
                        context.go(
                          s.branches.length == 1 ? '/inbox' : '/branches',
                        );
                    },
              child: state.busy
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(c.t('Verify', 'تحقق')),
            ),
          ],
        ),
      ),
    );
  }
}

class BranchSelectionScreen extends ConsumerWidget {
  const BranchSelectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SeatCopy.of(context);
    final state = ref.watch(operationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(c.t('Choose a branch', 'اختر الفرع'))),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: state.branches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final b = state.branches[i];
          return Card(
            child: ListTile(
              minTileHeight: 76,
              title: Text(
                b.restaurantName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(b.name),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () async {
                await ref.read(operationsProvider).selectBranch(b);
                if (context.mounted) context.go('/inbox');
              },
            ),
          );
        },
      ),
    );
  }
}

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SeatCopy.of(context), state = ref.watch(operationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.inbox),
            if (state.selectedBranch != null)
              Text(
                state.selectedBranch!.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: state.busy && state.inbox.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.inbox.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 180),
                  Icon(
                    Icons.inbox_outlined,
                    size: 52,
                    color: SeatColors.secondaryText,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      c.t('No requests waiting', 'لا توجد طلبات بانتظارك'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.inbox.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => RequestCard(request: state.inbox[i]),
              ),
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request});
  final ReservationRequest request;
  @override
  Widget build(BuildContext context) {
    final c = SeatCopy.of(context),
        lang = Localizations.localeOf(context).languageCode;
    return Semantics(
      button: true,
      label: '${request.guestName}, ${_requestStatus(request.status, c)}',
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/inbox/request/${request.id}'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.guestName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _chip(_requestStatus(request.status, c), request.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  seatDateTime(request.startsAt, lang),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      c.t(
                        '${request.partySize} guests',
                        '${request.partySize} ضيوف',
                      ),
                    ),
                    if (request.specialRequest != null) ...[
                      const Spacer(),
                      const Icon(Icons.note_outlined, size: 20),
                      const SizedBox(width: 4),
                      Text(c.t('Note', 'ملاحظة')),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  requestAge(request.createdAt, DateTime.now(), lang),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RequestDetailsScreen extends ConsumerWidget {
  const RequestDetailsScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SeatCopy.of(context),
        state = ref.watch(operationsProvider),
        lang = Localizations.localeOf(context).languageCode;
    final matches = state.inbox.where((e) => e.id == id);
    if (matches.isEmpty)
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            c.t('Request no longer actionable', 'لم يعد الطلب متاحاً'),
          ),
        ),
      );
    final r = matches.first,
        canAct =
            state.session?.canAct == true &&
            r.status != RequestStatus.alternativeProposed;
    return Scaffold(
      appBar: AppBar(title: Text(c.t('Request details', 'تفاصيل الطلب'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _chip(_requestStatus(r.status, c), r.status),
          const SizedBox(height: 24),
          Text(r.guestName, style: Theme.of(context).textTheme.headlineLarge),
          if (r.guestPhone != null)
            Text(r.guestPhone!, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          _Info(
            icon: Icons.schedule,
            title: c.t('Requested time', 'الوقت المطلوب'),
            value: seatDateTime(r.startsAt, lang),
          ),
          _Info(
            icon: Icons.people_outline,
            title: c.t('Party size', 'عدد الضيوف'),
            value: c.t('${r.partySize} guests', '${r.partySize} ضيوف'),
          ),
          if (r.specialRequest != null)
            _Info(
              icon: Icons.note_outlined,
              title: c.t('Special request', 'طلب خاص'),
              value: r.specialRequest!,
            ),
          if (r.alternativeStartsAt != null)
            _Info(
              icon: Icons.update,
              title: c.t('Suggested time', 'الوقت المقترح'),
              value: seatDateTime(r.alternativeStartsAt!, lang),
            ),
          const SizedBox(height: 18),
          if (canAct) ...[
            FilledButton(
              onPressed: state.busy
                  ? null
                  : () async {
                      await ref.read(operationsProvider).confirm(id);
                      if (!context.mounted) return;
                      _error(context, ref.read(operationsProvider).errorCode);
                      if (ref.read(operationsProvider).errorCode == null)
                        context.go('/today');
                    },
              child: Text(c.t('Confirm', 'تأكيد')),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.push('/inbox/request/$id/suggest'),
              child: Text(c.t('Suggest another time', 'اقترح وقتاً آخر')),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: SeatColors.destructive,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => _declineDialog(context, ref, id),
              child: Text(c.t('Decline', 'رفض')),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _declineDialog(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  final c = SeatCopy.of(context), reason = TextEditingController();
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            c.t('Decline this request?', 'رفض هذا الطلب؟'),
            style: Theme.of(ctx).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            c.t(
              'The customer will receive a simple decline message.',
              'سيستلم العميل رسالة رفض مختصرة.',
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: reason,
            decoration: InputDecoration(
              labelText: c.t(
                'Internal reason (optional)',
                'السبب الداخلي (اختياري)',
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SeatColors.destructive,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(c.t('Decline request', 'رفض الطلب')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(c.t('Keep request', 'الاحتفاظ بالطلب')),
          ),
        ],
      ),
    ),
  );
  if (ok == true) {
    await ref.read(operationsProvider).decline(id, reason.text);
    if (context.mounted) {
      _error(context, ref.read(operationsProvider).errorCode);
      if (ref.read(operationsProvider).errorCode == null) context.go('/inbox');
    }
  }
}

class SuggestTimeScreen extends ConsumerStatefulWidget {
  const SuggestTimeScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<SuggestTimeScreen> createState() => _SuggestTimeScreenState();
}

class _SuggestTimeScreenState extends ConsumerState<SuggestTimeScreen> {
  late Future<List<DateTime>> times;
  DateTime? selected;
  @override
  void initState() {
    super.initState();
    times = ref.read(repositoryProvider).alternatives(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = SeatCopy.of(context),
        lang = Localizations.localeOf(context).languageCode;
    final r = ref
        .watch(operationsProvider)
        .inbox
        .firstWhere((e) => e.id == widget.id);
    return Scaffold(
      appBar: AppBar(title: Text(c.t('Suggest time', 'اقتراح وقت'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              c.t('Original request', 'الطلب الأصلي'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              seatDateTime(r.startsAt, lang),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Text(
              c.t('Available alternatives', 'الأوقات البديلة المتاحة'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<DateTime>>(
                future: times,
                builder: (_, s) {
                  if (!s.hasData)
                    return const Center(child: CircularProgressIndicator());
                  return ListView.separated(
                    itemCount: s.data!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final time = s.data![i];
                      return Card(
                        child: RadioListTile<DateTime>(
                          value: time,
                          groupValue: selected,
                          title: Text(seatDateTime(time, lang)),
                          onChanged: (v) => setState(() => selected = v),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () async {
                      await ref
                          .read(operationsProvider)
                          .propose(widget.id, selected!);
                      if (!context.mounted) return;
                      _error(context, ref.read(operationsProvider).errorCode);
                      if (ref.read(operationsProvider).errorCode == null)
                        context.pop();
                    },
              child: Text(c.t('Send suggested time', 'إرسال الوقت المقترح')),
            ),
          ],
        ),
      ),
    );
  }
}

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SeatCopy.of(context),
        state = ref.watch(operationsProvider),
        lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(c.today)),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.today.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = state.today[i];
            return Card(
              child: ListTile(
                minTileHeight: 86,
                onTap: () => context.push('/today/reservation/${r.id}'),
                title: Text(
                  r.guestName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${seatDateTime(r.startsAt, lang)}\n${c.t('${r.partySize} guests', '${r.partySize} ضيوف')}',
                ),
                isThreeLine: true,
                trailing: _chip(_todayStatus(r.status, c), r.status),
              ),
            );
          },
        ),
      ),
    );
  }
}

class OperationalDetailsScreen extends ConsumerWidget {
  const OperationalDetailsScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SeatCopy.of(context),
        state = ref.watch(operationsProvider),
        lang = Localizations.localeOf(context).languageCode;
    final r = state.today.firstWhere((e) => e.id == id);
    final can = state.session?.canAct == true;
    return Scaffold(
      appBar: AppBar(title: Text(c.t('Reservation details', 'تفاصيل الحجز'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _chip(_todayStatus(r.status, c), r.status),
          const SizedBox(height: 24),
          Text(r.guestName, style: Theme.of(context).textTheme.headlineLarge),
          if (r.guestPhone != null)
            Text(r.guestPhone!, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 22),
          _Info(
            icon: Icons.schedule,
            title: c.t('Reservation time', 'وقت الحجز'),
            value: seatDateTime(r.startsAt, lang),
          ),
          _Info(
            icon: Icons.people_outline,
            title: c.t('Party size', 'عدد الضيوف'),
            value: c.t('${r.partySize} guests', '${r.partySize} ضيوف'),
          ),
          if (r.specialRequest != null)
            _Info(
              icon: Icons.note_outlined,
              title: c.t('Special request', 'طلب خاص'),
              value: r.specialRequest!,
            ),
          const SizedBox(height: 24),
          if (can && r.status == TodayStatus.confirmed) ...[
            FilledButton(
              onPressed: () => _confirmAction(
                context,
                c.t('Check this guest in?', 'تسجيل حضور الضيف؟'),
                c.t('Check In', 'تسجيل الحضور'),
                () => ref.read(operationsProvider).checkIn(id),
                ref,
              ),
              child: Text(c.t('Check In', 'تسجيل الحضور')),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _confirmAction(
                context,
                c.t('Mark as no show?', 'تسجيل عدم الحضور؟'),
                c.t('Mark No Show', 'تسجيل عدم الحضور'),
                () => ref.read(operationsProvider).noShow(id),
                ref,
              ),
              child: Text(c.t('Mark No Show', 'تسجيل عدم الحضور')),
            ),
          ],
          if (can && r.status == TodayStatus.checkedIn)
            FilledButton(
              onPressed: () => _confirmAction(
                context,
                c.t('Complete this reservation?', 'إكمال هذا الحجز؟'),
                c.t('Complete', 'إكمال'),
                () => ref.read(operationsProvider).complete(id),
                ref,
              ),
              child: Text(c.t('Complete', 'إكمال')),
            ),
        ],
      ),
    );
  }
}

Future<void> _confirmAction(
  BuildContext context,
  String title,
  String action,
  Future<void> Function() command,
  WidgetRef ref,
) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  if (yes == true) {
    await command();
    if (context.mounted) {
      _error(context, ref.read(operationsProvider).errorCode);
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SeatCopy.of(context), state = ref.watch(operationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(c.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.selectedBranch != null)
            _SettingsTile(
              icon: Icons.storefront,
              title: c.t('Selected branch', 'الفرع المختار'),
              subtitle: state.selectedBranch!.name,
              onTap: () => context.push('/branches'),
            ),
          _SettingsTile(
            icon: Icons.event_available,
            title: c.t('Reservation policy', 'سياسة الحجوزات'),
            subtitle: state.policy.mode == ReservationMode.requestFirst
                ? c.t('Request first', 'الطلب أولاً')
                : c.t('Instant confirmation', 'تأكيد فوري'),
            onTap: () => context.push('/settings/policy'),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: c.t('Notification preferences', 'تفضيلات الإشعارات'),
            subtitle: c.t(
              'Operational alerts on',
              'التنبيهات التشغيلية مفعّلة',
            ),
          ),
          _SettingsTile(
            icon: Icons.person_outline,
            title: c.t('Profile', 'الملف الشخصي'),
            subtitle: state.session?.name,
            onTap: () => context.push('/settings/profile'),
          ),
          _SettingsTile(
            icon: Icons.language,
            title: c.t('Language', 'اللغة'),
            subtitle: c.t('English', 'العربية'),
            onTap: () {
              ref.read(localeProvider.notifier).state = c.ar
                  ? const Locale('en')
                  : const Locale('ar');
            },
          ),
          const SizedBox(height: 20),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: SeatColors.destructive,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () async {
              await ref.read(operationsProvider).logout();
              if (context.mounted) context.go('/login');
            },
            child: Text(c.t('Log out', 'تسجيل الخروج')),
          ),
        ],
      ),
    );
  }
}

class PolicyScreen extends ConsumerStatefulWidget {
  const PolicyScreen({super.key});
  @override
  ConsumerState<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends ConsumerState<PolicyScreen> {
  @override
  Widget build(BuildContext context) {
    final c = SeatCopy.of(context), p = ref.watch(operationsProvider).policy;
    return Scaffold(
      appBar: AppBar(title: Text(c.t('Reservation policy', 'سياسة الحجوزات'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            c.t('Confirmation mode', 'وضع التأكيد'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          RadioListTile(
            value: ReservationMode.requestFirst,
            groupValue: p.mode,
            title: Text(c.t('Request first', 'الطلب أولاً')),
            subtitle: Text(
              c.t('Staff reviews every request.', 'يراجع الموظفون كل طلب.'),
            ),
            onChanged: (v) => _save(p.copyWith(mode: v)),
          ),
          RadioListTile(
            value: ReservationMode.instantConfirmation,
            groupValue: p.mode,
            title: Text(c.t('Instant confirmation', 'تأكيد فوري')),
            subtitle: Text(
              c.t(
                'Confirm automatically when available.',
                'تأكيد تلقائي عند توفر الحجز.',
              ),
            ),
            onChanged: (v) => _save(p.copyWith(mode: v)),
          ),
          const Divider(height: 36),
          Text(
            c.t('No-show policy', 'سياسة عدم الحضور'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: p.gracePeriodMinutes,
            decoration: InputDecoration(
              labelText: c.t('Grace period', 'فترة السماح'),
            ),
            items: [5, 10, 15, 20, 30]
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(c.t('$m minutes', '$m دقيقة')),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) _save(p.copyWith(gracePeriodMinutes: v));
            },
          ),
          const SizedBox(height: 16),
          _Info(
            icon: Icons.notifications_active_outlined,
            title: c.t('After grace period', 'بعد فترة السماح'),
            value: c.t(
              'Notify staff to decide',
              'إشعار الموظفين لاتخاذ القرار',
            ),
          ),
        ],
      ),
    );
  }

  void _save(BranchPolicy p) => ref.read(operationsProvider).savePolicy(p);
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SeatCopy.of(context), s = ref.watch(operationsProvider).session;
    return Scaffold(
      appBar: AppBar(title: Text(c.t('Profile', 'الملف الشخصي'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(
              radius: 42,
              backgroundColor: SeatColors.secondaryBackground,
              child: Icon(Icons.person, size: 42, color: SeatColors.accent),
            ),
            const SizedBox(height: 18),
            Text(
              s?.name ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              s?.role.name.toUpperCase() ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
            _Info(
              icon: Icons.security,
              title: c.t('Access', 'الصلاحيات'),
              value: s?.canAct == true
                  ? c.t('Can process requests', 'يمكنه معالجة الطلبات')
                  : c.t('View only', 'عرض فقط'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: SeatColors.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
      child: ListTile(
        minTileHeight: 70,
        leading: Icon(icon, color: SeatColors.accent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    ),
  );
}
