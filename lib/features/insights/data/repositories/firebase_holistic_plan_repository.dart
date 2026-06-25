import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fitup/core/database/fitup_database.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/services/logger_service.dart';

import '../../domain/entities/holistic_plan.dart';
import '../../domain/repositories/holistic_plan_repository.dart';

class FirebaseHolisticPlanRepository implements HolisticPlanRepository {
  FirebaseHolisticPlanRepository({
    required FirebaseFirestore firestore,
    required Connectivity connectivity,
    FitupDatabase? database,
    void Function(String userId)? onRemoteWriteFailed,
  })  : _firestore = firestore,
        _connectivity = connectivity,
        _db = database,
        _onRemoteWriteFailed = onRemoteWriteFailed;

  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;
  final FitupDatabase? _db;
  final void Function(String userId)? _onRemoteWriteFailed;

  String get _holisticPlansCollection => 'holisticPlans';

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _planDocPath(String userId, String planId) =>
      'users/$userId/$_holisticPlansCollection/$planId';

  bool _isOnline(List<ConnectivityResult> r) {
    return r.any(
      (ConnectivityResult c) =>
          c != ConnectivityResult.none && c != ConnectivityResult.bluetooth,
    );
  }

  Future<bool> _checkOnline() async {
    final List<ConnectivityResult> r = await _connectivity.checkConnectivity();
    return _isOnline(r);
  }

  static PlanTargets _targetsFromRow(HolisticPlanRow r) => PlanTargets(
        dailyStepGoal: r.dailyStepGoal ?? 0,
        dailyCalorieGoal: r.dailyCalorieGoal ?? 0,
        dailySleepGoalMinutes: r.dailySleepGoalMinutes ?? 0,
        dailyWaterGoalMl: r.dailyWaterGoalMl ?? 0,
        dailyWorkoutGoalMinutes: r.dailyWorkoutGoalMinutes ?? 0,
      );

  HolisticPlan _planFromRow({
    required String userId,
    required HolisticPlanRow plan,
    required List<ModulePlanRow> modules,
  }) {
    final Map<PlanModuleKey, ModulePlan> parsed = <PlanModuleKey, ModulePlan>{};
    for (final ModulePlanRow m in modules) {
      final PlanModuleKey? key = (() {
        try {
          return PlanModuleKey.values.firstWhere((PlanModuleKey k) => k.key == m.moduleKey);
        } catch (_) {
          return null;
        }
      })();
      if (key == null) {
        continue;
      }
      final Map<String, dynamic> payload = (jsonDecode(m.payloadJson) as Map)
          .cast<String, dynamic>();
      parsed[key] = ModulePlan(moduleKey: key, payload: payload);
    }

    final List<String> majorGoals = (jsonDecode(plan.majorGoalsJson) as List<dynamic>)
        .map((dynamic e) => e.toString())
        .toList();

    return HolisticPlan(
      id: plan.id,
      userId: userId,
      isActive: plan.isActive,
      startDate: plan.startDate,
      endDate: plan.endDate,
      dailyTargets: _targetsFromRow(plan),
      majorGoals: majorGoals,
      modulePlans: parsed,
      generatedAt: plan.createdAt,
      updatedAt: plan.updatedAt,
    );
  }

