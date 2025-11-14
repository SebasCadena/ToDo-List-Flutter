//importar GoRouter
import 'package:go_router/go_router.dart';
import 'package:to_do_list/views/home/home_view.dart';
import 'package:to_do_list/views/tasks/create_task_view.dart';

GoRouter appRouter = GoRouter(routes: [

  GoRoute(path:  '/', builder: (context, state) => const Home()),
  GoRoute(path:  '/createTask', builder: (context, state) => const CreateTaskView()),

]);
  