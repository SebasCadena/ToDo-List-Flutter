//importar GoRouter
import 'package:go_router/go_router.dart';
import 'package:to_do_list/views/home.dart';

GoRouter appRouter = GoRouter(routes: [

  GoRoute(path:  '/', builder: (context, state) => const Home()),

]);
  