import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/food.dart';
import '../repositories/food_repository.dart';

class ScanBarcodeUseCase {
  ScanBarcodeUseCase(this._repository);

  final FoodRepository _repository;

  Future<Either<Failure, Food?>> call(String barcode) =>
      _repository.getFoodByBarcode(barcode);
}
