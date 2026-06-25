import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/constants/env_config.dart';
import '../core/error/failures.dart';
import '../features/profile/domain/entities/profile_enums.dart';
import 'logger_service.dart';
import 'subscription_service.dart';

/// Product identifiers configured in RevenueCat / stores (Phase 9).
abstract final class RevenueCatProducts {
  static const String monthly = 'fitup_pro_monthly';
  static const String annual = 'fitup_pro_annual';
}

/// Entitlement identifier for Pro access.
const String kRevenueCatProEntitlementId = 'pro';

/// Live billing via RevenueCat (mobile only). Call [configureSdk] once after Firebase init.
class RevenueCatSubscriptionService implements SubscriptionService {
  RevenueCatSubscriptionService() {
    if (!kIsWeb && _sdkConfigured) {
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      unawaited(_emitCurrentTier());
    }
  }

  static bool _sdkConfigured = false;

  final StreamController<SubscriptionTier> _tierController =
      StreamController<SubscriptionTier>.broadcast();

  void _onCustomerInfo(CustomerInfo info) {
    _tierController.add(_tierFromCustomerInfo(info));
  }

  static SubscriptionTier _tierFromCustomerInfo(CustomerInfo info) {
    final EntitlementInfo? pro =
        info.entitlements.all[kRevenueCatProEntitlementId];
    final bool active = pro?.isActive ?? false;
    return active ? SubscriptionTier.pro : SubscriptionTier.free;
  }

  Future<void> _emitCurrentTier() async {
    if (kIsWeb || !_sdkConfigured) {
      _tierController.add(SubscriptionTier.free);
      return;
    }
    try {
      final CustomerInfo info = await Purchases.getCustomerInfo();
      _tierController.add(_tierFromCustomerInfo(info));
    } catch (e, st) {
      LoggerService.w('RevenueCat getCustomerInfo', e, st);
      _tierController.add(SubscriptionTier.free);
    }
  }

  /// Call once at startup (non-web). Safe to call when keys are empty (no-op).
  static Future<void> configureSdk() async {
    if (kIsWeb) {
      return;
    }
    final String apiKey = defaultTargetPlatform == TargetPlatform.iOS
        ? EnvConfig.revenueCatIosKey
        : EnvConfig.revenueCatAndroidKey;
    if (apiKey.isEmpty) {
      LoggerService.w(
        'RevenueCat API key missing — set REVENUE_CAT_ANDROID_KEY / REVENUE_CAT_IOS_KEY in .env',
      );
      _sdkConfigured = false;
      return;
    }
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
      final PurchasesConfiguration config = PurchasesConfiguration(apiKey);
      await Purchases.configure(config);
      _sdkConfigured = true;
    } catch (e, st) {
      LoggerService.e('RevenueCat configure', e, st);
      _sdkConfigured = false;
    }
  }

  /// Links RevenueCat to the signed-in Firebase user.
  @override
  Future<void> identifyUser(String userId) async {
    if (kIsWeb || !_sdkConfigured || userId.isEmpty) {
      return;
    }
    try {
      await Purchases.logIn(userId);
      await _emitCurrentTier();
    } catch (e, st) {
      LoggerService.w('RevenueCat logIn', e, st);
    }
  }

  /// Clears RevenueCat user on sign-out.
  @override
  Future<void> billingLogout() async {
    if (kIsWeb || !_sdkConfigured) {
      return;
    }
    try {
      await Purchases.logOut();
      _tierController.add(SubscriptionTier.free);
    } catch (e, st) {
      LoggerService.w('RevenueCat logOut', e, st);
    }
  }

  @override
  Stream<SubscriptionTier> watchTier(String userId) {
    if (userId.isEmpty) {
      return Stream<SubscriptionTier>.value(SubscriptionTier.free);
    }
    if (kIsWeb || !_sdkConfigured) {
      return Stream<SubscriptionTier>.value(SubscriptionTier.free);
    }
    return _tierController.stream;
  }

  @override
  Future<Either<Failure, Unit>> restorePurchases() async {
    if (kIsWeb || !_sdkConfigured) {
      return const Right<Failure, Unit>(unit);
    }
    try {
      await Purchases.restorePurchases();
      await _emitCurrentTier();
      return const Right<Failure, Unit>(unit);
    } on PlatformException catch (e) {
      return Left<Failure, Unit>(
        SubscriptionFailure(e.message ?? 'Restore failed'),
      );
    } catch (e) {
      return Left<Failure, Unit>(SubscriptionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> launchSubscriptionFlow() async {
    if (kIsWeb || !_sdkConfigured) {
      LoggerService.i('RevenueCat not configured — launchSubscriptionFlow skipped');
      return const Right<Failure, Unit>(unit);
    }
    try {
      final Offerings offerings = await Purchases.getOfferings();
      final Offering? current = offerings.current;
      if (current == null) {
        return const Left<Failure, Unit>(
          SubscriptionFailure('No subscription offerings'),
        );
      }
      final Package? pkg = _pickPackage(current);
      if (pkg == null) {
        return const Left<Failure, Unit>(
          SubscriptionFailure('No subscription packages'),
        );
      }
      await Purchases.purchase(PurchaseParams.package(pkg));
      await _emitCurrentTier();
      return const Right<Failure, Unit>(unit);
    } on PlatformException catch (e) {
      final PurchasesErrorCode code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const Right<Failure, Unit>(unit);
      }
      return Left<Failure, Unit>(
        SubscriptionFailure(e.message ?? code.name),
      );
    } catch (e) {
      return Left<Failure, Unit>(SubscriptionFailure(e.toString()));
    }
  }

  static Package? _pickPackage(Offering offering) {
    Package? annual;
    Package? monthly;
    for (final Package p in offering.availablePackages) {
      final String id = p.storeProduct.identifier;
      if (id == RevenueCatProducts.annual) {
        annual = p;
      } else if (id == RevenueCatProducts.monthly) {
        monthly = p;
      }
    }
    if (annual != null) {
      return annual;
    }
    if (monthly != null) {
      return monthly;
    }
    if (offering.availablePackages.isEmpty) {
      return null;
    }
    return offering.availablePackages.first;
  }
}
