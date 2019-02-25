import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:deer/domain/entity/todo_entity.dart';
import 'package:deer/presentation/app.dart';
import 'package:deer/utils/string_utils.dart';
import 'package:rxdart/rxdart.dart';

import 'calendar_actions.dart';
import 'calendar_state.dart';

class CalendarBloc {
  Sink get actions => _actions;
  final _actions = StreamController();

  CalendarState get initialState => _state.value;
  Stream<CalendarState> get state => _state.stream.distinct();

  final _state = BehaviorSubject<CalendarState>(
    seedValue: CalendarState(
      selectedDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    ),
  );

  StreamSubscription<List<TodoEntity>> _todosSubscription;

  CalendarBloc() {
    _actions.stream.listen((action) {
      switch (action.runtimeType) {
        case UpdateField:
          _onUpdateField(action);
          break;
        case AddTodo:
          _onAddTodo(action);
          break;
        default:
          assert(false);
      }
    });

    _todosSubscription = dependencies.todoInteractor.active.listen((data) {
      final todos = data.where((todo) => todo.dueDate != null);
      final events = groupBy(todos, (TodoEntity todo) => todo.dueDate);

      _state.add(_state.value.rebuild((b) => b..todos = MapBuilder(events)));
    });

    state.listen((data) {
      _state.add(_state.value.rebuild((b) => b..scheduledTodos = ListBuilder(b.todos[b.selectedDate] ?? [])));
    });
  }

  void dispose() {
    _actions.close();
    _state.close();
    _todosSubscription.cancel();
  }

  void _onUpdateField(UpdateField action) {
    final state = _state.value.toBuilder();

    switch (action.field) {
      case Field.selectedDate:
        state.selectedDate = action.value;
        break;
      case Field.calendarFormat:
        state.format = action.value;
        break;
      default:
        assert(false);
    }

    _state.add(state.build());
  }

  void _onAddTodo(AddTodo action) {
    _state.add(_state.value.rebuild((b) => b..todoNameHasError = isBlank(action.todo.name)));

    if (_state.value.todoNameHasError) {
      return;
    }

    dependencies.todoInteractor.add(action.todo);
  }
}
