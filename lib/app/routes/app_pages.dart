import 'package:get/get.dart';

import '../modules/analysis/bindings/analysis_binding.dart';
import '../modules/analysis/views/analysis_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/result/bindings/result_binding.dart';
import '../modules/result/views/result_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const String initial = Routes.home;

  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage(
      name: _Paths.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.analysis,
      page: () => const AnalysisView(),
      binding: AnalysisBinding(),
    ),
    GetPage(
      name: _Paths.result,
      page: () => const ResultView(),
      binding: ResultBinding(),
    ),
  ];
}
