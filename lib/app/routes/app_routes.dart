part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const home = _Paths.home;
  static const analysis = _Paths.analysis;
  static const result = _Paths.result;
}

abstract class _Paths {
  _Paths._();
  static const home = '/home';
  static const analysis = '/analysis';
  static const result = '/result';
}