  @override
  Future<Either<Failure, HolisticPlan?>> getActivePlan(String userId) async {
    try {
      if (_db != null) {
        final HolisticPlanRow? row = await (_db!.select(_db!.holisticPlans)
              ..where(
                ($HolisticPlansTable t) => t.userId.equals(userId) &
                    t.isActive.equals(true),
              )
              ..limit(1))
            .getSingleOrNull();
        if (row == null) {
          return const Right<Failure, HolisticPlan?>(null);
        }
        final List<ModulePlanRow> modules = await (_db!.select(_db!.modulePlans)
              ..where(
                ($ModulePlansTable t) => t.holisticPlanId.equals(row.id),
              ))
            .get();
        return Right<Failure, HolisticPlan?>(_planFromRow(
          userId: userId,
          plan: row,
          modules: modules,
        ));
      }

      // Web fallback: fetch from Firestore.
      final QuerySnapshot<Map<String, dynamic>> snap =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection(_holisticPlansCollection)
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();
      if (snap.docs.isEmpty) {
        return const Right<Failure, HolisticPlan?>(null);
      }
      final DocumentSnapshot<Map<String, dynamic>> doc = snap.docs.first;
      final String planId = doc.id;
      final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
      final DateTime startDate = (data['startDate'] as Timestamp).toDate();
      final DateTime endDate = (data['endDate'] as Timestamp).toDate();
      final PlanTargets targets = PlanTargets(
        dailyStepGoal: (data['dailyStepGoal'] as num?)?.toInt() ?? 0,
        dailyCalorieGoal: (data['dailyCalorieGoal'] as num?)?.toInt() ?? 0,
        dailySleepGoalMinutes:
            (data['dailySleepGoalMinutes'] as num?)?.toInt() ?? 0,
        dailyWaterGoalMl: (data['dailyWaterGoalMl'] as num?)?.toInt() ?? 0,
        dailyWorkoutGoalMinutes:
            (data['dailyWorkoutGoalMinutes'] as num?)?.toInt() ?? 0,
      );
      final List<String> majorGoals = (data['majorGoals'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          <String>[];

      final QuerySnapshot<Map<String, dynamic>> modSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_holisticPlansCollection)
          .doc(planId)
          .collection('modulePlans')
          .get();
      final Map<PlanModuleKey, ModulePlan> modules = <PlanModuleKey, ModulePlan>{};
      for (final QueryDocumentSnapshot<Map<String, dynamic>> m in modSnap.docs) {
        final String moduleKey = m.id;
        PlanModuleKey key;
        try {
          key = PlanModuleKey.values.firstWhere((PlanModuleKey k) => k.key == moduleKey);
        } catch (_) {
          key = PlanModuleKey.activity;
        }
        final Map<String, dynamic> payload = m.data();
        modules[key] = ModulePlan(moduleKey: key, payload: payload);
      }
      final DateTime createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final DateTime updatedAt =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return Right<Failure, HolisticPlan?>(
        HolisticPlan(
          id: planId,
          userId: userId,
          isActive: true,
          startDate: startDate,
          endDate: endDate,
          dailyTargets: targets,
          majorGoals: majorGoals,
          modulePlans: modules,
          generatedAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    } catch (e, st) {
      LoggerService.e('getActivePlan', e, st);
      return Left<Failure, HolisticPlan?>(
        ServerFailure(e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, HolisticPlan>> saveNewActivePlan({
    required String userId,
    required HolisticPlanDraft draft,
    required DateTime generatedAt,
  }) async {
    try {
      final FitupDatabase? db = _db;
      final String planId =
          'plan_${userId}_${DateTime.now().microsecondsSinceEpoch}';
      final DateTime now = DateTime.now();

      if (db == null) {
        // Web: write straight to Firestore. No offline persistence.
        await _writePlanToRemote(
          userId: userId,
          planId: planId,
          draft: draft,
          generatedAt: generatedAt,
          updatedAt: now,
          setActive: true,
        );
        final Map<PlanModuleKey, ModulePlan> modules = draft.modulePlans;
        return Right<Failure, HolisticPlan>(
          HolisticPlan(
            id: planId,
            userId: userId,
            isActive: true,
            startDate: draft.startDate,
            endDate: draft.endDate,
            dailyTargets: draft.dailyTargets,
            majorGoals: draft.majorGoals,
            modulePlans: modules,
            generatedAt: generatedAt,
            updatedAt: now,
          ),
        );
      }

      // Offline-first: local write MUST succeed.
      await (db.update(db.holisticPlans)..where(($HolisticPlansTable t) {
            return t.userId.equals(userId) & t.isActive.equals(true);
          })).write(
        const HolisticPlansCompanion(isActive: Value<bool>(false)),
      );

      await db.into(db.holisticPlans).insertOnConflictUpdate(
            HolisticPlansCompanion.insert(
              id: planId,
              userId: userId,
              isActive: const Value<bool>(true),
              status: const Value<String>('active'),
              startDate: draft.startDate,
              endDate: draft.endDate,
              dailyStepGoal: Value(draft.dailyTargets.dailyStepGoal),
              dailyCalorieGoal: Value(draft.dailyTargets.dailyCalorieGoal),
              dailySleepGoalMinutes:
                  Value(draft.dailyTargets.dailySleepGoalMinutes),
              dailyWaterGoalMl: Value(draft.dailyTargets.dailyWaterGoalMl),
              dailyWorkoutGoalMinutes:
                  Value(draft.dailyTargets.dailyWorkoutGoalMinutes),
              majorGoalsJson: Value(jsonEncode(draft.majorGoals)),
              synced: const Value<bool>(false),
              createdAt: generatedAt,
              updatedAt: now,
            ),
          );

      final List<ModulePlan> modules = draft.modulePlans.values.toList();
      for (final ModulePlan m in modules) {
        final String modulePlanId = 'mp_${planId}_${m.moduleKey.key}';
        await db.into(db.modulePlans).insertOnConflictUpdate(
              ModulePlansCompanion.insert(
                id: modulePlanId,
                userId: userId,
                holisticPlanId: planId,
                moduleKey: m.moduleKey.key,
                payloadJson: jsonEncode(m.payload),
                synced: const Value<bool>(false),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // Best-effort sync now.
      final bool online = await _checkOnline();
      if (online) {
        final Either<Failure, Unit> remoteRes = await _tryWritePlanToRemote(
          userId: userId,
          planId: planId,
          draft: draft,
          generatedAt: generatedAt,
          updatedAt: now,
        );
        return remoteRes.fold(
          (Failure f) => Right<Failure, HolisticPlan>(
            HolisticPlan(
              id: planId,
              userId: userId,
              isActive: true,
              startDate: draft.startDate,
              endDate: draft.endDate,
              dailyTargets: draft.dailyTargets,
              majorGoals: draft.majorGoals,
              modulePlans: draft.modulePlans,
              generatedAt: generatedAt,
              updatedAt: now,
            ),
          ),
          (_) => Right<Failure, HolisticPlan>(
            HolisticPlan(
              id: planId,
              userId: userId,
              isActive: true,
              startDate: draft.startDate,
              endDate: draft.endDate,
              dailyTargets: draft.dailyTargets,
              majorGoals: draft.majorGoals,
              modulePlans: draft.modulePlans,
              generatedAt: generatedAt,
              updatedAt: now,
            ),
          ),
        );
      }

      return Right<Failure, HolisticPlan>(
        HolisticPlan(
          id: planId,
          userId: userId,
          isActive: true,
          startDate: draft.startDate,
          endDate: draft.endDate,
          dailyTargets: draft.dailyTargets,
          majorGoals: draft.majorGoals,
          modulePlans: draft.modulePlans,
          generatedAt: generatedAt,
          updatedAt: now,
        ),
      );
    } catch (e, st) {
      LoggerService.e('saveNewActivePlan', e, st);
      return Left<Failure, HolisticPlan>(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HolisticPlan>> updateActivePlanModules({
    required String userId,
    required HolisticPlan activePlan,
    required HolisticPlanDraft updatedDraft,
    required DateTime updatedAt,
  }) async {
    try {
      final FitupDatabase? db = _db;
      final DateTime now = DateTime.now();
      final DateTime preservedStart = activePlan.startDate;
      final DateTime preservedEnd = activePlan.endDate;

      final HolisticPlanDraft normalizedDraft = HolisticPlanDraft(
        startDate: preservedStart,
        endDate: preservedEnd,
        dailyTargets: updatedDraft.dailyTargets,
        majorGoals: updatedDraft.majorGoals,
        modulePlans: updatedDraft.modulePlans,
      );

      if (db == null) {
        await _writePlanToRemote(
          userId: userId,
          planId: activePlan.id,
          draft: normalizedDraft,
          generatedAt: activePlan.generatedAt,
          updatedAt: updatedAt,
          setActive: true,
        );
        return Right<Failure, HolisticPlan>(
          activePlan.copyWith(
            dailyTargets: normalizedDraft.dailyTargets,
            majorGoals: normalizedDraft.majorGoals,
            modulePlans: normalizedDraft.modulePlans,
            updatedAt: updatedAt,
          ),
        );
      }

      await (db.update(db.holisticPlans)..where(($HolisticPlansTable t) {
            return t.userId.equals(userId) & t.id.equals(activePlan.id);
          })).write(
        HolisticPlansCompanion(
          startDate: Value<DateTime>(preservedStart),
          endDate: Value<DateTime>(preservedEnd),
          dailyStepGoal: Value<int>(normalizedDraft.dailyTargets.dailyStepGoal),
          dailyCalorieGoal:
              Value<int>(normalizedDraft.dailyTargets.dailyCalorieGoal),
          dailySleepGoalMinutes: Value<int>(
              normalizedDraft.dailyTargets.dailySleepGoalMinutes),
          dailyWaterGoalMl:
              Value<int>(normalizedDraft.dailyTargets.dailyWaterGoalMl),
          dailyWorkoutGoalMinutes: Value<int>(
              normalizedDraft.dailyTargets.dailyWorkoutGoalMinutes),
          majorGoalsJson: Value<String>(jsonEncode(normalizedDraft.majorGoals)),
          updatedAt: Value<DateTime>(updatedAt),
          synced: const Value<bool>(false),
        ),
      );

      await (db.delete(db.modulePlans)
            ..where(($ModulePlansTable t) => t.holisticPlanId.equals(activePlan.id)))
          .go();

      for (final ModulePlan m in normalizedDraft.modulePlans.values) {
        final String modulePlanId = 'mp_${activePlan.id}_${m.moduleKey.key}';
        await db.into(db.modulePlans).insertOnConflictUpdate(
              ModulePlansCompanion.insert(
                id: modulePlanId,
                userId: userId,
                holisticPlanId: activePlan.id,
                moduleKey: m.moduleKey.key,
                payloadJson: jsonEncode(m.payload),
                synced: const Value<bool>(false),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      final bool online = await _checkOnline();
      if (online) {
        final Either<Failure, Unit> remoteRes = await _tryWritePlanToRemote(
          userId: userId,
          planId: activePlan.id,
          draft: normalizedDraft,
          generatedAt: activePlan.generatedAt,
          updatedAt: updatedAt,
        );
        return remoteRes.fold(
          (Failure _) => Right<Failure, HolisticPlan>(
            activePlan.copyWith(
              dailyTargets: normalizedDraft.dailyTargets,
              majorGoals: normalizedDraft.majorGoals,
              modulePlans: normalizedDraft.modulePlans,
              updatedAt: updatedAt,
            ),
          ),
          (_) => Right<Failure, HolisticPlan>(
            activePlan.copyWith(
              dailyTargets: normalizedDraft.dailyTargets,
              majorGoals: normalizedDraft.majorGoals,
              modulePlans: normalizedDraft.modulePlans,
              updatedAt: updatedAt,
            ),
          ),
        );
      }

      return Right<Failure, HolisticPlan>(
        activePlan.copyWith(
          dailyTargets: normalizedDraft.dailyTargets,
          majorGoals: normalizedDraft.majorGoals,
          modulePlans: normalizedDraft.modulePlans,
          updatedAt: updatedAt,
        ),
      );
    } catch (e, st) {
      LoggerService.e('updateActivePlanModules', e, st);
      return Left<Failure, HolisticPlan>(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlanDailyCheck?>> getDailyCheck({
    required String userId,
    required String holisticPlanId,
    required String dateKey,
  }) async {
    try {
      if (_db == null) {
        // Web fallback: load from remote.
        final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
            .doc('users/$userId/$_holisticPlansCollection/$holisticPlanId/dailyChecks/$dateKey')
            .get();
        if (!doc.exists) {
          return const Right<Failure, PlanDailyCheck?>(null);
        }
        final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
        final DateTime updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ??
            DateTime.now();
        return Right<Failure, PlanDailyCheck?>(
          PlanDailyCheck(
            id: doc.id,
            userId: userId,
            holisticPlanId: holisticPlanId,
            dateKey: dateKey,
            stepsCompleted: data['stepsCompleted'] as bool? ?? false,
            caloriesCompleted: data['caloriesCompleted'] as bool? ?? false,
            sleepCompleted: data['sleepCompleted'] as bool? ?? false,
            waterCompleted: data['waterCompleted'] as bool? ?? false,
            workoutCompleted: data['workoutCompleted'] as bool? ?? false,
            nudgeText: (data['nudgeText'] as String?) ?? '',
            updatedAt: updatedAt,
          ),
        );
      }

      final PlanDailyCheckRow? row = await (_db!.select(_db!.planDailyChecks)
            ..where(($PlanDailyChecksTable t) =>
                t.userId.equals(userId) &
                t.holisticPlanId.equals(holisticPlanId) &
                t.dateKey.equals(dateKey))
            ..limit(1))
          .getSingleOrNull();
      if (row == null) {
        return const Right<Failure, PlanDailyCheck?>(null);
      }
      return Right<Failure, PlanDailyCheck?>(
        PlanDailyCheck(
          id: row.id,
          userId: row.userId,
          holisticPlanId: row.holisticPlanId,
          dateKey: row.dateKey,
          stepsCompleted: row.stepsCompleted,
          caloriesCompleted: row.caloriesCompleted,
          sleepCompleted: row.sleepCompleted,
          waterCompleted: row.waterCompleted,
          workoutCompleted: row.workoutCompleted,
          nudgeText: row.nudgeText,
          updatedAt: row.updatedAt,
        ),
      );
    } catch (e, st) {
      LoggerService.e('getDailyCheck', e, st);
      return Left<Failure, PlanDailyCheck?>(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> upsertDailyCheck({
    required String userId,
    required PlanDailyCheck check,
  }) async {
    try {
      if (_db == null) {
        await _firestore
            .doc('users/$userId/$_holisticPlansCollection/${check.holisticPlanId}/dailyChecks/${check.dateKey}')
            .set(<String, dynamic>{
              'stepsCompleted': check.stepsCompleted,
              'caloriesCompleted': check.caloriesCompleted,
              'sleepCompleted': check.sleepCompleted,
              'waterCompleted': check.waterCompleted,
              'workoutCompleted': check.workoutCompleted,
              'nudgeText': check.nudgeText,
              'updatedAt': Timestamp.fromDate(check.updatedAt),
            }, SetOptions(merge: true));
        return const Right<Failure, Unit>(unit);
      }

      final FitupDatabase db = _db!;
      await db.into(db.planDailyChecks).insertOnConflictUpdate(
            PlanDailyChecksCompanion.insert(
              id: check.id,
              userId: check.userId,
              holisticPlanId: check.holisticPlanId,
              dateKey: check.dateKey,
              stepsCompleted: Value(check.stepsCompleted),
              caloriesCompleted: Value(check.caloriesCompleted),
              sleepCompleted: Value(check.sleepCompleted),
              waterCompleted: Value(check.waterCompleted),
              workoutCompleted: Value(check.workoutCompleted),
              nudgeText: Value(check.nudgeText),
              synced: const Value<bool>(false),
              createdAt: check.updatedAt,
              updatedAt: check.updatedAt,
            ),
          );

      final bool online = await _checkOnline();
      if (online) {
        await _firestore
            .doc('users/$userId/$_holisticPlansCollection/${check.holisticPlanId}/dailyChecks/${check.dateKey}')
            .set(<String, dynamic>{
              'stepsCompleted': check.stepsCompleted,
              'caloriesCompleted': check.caloriesCompleted,
              'sleepCompleted': check.sleepCompleted,
              'waterCompleted': check.waterCompleted,
              'workoutCompleted': check.workoutCompleted,
              'nudgeText': check.nudgeText,
              'updatedAt': Timestamp.fromDate(check.updatedAt),
            }, SetOptions(merge: true));

        await (db.update(db.planDailyChecks)..where(($PlanDailyChecksTable t) => t.id.equals(check.id)))
            .write(
          const PlanDailyChecksCompanion(synced: Value(true)),
        );
      }

      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('upsertDailyCheck', e, st);
      _onRemoteWriteFailed?.call(userId);
      return Left<Failure, Unit>(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> flushPendingPlansToRemote({
    required String userId,
  }) async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return const Right<Failure, Unit>(unit);
    }
    try {
      // 1) Flush active / stale plan rows.
      final List<HolisticPlanRow> pendingPlans = await (db.select(db.holisticPlans)
            ..where(
              ($HolisticPlansTable t) =>
                  t.userId.equals(userId) & t.synced.equals(false),
            ))
          .get();

      for (final HolisticPlanRow plan in pendingPlans) {
        final List<ModulePlanRow> moduleRows = await (db.select(db.modulePlans)
              ..where(
                ($ModulePlansTable t) =>
                    t.holisticPlanId.equals(plan.id),
              ))
            .get();

        final Map<PlanModuleKey, ModulePlan> modulePlans = <PlanModuleKey, ModulePlan>{};
        for (final ModulePlanRow m in moduleRows) {
          PlanModuleKey? key;
          try {
            key = PlanModuleKey.values.firstWhere((PlanModuleKey k) => k.key == m.moduleKey);
          } catch (_) {
            key = null;
          }
          if (key == null) continue;
          modulePlans[key] = ModulePlan(
            moduleKey: key,
            payload: (jsonDecode(m.payloadJson) as Map).cast<String, dynamic>(),
          );
        }

        final HolisticPlanDraft draft = HolisticPlanDraft(
          startDate: plan.startDate,
          endDate: plan.endDate,
          dailyTargets: _targetsFromRow(plan),
          majorGoals: (jsonDecode(plan.majorGoalsJson) as List<dynamic>)
              .map((dynamic e) => e.toString())
              .toList(),
          modulePlans: modulePlans,
        );

        await _writePlanToRemote(
          userId: userId,
          planId: plan.id,
          draft: draft,
          generatedAt: plan.createdAt,
          updatedAt: DateTime.now(),
          setActive: plan.isActive,
        );

        // Mark plan + modules synced.
        await (db.update(db.holisticPlans)..where(($HolisticPlansTable t) => t.id.equals(plan.id)))
            .write(
          const HolisticPlansCompanion(synced: Value(true)),
        );
        await (db.update(db.modulePlans)..where(($ModulePlansTable t) => t.holisticPlanId.equals(plan.id)))
            .write(
          const ModulePlansCompanion(synced: Value(true)),
        );

        // Flush daily checks too.
        final List<PlanDailyCheckRow> pendingChecks = await (db.select(db.planDailyChecks)
              ..where(
                ($PlanDailyChecksTable t) =>
                    t.holisticPlanId.equals(plan.id) & t.synced.equals(false),
              ))
            .get();

        for (final PlanDailyCheckRow c in pendingChecks) {
          await _firestore
              .doc('users/$userId/$_holisticPlansCollection/${plan.id}/dailyChecks/${c.dateKey}')
              .set(<String, dynamic>{
                'stepsCompleted': c.stepsCompleted,
                'caloriesCompleted': c.caloriesCompleted,
                'sleepCompleted': c.sleepCompleted,
                'waterCompleted': c.waterCompleted,
                'workoutCompleted': c.workoutCompleted,
                'nudgeText': c.nudgeText,
                'updatedAt': Timestamp.fromDate(c.updatedAt),
              }, SetOptions(merge: true));
        }
        if (pendingChecks.isNotEmpty) {
          await (db.update(db.planDailyChecks)
                ..where(($PlanDailyChecksTable t) =>
                    t.holisticPlanId.equals(plan.id)))
              .write(
            const PlanDailyChecksCompanion(synced: Value(true)),
          );
        }
      }

      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('flushPendingPlansToRemote', e, st);
      return Left<Failure, Unit>(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> _tryWritePlanToRemote({
    required String userId,
    required String planId,
    required HolisticPlanDraft draft,
    required DateTime generatedAt,
    required DateTime updatedAt,
  }) async {
    try {
      await _writePlanToRemote(
        userId: userId,
        planId: planId,
        draft: draft,
        generatedAt: generatedAt,
        updatedAt: updatedAt,
        setActive: true,
      );
      // Mark synced in local storage if available.
      if (_db != null) {
        final FitupDatabase db = _db!;
        await (db.update(db.holisticPlans)..where(($HolisticPlansTable t) => t.id.equals(planId)))
            .write(
          const HolisticPlansCompanion(synced: Value(true)),
        );
        await (db.update(db.modulePlans)
              ..where(($ModulePlansTable t) => t.holisticPlanId.equals(planId)))
            .write(
          const ModulePlansCompanion(synced: Value(true)),
        );
      }
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('_tryWritePlanToRemote', e, st);
      _onRemoteWriteFailed?.call(userId);
      return Left<Failure, Unit>(ServerFailure(e.toString()));
    }
  }

  Future<void> _writePlanToRemote({
    required String userId,
    required String planId,
    required HolisticPlanDraft draft,
    required DateTime generatedAt,
    required DateTime updatedAt,
    required bool setActive,
  }) async {
    await _firestore
        .doc('users/$userId/$_holisticPlansCollection/$planId')
        .set(<String, dynamic>{
          'userId': userId,
          'isActive': setActive,
          'status': 'active',
          'startDate': Timestamp.fromDate(draft.startDate),
          'endDate': Timestamp.fromDate(draft.endDate),
          'dailyStepGoal': draft.dailyTargets.dailyStepGoal,
          'dailyCalorieGoal': draft.dailyTargets.dailyCalorieGoal,
          'dailySleepGoalMinutes': draft.dailyTargets.dailySleepGoalMinutes,
          'dailyWaterGoalMl': draft.dailyTargets.dailyWaterGoalMl,
          'dailyWorkoutGoalMinutes': draft.dailyTargets.dailyWorkoutGoalMinutes,
          'majorGoals': draft.majorGoals,
          'createdAt': Timestamp.fromDate(generatedAt),
          'updatedAt': Timestamp.fromDate(updatedAt),
        }, SetOptions(merge: true));

    for (final ModulePlan m in draft.modulePlans.values) {
      await _firestore
          .doc('users/$userId/$_holisticPlansCollection/$planId/modulePlans/${m.moduleKey.key}')
          .set(m.payload, SetOptions(merge: true));
    }

    // Note: daily checks are synced separately via [flushPendingPlansToRemote].
  }
}

