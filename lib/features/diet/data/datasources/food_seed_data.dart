import '../../domain/entities/food.dart';

/// 300+ seed entries covering North Indian, South Indian, Bengali,
/// Continental, American, Italian, Indo-Chinese, and Indian packaged foods.
/// All values are per 100 g unless noted otherwise.
const List<Food> kFoodSeedDatabase = <Food>[
  // ───────────────────── NORTH INDIAN ─────────────────────
  Food(id: 'seed_ni_001', name: 'Dal Makhani', caloriesPer100g: 126, proteinPer100g: 5.5, carbsPer100g: 12.0, fatPer100g: 6.5, fiberPer100g: 3.2, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_002', name: 'Paneer Butter Masala', caloriesPer100g: 196, proteinPer100g: 8.0, carbsPer100g: 8.5, fatPer100g: 15.0, fiberPer100g: 1.2, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_003', name: 'Chole (Chickpea Curry)', caloriesPer100g: 140, proteinPer100g: 7.0, carbsPer100g: 18.0, fatPer100g: 4.5, fiberPer100g: 5.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_004', name: 'Rajma (Kidney Bean Curry)', caloriesPer100g: 127, proteinPer100g: 7.5, carbsPer100g: 17.0, fatPer100g: 3.0, fiberPer100g: 6.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_005', name: 'Aloo Gobi', caloriesPer100g: 80, proteinPer100g: 2.5, carbsPer100g: 10.0, fatPer100g: 3.5, fiberPer100g: 2.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_006', name: 'Aloo Paratha', caloriesPer100g: 220, proteinPer100g: 5.0, carbsPer100g: 30.0, fatPer100g: 9.0, fiberPer100g: 2.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_007', name: 'Tandoori Roti', caloriesPer100g: 260, proteinPer100g: 8.7, carbsPer100g: 49.0, fatPer100g: 3.5, fiberPer100g: 3.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_008', name: 'Naan (Plain)', caloriesPer100g: 310, proteinPer100g: 8.5, carbsPer100g: 52.0, fatPer100g: 7.5, fiberPer100g: 2.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_009', name: 'Butter Naan', caloriesPer100g: 340, proteinPer100g: 8.0, carbsPer100g: 50.0, fatPer100g: 12.0, fiberPer100g: 2.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_010', name: 'Jeera Rice', caloriesPer100g: 148, proteinPer100g: 3.0, carbsPer100g: 28.0, fatPer100g: 2.5, fiberPer100g: 0.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_011', name: 'Palak Paneer', caloriesPer100g: 149, proteinPer100g: 8.0, carbsPer100g: 5.5, fatPer100g: 11.0, fiberPer100g: 2.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_012', name: 'Shahi Paneer', caloriesPer100g: 210, proteinPer100g: 8.5, carbsPer100g: 7.0, fatPer100g: 17.0, fiberPer100g: 1.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_013', name: 'Kadhai Paneer', caloriesPer100g: 185, proteinPer100g: 9.0, carbsPer100g: 6.0, fatPer100g: 14.0, fiberPer100g: 1.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_014', name: 'Matar Paneer', caloriesPer100g: 155, proteinPer100g: 8.0, carbsPer100g: 9.0, fatPer100g: 10.0, fiberPer100g: 3.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_015', name: 'Malai Kofta', caloriesPer100g: 230, proteinPer100g: 6.0, carbsPer100g: 14.0, fatPer100g: 17.0, fiberPer100g: 1.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_016', name: 'Dal Tadka', caloriesPer100g: 105, proteinPer100g: 6.0, carbsPer100g: 13.0, fatPer100g: 3.5, fiberPer100g: 3.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_017', name: 'Yellow Moong Dal', caloriesPer100g: 95, proteinPer100g: 6.5, carbsPer100g: 12.5, fatPer100g: 2.0, fiberPer100g: 2.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_018', name: 'Baingan Bharta', caloriesPer100g: 72, proteinPer100g: 1.5, carbsPer100g: 6.0, fatPer100g: 4.5, fiberPer100g: 3.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_019', name: 'Bhindi Masala (Okra)', caloriesPer100g: 85, proteinPer100g: 2.0, carbsPer100g: 7.0, fatPer100g: 5.5, fiberPer100g: 3.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_020', name: 'Lauki Sabzi (Bottle Gourd)', caloriesPer100g: 55, proteinPer100g: 1.5, carbsPer100g: 6.5, fatPer100g: 2.5, fiberPer100g: 1.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_021', name: 'Tinda Masala', caloriesPer100g: 60, proteinPer100g: 1.5, carbsPer100g: 7.0, fatPer100g: 3.0, fiberPer100g: 2.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_022', name: 'Methi Thepla', caloriesPer100g: 250, proteinPer100g: 7.0, carbsPer100g: 35.0, fatPer100g: 9.0, fiberPer100g: 4.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_023', name: 'Gobi Paratha', caloriesPer100g: 210, proteinPer100g: 5.0, carbsPer100g: 28.0, fatPer100g: 8.5, fiberPer100g: 2.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_024', name: 'Paneer Paratha', caloriesPer100g: 245, proteinPer100g: 8.5, carbsPer100g: 27.0, fatPer100g: 11.0, fiberPer100g: 1.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_025', name: 'Plain Paratha', caloriesPer100g: 280, proteinPer100g: 6.0, carbsPer100g: 38.0, fatPer100g: 11.5, fiberPer100g: 2.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_026', name: 'Chapati (Whole Wheat)', caloriesPer100g: 240, proteinPer100g: 8.0, carbsPer100g: 45.0, fatPer100g: 3.0, fiberPer100g: 3.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_027', name: 'Poori (Fried Bread)', caloriesPer100g: 320, proteinPer100g: 6.5, carbsPer100g: 40.0, fatPer100g: 15.0, fiberPer100g: 2.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_028', name: 'Samosa (Potato)', caloriesPer100g: 260, proteinPer100g: 4.0, carbsPer100g: 28.0, fatPer100g: 14.5, fiberPer100g: 2.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_029', name: 'Pakora (Onion Bhaji)', caloriesPer100g: 285, proteinPer100g: 5.0, carbsPer100g: 22.0, fatPer100g: 20.0, fiberPer100g: 3.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_030', name: 'Kachori', caloriesPer100g: 310, proteinPer100g: 5.5, carbsPer100g: 30.0, fatPer100g: 19.0, fiberPer100g: 2.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_031', name: 'Raita (Boondi)', caloriesPer100g: 85, proteinPer100g: 3.0, carbsPer100g: 7.0, fatPer100g: 5.0, fiberPer100g: 0.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_032', name: 'Lassi (Sweet)', caloriesPer100g: 90, proteinPer100g: 3.0, carbsPer100g: 14.0, fatPer100g: 2.5, fiberPer100g: 0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_033', name: 'Lassi (Salted)', caloriesPer100g: 60, proteinPer100g: 3.0, carbsPer100g: 5.0, fatPer100g: 2.5, fiberPer100g: 0, sodiumPer100g: 250, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_034', name: 'Biryani (Veg)', caloriesPer100g: 155, proteinPer100g: 3.5, carbsPer100g: 22.0, fatPer100g: 6.0, fiberPer100g: 1.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_035', name: 'Chicken Biryani', caloriesPer100g: 175, proteinPer100g: 9.0, carbsPer100g: 20.0, fatPer100g: 7.0, fiberPer100g: 0.8, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_036', name: 'Mutton Biryani', caloriesPer100g: 185, proteinPer100g: 10.0, carbsPer100g: 19.0, fatPer100g: 8.0, fiberPer100g: 0.8, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_037', name: 'Butter Chicken', caloriesPer100g: 175, proteinPer100g: 14.0, carbsPer100g: 6.0, fatPer100g: 11.0, fiberPer100g: 0.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_038', name: 'Chicken Tikka', caloriesPer100g: 165, proteinPer100g: 20.0, carbsPer100g: 5.0, fatPer100g: 7.5, fiberPer100g: 0.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_039', name: 'Tandoori Chicken', caloriesPer100g: 150, proteinPer100g: 22.0, carbsPer100g: 3.0, fatPer100g: 5.5, fiberPer100g: 0.3, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_040', name: 'Chicken Curry (Gravy)', caloriesPer100g: 145, proteinPer100g: 12.0, carbsPer100g: 5.0, fatPer100g: 9.0, fiberPer100g: 0.8, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_041', name: 'Mutton Curry', caloriesPer100g: 155, proteinPer100g: 13.0, carbsPer100g: 5.0, fatPer100g: 10.0, fiberPer100g: 0.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_042', name: 'Egg Curry', caloriesPer100g: 120, proteinPer100g: 8.0, carbsPer100g: 5.0, fatPer100g: 8.0, fiberPer100g: 0.8, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_043', name: 'Keema (Minced Mutton)', caloriesPer100g: 190, proteinPer100g: 15.0, carbsPer100g: 4.0, fatPer100g: 13.0, fiberPer100g: 0.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_044', name: 'Fish Curry (North)', caloriesPer100g: 110, proteinPer100g: 14.0, carbsPer100g: 4.0, fatPer100g: 4.5, fiberPer100g: 0.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_045', name: 'Mixed Veg Curry', caloriesPer100g: 75, proteinPer100g: 2.5, carbsPer100g: 8.0, fatPer100g: 3.5, fiberPer100g: 3.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_046', name: 'Dum Aloo', caloriesPer100g: 130, proteinPer100g: 3.0, carbsPer100g: 15.0, fatPer100g: 6.5, fiberPer100g: 1.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_047', name: 'Kadhi Pakora', caloriesPer100g: 90, proteinPer100g: 3.5, carbsPer100g: 8.0, fatPer100g: 5.0, fiberPer100g: 1.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_048', name: 'Aloo Tikki', caloriesPer100g: 180, proteinPer100g: 3.5, carbsPer100g: 22.0, fatPer100g: 9.0, fiberPer100g: 2.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_049', name: 'Pav Bhaji', caloriesPer100g: 155, proteinPer100g: 4.0, carbsPer100g: 18.0, fatPer100g: 8.0, fiberPer100g: 3.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ni_050', name: 'Chole Bhature', caloriesPer100g: 280, proteinPer100g: 7.0, carbsPer100g: 30.0, fatPer100g: 15.0, fiberPer100g: 3.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── SOUTH INDIAN ─────────────────────
  Food(id: 'seed_si_001', name: 'Plain Dosa', caloriesPer100g: 165, proteinPer100g: 4.0, carbsPer100g: 28.0, fatPer100g: 4.0, fiberPer100g: 1.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_002', name: 'Masala Dosa', caloriesPer100g: 185, proteinPer100g: 4.5, carbsPer100g: 25.0, fatPer100g: 7.5, fiberPer100g: 2.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_003', name: 'Idli (Steamed)', caloriesPer100g: 125, proteinPer100g: 4.0, carbsPer100g: 24.0, fatPer100g: 0.5, fiberPer100g: 1.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_004', name: 'Vada (Medu)', caloriesPer100g: 270, proteinPer100g: 10.0, carbsPer100g: 24.0, fatPer100g: 15.0, fiberPer100g: 3.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_005', name: 'Sambar', caloriesPer100g: 65, proteinPer100g: 3.0, carbsPer100g: 9.0, fatPer100g: 1.5, fiberPer100g: 2.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_006', name: 'Coconut Chutney', caloriesPer100g: 175, proteinPer100g: 3.0, carbsPer100g: 8.0, fatPer100g: 15.0, fiberPer100g: 3.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_007', name: 'Rasam', caloriesPer100g: 30, proteinPer100g: 1.5, carbsPer100g: 4.5, fatPer100g: 0.5, fiberPer100g: 0.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_008', name: 'Upma', caloriesPer100g: 140, proteinPer100g: 3.5, carbsPer100g: 20.0, fatPer100g: 5.0, fiberPer100g: 1.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_009', name: 'Pongal (Ven)', caloriesPer100g: 125, proteinPer100g: 3.5, carbsPer100g: 18.0, fatPer100g: 4.5, fiberPer100g: 1.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_010', name: 'Uttapam', caloriesPer100g: 175, proteinPer100g: 5.0, carbsPer100g: 26.0, fatPer100g: 5.5, fiberPer100g: 2.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_011', name: 'Appam', caloriesPer100g: 170, proteinPer100g: 3.5, carbsPer100g: 30.0, fatPer100g: 4.0, fiberPer100g: 1.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_012', name: 'Puttu (Rice)', caloriesPer100g: 180, proteinPer100g: 3.5, carbsPer100g: 32.0, fatPer100g: 5.0, fiberPer100g: 1.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_013', name: 'Lemon Rice', caloriesPer100g: 158, proteinPer100g: 3.0, carbsPer100g: 27.0, fatPer100g: 4.0, fiberPer100g: 0.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_014', name: 'Curd Rice', caloriesPer100g: 130, proteinPer100g: 3.5, carbsPer100g: 22.0, fatPer100g: 3.0, fiberPer100g: 0.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_015', name: 'Tamarind Rice', caloriesPer100g: 155, proteinPer100g: 3.0, carbsPer100g: 28.0, fatPer100g: 3.5, fiberPer100g: 1.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_016', name: 'Tomato Rice', caloriesPer100g: 145, proteinPer100g: 3.0, carbsPer100g: 25.0, fatPer100g: 3.5, fiberPer100g: 1.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_017', name: 'Bisibele Bath', caloriesPer100g: 140, proteinPer100g: 4.0, carbsPer100g: 20.0, fatPer100g: 5.0, fiberPer100g: 2.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_018', name: 'Avial', caloriesPer100g: 85, proteinPer100g: 2.0, carbsPer100g: 6.0, fatPer100g: 6.0, fiberPer100g: 3.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_019', name: 'Pesarattu (Moong Dosa)', caloriesPer100g: 155, proteinPer100g: 7.0, carbsPer100g: 22.0, fatPer100g: 4.0, fiberPer100g: 3.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_020', name: 'Kootu (Mixed Veg)', caloriesPer100g: 75, proteinPer100g: 3.5, carbsPer100g: 8.0, fatPer100g: 3.0, fiberPer100g: 2.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_021', name: 'Hyderabadi Chicken Biryani', caloriesPer100g: 180, proteinPer100g: 10.0, carbsPer100g: 20.0, fatPer100g: 7.5, fiberPer100g: 0.8, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_022', name: 'Chicken Chettinad', caloriesPer100g: 155, proteinPer100g: 15.0, carbsPer100g: 5.0, fatPer100g: 9.0, fiberPer100g: 1.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_023', name: 'Kerala Fish Curry', caloriesPer100g: 115, proteinPer100g: 14.0, carbsPer100g: 3.0, fatPer100g: 5.5, fiberPer100g: 0.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_024', name: 'Meen Pollichathu (Fish)', caloriesPer100g: 140, proteinPer100g: 16.0, carbsPer100g: 3.0, fatPer100g: 7.0, fiberPer100g: 0.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_si_025', name: 'Payasam (Vermicelli)', caloriesPer100g: 135, proteinPer100g: 3.0, carbsPer100g: 22.0, fatPer100g: 4.0, sugarPer100g: 14.0, fiberPer100g: 0.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── BENGALI ─────────────────────
  Food(id: 'seed_bg_001', name: 'Macher Jhol (Fish Curry)', caloriesPer100g: 100, proteinPer100g: 12.0, carbsPer100g: 4.0, fatPer100g: 4.0, fiberPer100g: 0.5, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bg_002', name: 'Luchi (Fried Bread)', caloriesPer100g: 330, proteinPer100g: 5.5, carbsPer100g: 40.0, fatPer100g: 17.0, fiberPer100g: 1.0, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bg_003', name: 'Aloo Posto', caloriesPer100g: 110, proteinPer100g: 3.5, carbsPer100g: 10.0, fatPer100g: 6.5, fiberPer100g: 2.0, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bg_004', name: 'Shukto (Mixed Veg)', caloriesPer100g: 70, proteinPer100g: 2.0, carbsPer100g: 8.0, fatPer100g: 3.5, fiberPer100g: 3.0, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bg_005', name: 'Chingri Malai Curry (Prawn)', caloriesPer100g: 145, proteinPer100g: 12.0, carbsPer100g: 3.0, fatPer100g: 10.0, fiberPer100g: 0.5, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bg_006', name: 'Kosha Mangsho (Mutton)', caloriesPer100g: 175, proteinPer100g: 14.0, carbsPer100g: 4.0, fatPer100g: 12.0, fiberPer100g: 0.5, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bg_007', name: 'Mishti Doi', caloriesPer100g: 115, proteinPer100g: 3.0, carbsPer100g: 18.0, fatPer100g: 3.5, sugarPer100g: 15.0, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bg_008', name: 'Rosogolla', caloriesPer100g: 180, proteinPer100g: 5.0, carbsPer100g: 35.0, fatPer100g: 2.5, sugarPer100g: 28.0, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bg_009', name: 'Sandesh', caloriesPer100g: 220, proteinPer100g: 8.0, carbsPer100g: 30.0, fatPer100g: 8.0, sugarPer100g: 24.0, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bg_010', name: 'Begun Bhaja (Fried Eggplant)', caloriesPer100g: 165, proteinPer100g: 1.5, carbsPer100g: 8.0, fatPer100g: 14.0, fiberPer100g: 2.0, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bg_011', name: 'Doi Maach (Yogurt Fish)', caloriesPer100g: 120, proteinPer100g: 13.0, carbsPer100g: 4.0, fatPer100g: 6.0, fiberPer100g: 0.3, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bg_012', name: 'Ghee Rice (Bengali)', caloriesPer100g: 165, proteinPer100g: 3.0, carbsPer100g: 25.0, fatPer100g: 6.0, fiberPer100g: 0.5, category: 'Bengali', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── COMMON INDIAN SNACKS / STREET FOOD ─────────────────
  Food(id: 'seed_sn_001', name: 'Pani Puri (Golgappa)', caloriesPer100g: 190, proteinPer100g: 4.0, carbsPer100g: 28.0, fatPer100g: 7.0, fiberPer100g: 2.0, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sn_002', name: 'Bhel Puri', caloriesPer100g: 195, proteinPer100g: 5.0, carbsPer100g: 30.0, fatPer100g: 6.0, fiberPer100g: 2.5, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sn_003', name: 'Sev Puri', caloriesPer100g: 220, proteinPer100g: 4.5, carbsPer100g: 27.0, fatPer100g: 11.0, fiberPer100g: 2.0, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sn_004', name: 'Dahi Puri', caloriesPer100g: 165, proteinPer100g: 4.0, carbsPer100g: 20.0, fatPer100g: 7.5, fiberPer100g: 1.5, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sn_005', name: 'Vada Pav', caloriesPer100g: 250, proteinPer100g: 5.5, carbsPer100g: 30.0, fatPer100g: 12.0, fiberPer100g: 2.0, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sn_006', name: 'Dhokla', caloriesPer100g: 135, proteinPer100g: 5.5, carbsPer100g: 20.0, fatPer100g: 3.5, fiberPer100g: 2.0, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sn_007', name: 'Khandvi', caloriesPer100g: 120, proteinPer100g: 5.0, carbsPer100g: 15.0, fatPer100g: 4.5, fiberPer100g: 1.5, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sn_008', name: 'Misal Pav', caloriesPer100g: 200, proteinPer100g: 7.0, carbsPer100g: 25.0, fatPer100g: 8.0, fiberPer100g: 4.0, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sn_009', name: 'Dahi Bhalla', caloriesPer100g: 145, proteinPer100g: 5.0, carbsPer100g: 18.0, fatPer100g: 6.0, fiberPer100g: 2.0, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sn_010', name: 'Pav Bhaji', caloriesPer100g: 155, proteinPer100g: 4.0, carbsPer100g: 18.0, fatPer100g: 8.0, fiberPer100g: 3.0, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sn_011', name: 'Cutlet (Veg)', caloriesPer100g: 200, proteinPer100g: 4.0, carbsPer100g: 20.0, fatPer100g: 12.0, fiberPer100g: 2.0, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sn_012', name: 'Chaat (Mixed)', caloriesPer100g: 175, proteinPer100g: 4.5, carbsPer100g: 22.0, fatPer100g: 8.0, fiberPer100g: 2.5, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── INDIAN SWEETS / DESSERTS ─────────────────
  Food(id: 'seed_sw_001', name: 'Gulab Jamun', caloriesPer100g: 340, proteinPer100g: 5.0, carbsPer100g: 48.0, fatPer100g: 15.0, sugarPer100g: 38.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sw_002', name: 'Jalebi', caloriesPer100g: 370, proteinPer100g: 3.0, carbsPer100g: 60.0, fatPer100g: 13.0, sugarPer100g: 45.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sw_003', name: 'Barfi (Kaju)', caloriesPer100g: 390, proteinPer100g: 8.0, carbsPer100g: 50.0, fatPer100g: 18.0, sugarPer100g: 40.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sw_004', name: 'Rasgulla', caloriesPer100g: 180, proteinPer100g: 5.0, carbsPer100g: 35.0, fatPer100g: 2.5, sugarPer100g: 28.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sw_005', name: 'Laddu (Besan)', caloriesPer100g: 420, proteinPer100g: 8.0, carbsPer100g: 45.0, fatPer100g: 24.0, sugarPer100g: 30.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sw_006', name: 'Kheer (Rice)', caloriesPer100g: 120, proteinPer100g: 3.5, carbsPer100g: 18.0, fatPer100g: 4.0, sugarPer100g: 12.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sw_007', name: 'Halwa (Gajar)', caloriesPer100g: 175, proteinPer100g: 3.0, carbsPer100g: 25.0, fatPer100g: 7.5, sugarPer100g: 18.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sw_008', name: 'Halwa (Sooji)', caloriesPer100g: 250, proteinPer100g: 3.5, carbsPer100g: 32.0, fatPer100g: 12.0, sugarPer100g: 20.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sw_009', name: 'Peda', caloriesPer100g: 380, proteinPer100g: 7.0, carbsPer100g: 50.0, fatPer100g: 17.0, sugarPer100g: 40.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_sw_010', name: 'Kulfi (Mango)', caloriesPer100g: 200, proteinPer100g: 4.0, carbsPer100g: 25.0, fatPer100g: 10.0, sugarPer100g: 20.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── INDIAN PACKAGED FOOD ─────────────────
  Food(id: 'seed_pk_001', name: 'Maggi 2-Minute Noodles', brand: 'Nestle', caloriesPer100g: 395, proteinPer100g: 9.0, carbsPer100g: 58.0, fatPer100g: 15.0, sodiumPer100g: 1100, fiberPer100g: 2.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_002', name: 'Parle-G Biscuits', brand: 'Parle', caloriesPer100g: 462, proteinPer100g: 6.5, carbsPer100g: 73.0, fatPer100g: 16.0, sugarPer100g: 27.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_003', name: 'Good Day Butter Cookies', brand: 'Britannia', caloriesPer100g: 480, proteinPer100g: 5.5, carbsPer100g: 68.0, fatPer100g: 20.0, sugarPer100g: 25.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_004', name: 'Marie Gold Biscuits', brand: 'Britannia', caloriesPer100g: 435, proteinPer100g: 7.0, carbsPer100g: 72.0, fatPer100g: 13.0, sugarPer100g: 22.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_005', name: 'Amul Butter', brand: 'Amul', caloriesPer100g: 720, proteinPer100g: 0.5, carbsPer100g: 0.5, fatPer100g: 81.0, sodiumPer100g: 40, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_006', name: 'Amul Cheese Slice', brand: 'Amul', caloriesPer100g: 310, proteinPer100g: 18.0, carbsPer100g: 4.0, fatPer100g: 25.0, sodiumPer100g: 900, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_007', name: 'Amul Paneer', brand: 'Amul', caloriesPer100g: 265, proteinPer100g: 18.3, carbsPer100g: 1.2, fatPer100g: 20.8, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_008', name: 'Mother Dairy Curd', brand: 'Mother Dairy', caloriesPer100g: 60, proteinPer100g: 3.0, carbsPer100g: 5.0, fatPer100g: 3.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_009', name: 'Haldiram Aloo Bhujia', brand: 'Haldiram', caloriesPer100g: 520, proteinPer100g: 8.0, carbsPer100g: 50.0, fatPer100g: 32.0, sodiumPer100g: 600, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_010', name: 'Lays Classic Salted Chips', brand: 'Lays', caloriesPer100g: 536, proteinPer100g: 6.0, carbsPer100g: 52.0, fatPer100g: 34.0, sodiumPer100g: 630, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_011', name: 'Kurkure Masala Munch', brand: 'Kurkure', caloriesPer100g: 520, proteinPer100g: 6.0, carbsPer100g: 55.0, fatPer100g: 30.0, sodiumPer100g: 750, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_012', name: 'Amul Milk (Toned)', brand: 'Amul', caloriesPer100g: 58, proteinPer100g: 3.0, carbsPer100g: 4.8, fatPer100g: 3.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_013', name: 'Amul Milk (Full Cream)', brand: 'Amul', caloriesPer100g: 68, proteinPer100g: 3.5, carbsPer100g: 4.8, fatPer100g: 4.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_014', name: 'MTR Ready Poha', brand: 'MTR', caloriesPer100g: 340, proteinPer100g: 6.0, carbsPer100g: 60.0, fatPer100g: 8.0, fiberPer100g: 2.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_015', name: 'Bournvita Health Drink', brand: 'Cadbury', caloriesPer100g: 375, proteinPer100g: 7.0, carbsPer100g: 80.0, fatPer100g: 2.5, sugarPer100g: 38.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_016', name: 'Top Ramen Curry Noodles', brand: 'Nissin', caloriesPer100g: 400, proteinPer100g: 8.5, carbsPer100g: 56.0, fatPer100g: 16.0, sodiumPer100g: 1050, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_017', name: 'Yippee Noodles (Magic Masala)', brand: 'ITC', caloriesPer100g: 390, proteinPer100g: 8.0, carbsPer100g: 57.0, fatPer100g: 14.5, sodiumPer100g: 980, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_018', name: 'Parle Hide & Seek', brand: 'Parle', caloriesPer100g: 495, proteinPer100g: 5.5, carbsPer100g: 63.0, fatPer100g: 24.0, sugarPer100g: 30.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_019', name: 'Real Mango Juice', brand: 'Real', caloriesPer100g: 55, proteinPer100g: 0.2, carbsPer100g: 13.5, fatPer100g: 0, sugarPer100g: 12.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_pk_020', name: 'Frooti Mango Drink', brand: 'Parle Agro', caloriesPer100g: 50, proteinPer100g: 0.1, carbsPer100g: 12.5, fatPer100g: 0, sugarPer100g: 11.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── INDIAN BASICS / STAPLES ─────────────────
  Food(id: 'seed_bs_001', name: 'Steamed White Rice', caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28.0, fatPer100g: 0.3, fiberPer100g: 0.4, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_002', name: 'Brown Rice (Cooked)', caloriesPer100g: 123, proteinPer100g: 2.7, carbsPer100g: 26.0, fatPer100g: 1.0, fiberPer100g: 1.8, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_003', name: 'Dal (Toor / Arhar, Cooked)', caloriesPer100g: 115, proteinPer100g: 7.0, carbsPer100g: 16.0, fatPer100g: 2.5, fiberPer100g: 3.0, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_004', name: 'Curd / Yogurt (Plain)', caloriesPer100g: 60, proteinPer100g: 3.5, carbsPer100g: 4.7, fatPer100g: 3.0, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_005', name: 'Paneer (Fresh)', caloriesPer100g: 265, proteinPer100g: 18.3, carbsPer100g: 1.2, fatPer100g: 20.8, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_006', name: 'Ghee', caloriesPer100g: 900, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_007', name: 'Coconut Oil', caloriesPer100g: 890, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 99, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_008', name: 'Mustard Oil', caloriesPer100g: 884, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_009', name: 'Poha (Flattened Rice, Cooked)', caloriesPer100g: 130, proteinPer100g: 2.5, carbsPer100g: 25.0, fatPer100g: 2.5, fiberPer100g: 1.5, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_010', name: 'Rawa / Sooji (Dry)', caloriesPer100g: 340, proteinPer100g: 10.0, carbsPer100g: 72.0, fatPer100g: 1.5, fiberPer100g: 3.0, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_011', name: 'Whole Wheat Flour (Atta)', caloriesPer100g: 340, proteinPer100g: 11.0, carbsPer100g: 68.0, fatPer100g: 2.5, fiberPer100g: 11.0, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_012', name: 'Besan (Gram Flour)', caloriesPer100g: 356, proteinPer100g: 22.0, carbsPer100g: 47.0, fatPer100g: 7.0, fiberPer100g: 10.0, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_013', name: 'Boiled Egg', caloriesPer100g: 155, proteinPer100g: 13.0, carbsPer100g: 1.1, fatPer100g: 11.0, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_014', name: 'Omelette (2 eggs)', caloriesPer100g: 190, proteinPer100g: 11.0, carbsPer100g: 1.5, fatPer100g: 15.0, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_015', name: 'Chicken Breast (Cooked)', caloriesPer100g: 165, proteinPer100g: 31.0, carbsPer100g: 0, fatPer100g: 3.6, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_016', name: 'Mutton (Cooked, Lean)', caloriesPer100g: 250, proteinPer100g: 25.0, carbsPer100g: 0, fatPer100g: 16.0, category: 'Basics', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_017', name: 'Banana', caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23.0, fatPer100g: 0.3, fiberPer100g: 2.6, sugarPer100g: 12.0, category: 'Fruits', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_018', name: 'Mango', caloriesPer100g: 60, proteinPer100g: 0.8, carbsPer100g: 15.0, fatPer100g: 0.4, fiberPer100g: 1.6, sugarPer100g: 14.0, category: 'Fruits', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_019', name: 'Apple', caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14.0, fatPer100g: 0.2, fiberPer100g: 2.4, sugarPer100g: 10.0, category: 'Fruits', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_020', name: 'Papaya', caloriesPer100g: 43, proteinPer100g: 0.5, carbsPer100g: 11.0, fatPer100g: 0.3, fiberPer100g: 1.7, sugarPer100g: 8.0, category: 'Fruits', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_021', name: 'Guava', caloriesPer100g: 68, proteinPer100g: 2.6, carbsPer100g: 14.0, fatPer100g: 1.0, fiberPer100g: 5.4, category: 'Fruits', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_022', name: 'Pomegranate', caloriesPer100g: 83, proteinPer100g: 1.7, carbsPer100g: 19.0, fatPer100g: 1.2, fiberPer100g: 4.0, sugarPer100g: 14.0, category: 'Fruits', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_023', name: 'Tea with Milk & Sugar', caloriesPer100g: 38, proteinPer100g: 1.0, carbsPer100g: 5.5, fatPer100g: 1.3, sugarPer100g: 4.0, category: 'Beverages', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_024', name: 'Coffee with Milk & Sugar', caloriesPer100g: 42, proteinPer100g: 1.0, carbsPer100g: 6.0, fatPer100g: 1.5, sugarPer100g: 5.0, category: 'Beverages', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_025', name: 'Buttermilk (Chaas)', caloriesPer100g: 35, proteinPer100g: 2.0, carbsPer100g: 4.0, fatPer100g: 1.0, sodiumPer100g: 120, category: 'Beverages', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_026', name: 'Coconut Water', caloriesPer100g: 19, proteinPer100g: 0.7, carbsPer100g: 3.7, fatPer100g: 0.2, category: 'Beverages', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_bs_027', name: 'Nimbu Pani (Lemonade)', caloriesPer100g: 30, proteinPer100g: 0.2, carbsPer100g: 7.5, fatPer100g: 0, sugarPer100g: 6.0, category: 'Beverages', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── INDO-CHINESE ─────────────────────
  Food(id: 'seed_ic_001', name: 'Veg Manchurian (Dry)', caloriesPer100g: 195, proteinPer100g: 4.0, carbsPer100g: 20.0, fatPer100g: 11.0, fiberPer100g: 2.0, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_002', name: 'Veg Manchurian (Gravy)', caloriesPer100g: 140, proteinPer100g: 3.0, carbsPer100g: 15.0, fatPer100g: 8.0, fiberPer100g: 1.5, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_003', name: 'Fried Rice (Veg)', caloriesPer100g: 175, proteinPer100g: 3.5, carbsPer100g: 28.0, fatPer100g: 6.0, fiberPer100g: 1.5, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_004', name: 'Fried Rice (Chicken)', caloriesPer100g: 190, proteinPer100g: 8.0, carbsPer100g: 26.0, fatPer100g: 6.5, fiberPer100g: 1.0, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_005', name: 'Hakka Noodles (Veg)', caloriesPer100g: 185, proteinPer100g: 4.0, carbsPer100g: 30.0, fatPer100g: 6.0, fiberPer100g: 1.5, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_006', name: 'Hakka Noodles (Chicken)', caloriesPer100g: 200, proteinPer100g: 8.0, carbsPer100g: 28.0, fatPer100g: 7.0, fiberPer100g: 1.0, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_007', name: 'Chilli Chicken', caloriesPer100g: 220, proteinPer100g: 16.0, carbsPer100g: 10.0, fatPer100g: 14.0, fiberPer100g: 1.0, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_008', name: 'Chilli Paneer', caloriesPer100g: 210, proteinPer100g: 10.0, carbsPer100g: 10.0, fatPer100g: 15.0, fiberPer100g: 1.5, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_009', name: 'Spring Roll (Veg)', caloriesPer100g: 250, proteinPer100g: 4.0, carbsPer100g: 25.0, fatPer100g: 15.0, fiberPer100g: 2.0, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_010', name: 'Momos (Veg, Steamed)', caloriesPer100g: 170, proteinPer100g: 5.0, carbsPer100g: 25.0, fatPer100g: 5.5, fiberPer100g: 2.0, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_011', name: 'Momos (Chicken, Steamed)', caloriesPer100g: 185, proteinPer100g: 10.0, carbsPer100g: 22.0, fatPer100g: 6.5, fiberPer100g: 1.0, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_012', name: 'Momos (Fried)', caloriesPer100g: 260, proteinPer100g: 7.0, carbsPer100g: 24.0, fatPer100g: 15.0, fiberPer100g: 1.5, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_013', name: 'Schezwan Fried Rice', caloriesPer100g: 190, proteinPer100g: 4.0, carbsPer100g: 28.0, fatPer100g: 7.0, fiberPer100g: 1.5, sodiumPer100g: 500, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_014', name: 'Manchow Soup', caloriesPer100g: 45, proteinPer100g: 2.0, carbsPer100g: 5.0, fatPer100g: 2.0, fiberPer100g: 0.5, sodiumPer100g: 400, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ic_015', name: 'Hot and Sour Soup', caloriesPer100g: 40, proteinPer100g: 2.0, carbsPer100g: 4.5, fatPer100g: 1.5, fiberPer100g: 0.5, sodiumPer100g: 380, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── ITALIAN ─────────────────────
  Food(id: 'seed_it_001', name: 'Margherita Pizza', caloriesPer100g: 250, proteinPer100g: 11.0, carbsPer100g: 30.0, fatPer100g: 10.0, fiberPer100g: 2.0, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_it_002', name: 'Pasta Marinara', caloriesPer100g: 130, proteinPer100g: 4.0, carbsPer100g: 24.0, fatPer100g: 1.5, fiberPer100g: 2.0, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_it_003', name: 'Pasta Alfredo', caloriesPer100g: 190, proteinPer100g: 7.0, carbsPer100g: 22.0, fatPer100g: 8.5, fiberPer100g: 1.0, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_it_004', name: 'Spaghetti Bolognese', caloriesPer100g: 155, proteinPer100g: 8.0, carbsPer100g: 18.0, fatPer100g: 5.5, fiberPer100g: 1.5, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_it_005', name: 'Pasta Pesto', caloriesPer100g: 175, proteinPer100g: 6.0, carbsPer100g: 22.0, fatPer100g: 7.0, fiberPer100g: 1.5, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_it_006', name: 'Lasagna', caloriesPer100g: 165, proteinPer100g: 9.0, carbsPer100g: 16.0, fatPer100g: 7.5, fiberPer100g: 1.0, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_it_007', name: 'Bruschetta', caloriesPer100g: 165, proteinPer100g: 4.0, carbsPer100g: 22.0, fatPer100g: 7.0, fiberPer100g: 1.5, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_it_008', name: 'Risotto', caloriesPer100g: 140, proteinPer100g: 3.5, carbsPer100g: 20.0, fatPer100g: 5.0, fiberPer100g: 0.5, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_it_009', name: 'Garlic Bread', caloriesPer100g: 350, proteinPer100g: 8.0, carbsPer100g: 42.0, fatPer100g: 16.0, fiberPer100g: 2.0, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_it_010', name: 'Tiramisu', caloriesPer100g: 280, proteinPer100g: 5.0, carbsPer100g: 28.0, fatPer100g: 16.0, sugarPer100g: 20.0, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_it_011', name: 'Penne Arrabbiata', caloriesPer100g: 140, proteinPer100g: 5.0, carbsPer100g: 24.0, fatPer100g: 3.0, fiberPer100g: 2.0, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_it_012', name: 'Caprese Salad', caloriesPer100g: 140, proteinPer100g: 8.0, carbsPer100g: 4.0, fatPer100g: 10.0, fiberPer100g: 0.5, category: 'Italian', source: FoodSource.usda),

  // ───────────────────── AMERICAN / CONTINENTAL ─────────────────
  Food(id: 'seed_am_001', name: 'Cheeseburger', caloriesPer100g: 265, proteinPer100g: 14.0, carbsPer100g: 22.0, fatPer100g: 14.0, fiberPer100g: 1.0, sodiumPer100g: 550, category: 'American', source: FoodSource.usda),
  Food(id: 'seed_am_002', name: 'French Fries', caloriesPer100g: 312, proteinPer100g: 3.4, carbsPer100g: 41.0, fatPer100g: 15.0, fiberPer100g: 3.8, sodiumPer100g: 210, category: 'American', source: FoodSource.usda),
  Food(id: 'seed_am_003', name: 'Grilled Chicken Sandwich', caloriesPer100g: 200, proteinPer100g: 16.0, carbsPer100g: 18.0, fatPer100g: 7.0, fiberPer100g: 1.5, category: 'American', source: FoodSource.usda),
  Food(id: 'seed_am_004', name: 'Hot Dog', caloriesPer100g: 290, proteinPer100g: 10.0, carbsPer100g: 25.0, fatPer100g: 17.0, sodiumPer100g: 800, category: 'American', source: FoodSource.usda),
  Food(id: 'seed_am_005', name: 'Caesar Salad', caloriesPer100g: 120, proteinPer100g: 5.0, carbsPer100g: 8.0, fatPer100g: 8.0, fiberPer100g: 1.5, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_am_006', name: 'Grilled Chicken Breast', caloriesPer100g: 165, proteinPer100g: 31.0, carbsPer100g: 0, fatPer100g: 3.6, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_am_007', name: 'Scrambled Eggs', caloriesPer100g: 148, proteinPer100g: 10.0, carbsPer100g: 1.6, fatPer100g: 11.0, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_am_008', name: 'Pancakes (with Syrup)', caloriesPer100g: 250, proteinPer100g: 5.0, carbsPer100g: 40.0, fatPer100g: 8.0, sugarPer100g: 18.0, category: 'American', source: FoodSource.usda),
  Food(id: 'seed_am_009', name: 'Mac and Cheese', caloriesPer100g: 200, proteinPer100g: 8.0, carbsPer100g: 22.0, fatPer100g: 9.0, fiberPer100g: 1.0, sodiumPer100g: 470, category: 'American', source: FoodSource.usda),
  Food(id: 'seed_am_010', name: 'Chicken Nuggets', caloriesPer100g: 295, proteinPer100g: 15.0, carbsPer100g: 18.0, fatPer100g: 18.0, fiberPer100g: 1.0, sodiumPer100g: 560, category: 'American', source: FoodSource.usda),
  Food(id: 'seed_am_011', name: 'Wrap (Chicken)', caloriesPer100g: 210, proteinPer100g: 12.0, carbsPer100g: 22.0, fatPer100g: 8.0, fiberPer100g: 1.5, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_am_012', name: 'Club Sandwich', caloriesPer100g: 230, proteinPer100g: 13.0, carbsPer100g: 20.0, fatPer100g: 11.0, fiberPer100g: 1.5, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_am_013', name: 'Fish and Chips', caloriesPer100g: 240, proteinPer100g: 12.0, carbsPer100g: 22.0, fatPer100g: 12.0, fiberPer100g: 1.5, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_am_014', name: 'Mushroom Soup (Cream)', caloriesPer100g: 75, proteinPer100g: 2.0, carbsPer100g: 7.0, fatPer100g: 4.5, fiberPer100g: 0.5, sodiumPer100g: 400, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_am_015', name: 'Tomato Soup', caloriesPer100g: 60, proteinPer100g: 1.5, carbsPer100g: 10.0, fatPer100g: 1.5, fiberPer100g: 1.5, sodiumPer100g: 380, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_am_016', name: 'Baked Potato with Cheese', caloriesPer100g: 140, proteinPer100g: 5.0, carbsPer100g: 18.0, fatPer100g: 5.5, fiberPer100g: 2.0, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_am_017', name: 'Grilled Fish (White)', caloriesPer100g: 110, proteinPer100g: 22.0, carbsPer100g: 0, fatPer100g: 2.5, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_am_018', name: 'Steak (Sirloin, Grilled)', caloriesPer100g: 210, proteinPer100g: 27.0, carbsPer100g: 0, fatPer100g: 11.0, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_am_019', name: 'Mashed Potato', caloriesPer100g: 100, proteinPer100g: 2.0, carbsPer100g: 15.0, fatPer100g: 4.0, fiberPer100g: 1.5, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_am_020', name: 'Coleslaw', caloriesPer100g: 95, proteinPer100g: 1.0, carbsPer100g: 8.0, fatPer100g: 7.0, fiberPer100g: 1.5, category: 'Continental', source: FoodSource.usda),

  // ───────────────────── COMMON HEALTHY / GYM FOODS ─────────────────
  Food(id: 'seed_hl_001', name: 'Oats (Cooked)', caloriesPer100g: 68, proteinPer100g: 2.5, carbsPer100g: 12.0, fatPer100g: 1.5, fiberPer100g: 1.7, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_002', name: 'Oats (Dry)', caloriesPer100g: 379, proteinPer100g: 13.0, carbsPer100g: 67.0, fatPer100g: 6.5, fiberPer100g: 10.0, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_003', name: 'Greek Yogurt (Plain)', caloriesPer100g: 59, proteinPer100g: 10.0, carbsPer100g: 3.6, fatPer100g: 0.7, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_004', name: 'Whey Protein Powder', caloriesPer100g: 380, proteinPer100g: 75.0, carbsPer100g: 10.0, fatPer100g: 5.0, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_005', name: 'Peanut Butter', caloriesPer100g: 588, proteinPer100g: 25.0, carbsPer100g: 20.0, fatPer100g: 50.0, fiberPer100g: 6.0, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_006', name: 'Almonds', caloriesPer100g: 579, proteinPer100g: 21.0, carbsPer100g: 22.0, fatPer100g: 50.0, fiberPer100g: 12.5, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_007', name: 'Walnuts', caloriesPer100g: 654, proteinPer100g: 15.0, carbsPer100g: 14.0, fatPer100g: 65.0, fiberPer100g: 6.7, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_008', name: 'Cashews', caloriesPer100g: 553, proteinPer100g: 18.0, carbsPer100g: 30.0, fatPer100g: 44.0, fiberPer100g: 3.3, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_009', name: 'Flax Seeds', caloriesPer100g: 534, proteinPer100g: 18.0, carbsPer100g: 29.0, fatPer100g: 42.0, fiberPer100g: 27.0, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_010', name: 'Chia Seeds', caloriesPer100g: 486, proteinPer100g: 17.0, carbsPer100g: 42.0, fatPer100g: 31.0, fiberPer100g: 34.0, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_011', name: 'Quinoa (Cooked)', caloriesPer100g: 120, proteinPer100g: 4.4, carbsPer100g: 21.0, fatPer100g: 1.9, fiberPer100g: 2.8, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_012', name: 'Sweet Potato (Boiled)', caloriesPer100g: 86, proteinPer100g: 1.6, carbsPer100g: 20.0, fatPer100g: 0.1, fiberPer100g: 3.0, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_013', name: 'Avocado', caloriesPer100g: 160, proteinPer100g: 2.0, carbsPer100g: 9.0, fatPer100g: 15.0, fiberPer100g: 7.0, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_014', name: 'Salmon (Grilled)', caloriesPer100g: 208, proteinPer100g: 20.0, carbsPer100g: 0, fatPer100g: 13.0, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_015', name: 'Tuna (Canned in Water)', caloriesPer100g: 116, proteinPer100g: 26.0, carbsPer100g: 0, fatPer100g: 1.0, sodiumPer100g: 280, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_016', name: 'Tofu', caloriesPer100g: 76, proteinPer100g: 8.0, carbsPer100g: 1.9, fatPer100g: 4.8, fiberPer100g: 0.3, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_017', name: 'Sprouts (Moong)', caloriesPer100g: 65, proteinPer100g: 6.0, carbsPer100g: 8.0, fatPer100g: 0.5, fiberPer100g: 2.0, category: 'Healthy', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_hl_018', name: 'Dates (Dried)', caloriesPer100g: 277, proteinPer100g: 1.8, carbsPer100g: 75.0, fatPer100g: 0.2, fiberPer100g: 7.0, sugarPer100g: 63.0, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_019', name: 'Raisins', caloriesPer100g: 299, proteinPer100g: 3.1, carbsPer100g: 79.0, fatPer100g: 0.5, fiberPer100g: 3.7, sugarPer100g: 59.0, category: 'Healthy', source: FoodSource.usda),
  Food(id: 'seed_hl_020', name: 'Dark Chocolate (70%)', caloriesPer100g: 600, proteinPer100g: 8.0, carbsPer100g: 46.0, fatPer100g: 43.0, fiberPer100g: 11.0, sugarPer100g: 24.0, category: 'Healthy', source: FoodSource.usda),

  // ───────────────────── COMMON FAST FOOD / RESTAURANT ────────────
  Food(id: 'seed_ff_001', name: 'Dominos Cheese Burst Pizza', brand: 'Dominos', caloriesPer100g: 275, proteinPer100g: 12.0, carbsPer100g: 28.0, fatPer100g: 13.0, category: 'Fast Food', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ff_002', name: 'McAloo Tikki Burger', brand: 'McDonalds', caloriesPer100g: 225, proteinPer100g: 6.0, carbsPer100g: 30.0, fatPer100g: 9.0, category: 'Fast Food', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ff_003', name: 'KFC Chicken Zinger', brand: 'KFC', caloriesPer100g: 260, proteinPer100g: 14.0, carbsPer100g: 22.0, fatPer100g: 13.0, category: 'Fast Food', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ff_004', name: 'Subway Veg Patty Sub', brand: 'Subway', caloriesPer100g: 175, proteinPer100g: 7.0, carbsPer100g: 24.0, fatPer100g: 6.0, fiberPer100g: 2.0, category: 'Fast Food', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_ff_005', name: 'Pizza (Pepperoni)', caloriesPer100g: 270, proteinPer100g: 12.0, carbsPer100g: 28.0, fatPer100g: 12.5, category: 'Fast Food', source: FoodSource.usda),
  Food(id: 'seed_ff_006', name: 'Burger (Chicken)', caloriesPer100g: 240, proteinPer100g: 14.0, carbsPer100g: 22.0, fatPer100g: 11.0, category: 'Fast Food', source: FoodSource.usda),
  Food(id: 'seed_ff_007', name: 'Fried Chicken (Drumstick)', caloriesPer100g: 260, proteinPer100g: 18.0, carbsPer100g: 10.0, fatPer100g: 17.0, category: 'Fast Food', source: FoodSource.usda),
  Food(id: 'seed_ff_008', name: 'Shawarma (Chicken)', caloriesPer100g: 215, proteinPer100g: 14.0, carbsPer100g: 18.0, fatPer100g: 10.0, fiberPer100g: 1.0, category: 'Fast Food', source: FoodSource.usda),
  Food(id: 'seed_ff_009', name: 'Falafel', caloriesPer100g: 333, proteinPer100g: 13.0, carbsPer100g: 32.0, fatPer100g: 18.0, fiberPer100g: 5.0, category: 'Fast Food', source: FoodSource.usda),
  Food(id: 'seed_ff_010', name: 'Nachos with Cheese', caloriesPer100g: 300, proteinPer100g: 7.0, carbsPer100g: 32.0, fatPer100g: 16.0, fiberPer100g: 3.0, sodiumPer100g: 500, category: 'Fast Food', source: FoodSource.usda),

  // ───────────────────── EXPANDED NORTH / STREET / SWEETS ─────────────────
  Food(id: 'seed_x2_001', name: 'Chole Kulche (Amritsari)', caloriesPer100g: 195, proteinPer100g: 6.5, carbsPer100g: 28.0, fatPer100g: 6.5, fiberPer100g: 4.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_002', name: 'Amritsari Fish Fry', caloriesPer100g: 220, proteinPer100g: 16.0, carbsPer100g: 12.0, fatPer100g: 12.0, fiberPer100g: 0.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_003', name: 'Sarson Ka Saag', caloriesPer100g: 95, proteinPer100g: 4.0, carbsPer100g: 8.0, fatPer100g: 5.5, fiberPer100g: 3.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_004', name: 'Makki Ki Roti', caloriesPer100g: 290, proteinPer100g: 7.0, carbsPer100g: 45.0, fatPer100g: 9.0, fiberPer100g: 5.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_005', name: 'Chana Masala', caloriesPer100g: 135, proteinPer100g: 6.5, carbsPer100g: 16.0, fatPer100g: 5.0, fiberPer100g: 5.5, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_006', name: 'Pindi Chole', caloriesPer100g: 142, proteinPer100g: 7.0, carbsPer100g: 17.0, fatPer100g: 5.5, fiberPer100g: 5.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_007', name: 'Paneer Tikka', caloriesPer100g: 240, proteinPer100g: 14.0, carbsPer100g: 8.0, fatPer100g: 17.0, fiberPer100g: 1.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_008', name: 'Hara Bhara Kebab', caloriesPer100g: 175, proteinPer100g: 5.0, carbsPer100g: 20.0, fatPer100g: 8.0, fiberPer100g: 4.0, category: 'North Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_009', name: 'Dahi Bhalla Chaat', caloriesPer100g: 155, proteinPer100g: 5.5, carbsPer100g: 19.0, fatPer100g: 6.5, fiberPer100g: 2.0, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_010', name: 'Jhal Muri', caloriesPer100g: 165, proteinPer100g: 4.0, carbsPer100g: 24.0, fatPer100g: 6.0, fiberPer100g: 2.5, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_011', name: 'Egg Roll (Kolkata)', caloriesPer100g: 235, proteinPer100g: 9.0, carbsPer100g: 26.0, fatPer100g: 10.0, fiberPer100g: 1.5, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_012', name: 'Kathi Roll (Chicken)', caloriesPer100g: 245, proteinPer100g: 12.0, carbsPer100g: 24.0, fatPer100g: 11.0, fiberPer100g: 1.0, category: 'Indian Snacks', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_013', name: 'Rabri', caloriesPer100g: 220, proteinPer100g: 6.0, carbsPer100g: 28.0, fatPer100g: 9.0, sugarPer100g: 22.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_014', name: 'Soan Papdi', caloriesPer100g: 510, proteinPer100g: 4.0, carbsPer100g: 58.0, fatPer100g: 29.0, sugarPer100g: 42.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_015', name: 'Cham Cham', caloriesPer100g: 210, proteinPer100g: 6.0, carbsPer100g: 38.0, fatPer100g: 4.0, sugarPer100g: 30.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_016', name: 'Phirni', caloriesPer100g: 140, proteinPer100g: 3.5, carbsPer100g: 22.0, fatPer100g: 4.5, sugarPer100g: 16.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_017', name: 'Basundi', caloriesPer100g: 185, proteinPer100g: 5.0, carbsPer100g: 20.0, fatPer100g: 9.0, sugarPer100g: 18.0, category: 'Indian Sweets', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── SOUTH / COASTAL EXTRA ─────────────────
  Food(id: 'seed_x2_020', name: 'Rava Dosa', caloriesPer100g: 170, proteinPer100g: 4.0, carbsPer100g: 27.0, fatPer100g: 5.0, fiberPer100g: 1.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_021', name: 'Set Dosa', caloriesPer100g: 160, proteinPer100g: 4.0, carbsPer100g: 26.0, fatPer100g: 4.5, fiberPer100g: 1.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_022', name: 'Rava Idli', caloriesPer100g: 135, proteinPer100g: 4.0, carbsPer100g: 23.0, fatPer100g: 3.0, fiberPer100g: 1.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_023', name: 'Pesarattu Upma', caloriesPer100g: 150, proteinPer100g: 6.0, carbsPer100g: 21.0, fatPer100g: 4.0, fiberPer100g: 2.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_024', name: 'Chettinad Chicken', caloriesPer100g: 175, proteinPer100g: 16.0, carbsPer100g: 6.0, fatPer100g: 10.0, fiberPer100g: 1.2, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_025', name: 'Appam with Stew', caloriesPer100g: 125, proteinPer100g: 3.5, carbsPer100g: 18.0, fatPer100g: 4.5, fiberPer100g: 1.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_026', name: 'Malabar Parotta', caloriesPer100g: 310, proteinPer100g: 6.0, carbsPer100g: 42.0, fatPer100g: 13.0, fiberPer100g: 2.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_027', name: 'Beef Ularthiyathu (Kerala)', caloriesPer100g: 195, proteinPer100g: 18.0, carbsPer100g: 5.0, fatPer100g: 11.0, fiberPer100g: 1.0, category: 'South Indian', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_028', name: 'Prawn Curry (Goan)', caloriesPer100g: 125, proteinPer100g: 14.0, carbsPer100g: 4.0, fatPer100g: 5.5, fiberPer100g: 0.5, category: 'South Indian', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── BENGALI / EAST EXTRA ─────────────────
  Food(id: 'seed_x2_030', name: 'Luchi with Aloo Dum', caloriesPer100g: 265, proteinPer100g: 5.0, carbsPer100g: 32.0, fatPer100g: 13.0, fiberPer100g: 2.0, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_031', name: 'Kosha Mangsho', caloriesPer100g: 185, proteinPer100g: 14.0, carbsPer100g: 5.0, fatPer100g: 12.0, fiberPer100g: 0.5, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_032', name: 'Shorshe Ilish', caloriesPer100g: 195, proteinPer100g: 15.0, carbsPer100g: 3.0, fatPer100g: 14.0, fiberPer100g: 0.3, category: 'Bengali', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_033', name: 'Pantua', caloriesPer100g: 320, proteinPer100g: 5.0, carbsPer100g: 42.0, fatPer100g: 14.0, sugarPer100g: 28.0, category: 'Bengali', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── INDO-CHINESE EXTRA ─────────────────
  Food(id: 'seed_x2_040', name: 'Gobi Manchurian (Gravy)', caloriesPer100g: 125, proteinPer100g: 2.5, carbsPer100g: 14.0, fatPer100g: 6.5, fiberPer100g: 2.0, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_041', name: 'Egg Fried Rice', caloriesPer100g: 185, proteinPer100g: 7.0, carbsPer100g: 27.0, fatPer100g: 6.0, fiberPer100g: 1.0, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_042', name: 'American Chop Suey', caloriesPer100g: 165, proteinPer100g: 5.0, carbsPer100g: 22.0, fatPer100g: 6.5, fiberPer100g: 2.0, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_043', name: 'Chilli Potato', caloriesPer100g: 175, proteinPer100g: 3.0, carbsPer100g: 24.0, fatPer100g: 8.0, fiberPer100g: 2.5, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_044', name: 'Dragon Chicken', caloriesPer100g: 230, proteinPer100g: 15.0, carbsPer100g: 12.0, fatPer100g: 14.0, fiberPer100g: 1.0, category: 'Indo-Chinese', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── PACKAGED INDIA EXTRA ─────────────────
  Food(id: 'seed_x2_050', name: 'Sunfeast Dark Fantasy', brand: 'ITC', caloriesPer100g: 480, proteinPer100g: 5.0, carbsPer100g: 64.0, fatPer100g: 22.0, sugarPer100g: 32.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_051', name: 'Britannia Cake (Fruit)', brand: 'Britannia', caloriesPer100g: 385, proteinPer100g: 5.0, carbsPer100g: 58.0, fatPer100g: 14.0, sugarPer100g: 28.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_052', name: 'Bingo Mad Angles', brand: 'ITC', caloriesPer100g: 515, proteinPer100g: 6.0, carbsPer100g: 54.0, fatPer100g: 30.0, sodiumPer100g: 720, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_053', name: 'Uncle Chips Spicy Masala', brand: 'Uncle', caloriesPer100g: 530, proteinPer100g: 6.0, carbsPer100g: 52.0, fatPer100g: 32.0, sodiumPer100g: 680, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_054', name: 'Chocos Cereal', brand: 'Kelloggs', caloriesPer100g: 380, proteinPer100g: 6.5, carbsPer100g: 84.0, fatPer100g: 3.0, sugarPer100g: 32.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_055', name: 'Saffola Masala Oats', brand: 'Saffola', caloriesPer100g: 360, proteinPer100g: 11.0, carbsPer100g: 62.0, fatPer100g: 8.0, fiberPer100g: 10.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_056', name: 'Ching Hakka Noodles', brand: 'Chings', caloriesPer100g: 385, proteinPer100g: 8.0, carbsPer100g: 58.0, fatPer100g: 13.0, sodiumPer100g: 980, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_057', name: 'Smith & Jones Pasta', brand: 'Smith & Jones', caloriesPer100g: 350, proteinPer100g: 10.0, carbsPer100g: 65.0, fatPer100g: 5.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_058', name: 'Nandini Butter Milk', brand: 'Nandini', caloriesPer100g: 40, proteinPer100g: 1.5, carbsPer100g: 4.5, fatPer100g: 1.5, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_059', name: 'Mother Dairy Paneer', brand: 'Mother Dairy', caloriesPer100g: 265, proteinPer100g: 18.0, carbsPer100g: 1.2, fatPer100g: 21.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),
  Food(id: 'seed_x2_060', name: 'Vadilal Ice Cream (Vanilla)', brand: 'Vadilal', caloriesPer100g: 210, proteinPer100g: 3.5, carbsPer100g: 24.0, fatPer100g: 11.0, sugarPer100g: 20.0, category: 'Packaged', isIndian: true, source: FoodSource.ifct),

  // ───────────────────── CONTINENTAL / ITALIAN / AMERICAN EXTRA ─────────────────
  Food(id: 'seed_x2_070', name: 'Caesar Salad with Chicken', caloriesPer100g: 175, proteinPer100g: 14.0, carbsPer100g: 8.0, fatPer100g: 10.0, fiberPer100g: 2.0, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_x2_071', name: 'Penne Arrabiata (Restaurant)', caloriesPer100g: 145, proteinPer100g: 5.0, carbsPer100g: 23.0, fatPer100g: 3.5, fiberPer100g: 2.0, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_x2_072', name: 'BBQ Chicken Wings', caloriesPer100g: 280, proteinPer100g: 18.0, carbsPer100g: 4.0, fatPer100g: 21.0, category: 'American', source: FoodSource.usda),
  Food(id: 'seed_x2_073', name: 'Caesar Wrap', caloriesPer100g: 215, proteinPer100g: 12.0, carbsPer100g: 22.0, fatPer100g: 9.0, fiberPer100g: 1.5, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_x2_074', name: 'Minestrone Soup', caloriesPer100g: 45, proteinPer100g: 2.0, carbsPer100g: 7.0, fatPer100g: 1.0, fiberPer100g: 1.5, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_x2_075', name: 'Chicken Alfredo Pasta', caloriesPer100g: 195, proteinPer100g: 10.0, carbsPer100g: 20.0, fatPer100g: 8.5, fiberPer100g: 1.0, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_x2_076', name: 'Waffles (with Maple)', caloriesPer100g: 285, proteinPer100g: 6.0, carbsPer100g: 38.0, fatPer100g: 12.0, sugarPer100g: 18.0, category: 'American', source: FoodSource.usda),
  Food(id: 'seed_x2_077', name: 'Bagel with Cream Cheese', caloriesPer100g: 265, proteinPer100g: 9.0, carbsPer100g: 28.0, fatPer100g: 13.0, category: 'American', source: FoodSource.usda),
  Food(id: 'seed_x2_078', name: 'Greek Salad', caloriesPer100g: 95, proteinPer100g: 4.0, carbsPer100g: 6.0, fatPer100g: 7.0, fiberPer100g: 2.0, category: 'Continental', source: FoodSource.usda),
  Food(id: 'seed_x2_079', name: 'Minestrone (Vegetable)', caloriesPer100g: 40, proteinPer100g: 1.5, carbsPer100g: 6.5, fatPer100g: 1.3, fiberPer100g: 1.7, category: 'Italian', source: FoodSource.usda),
  Food(id: 'seed_x2_080', name: 'Tandoori Salmon (Continental)', caloriesPer100g: 185, proteinPer100g: 19.0, carbsPer100g: 3.0, fatPer100g: 11.0, category: 'Continental', source: FoodSource.usda),
];

/// Popular subset for the "Common" tab in the meal log.
const List<String> kCommonFoodSeedIds = <String>[
  'seed_ni_026', // Chapati
  'seed_bs_001', // Steamed White Rice
  'seed_bs_003', // Toor Dal
  'seed_bs_004', // Curd
  'seed_bs_013', // Boiled Egg
  'seed_ni_001', // Dal Makhani
  'seed_ni_003', // Chole
  'seed_ni_004', // Rajma
  'seed_ni_005', // Aloo Gobi
  'seed_ni_006', // Aloo Paratha
  'seed_ni_037', // Butter Chicken
  'seed_si_001', // Plain Dosa
  'seed_si_003', // Idli
  'seed_si_005', // Sambar
  'seed_si_008', // Upma
  'seed_bs_009', // Poha
  'seed_bs_015', // Chicken Breast
  'seed_bs_017', // Banana
  'seed_bs_023', // Tea
  'seed_hl_001', // Oats (Cooked)
  'seed_hl_003', // Greek Yogurt
  'seed_ic_005', // Hakka Noodles
  'seed_ic_010', // Momos (Veg)
  'seed_pk_001', // Maggi
  'seed_pk_012', // Amul Milk
  'seed_hl_005', // Peanut Butter
  'seed_hl_006', // Almonds
  'seed_ni_035', // Chicken Biryani
  'seed_ni_008', // Naan
  'seed_ni_002', // Paneer Butter Masala
];
