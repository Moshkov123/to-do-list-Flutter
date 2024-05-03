import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class TodoList extends StatefulWidget {
  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  List<Map<String, dynamic>> todos = [];
  TextEditingController _controller = TextEditingController();
  Set<Map<String, dynamic>> selectedItems = Set<Map<String, dynamic>>();
  Dio dio = Dio();

  Future<void> fetchTodos() async {
    try {
      Response response = await dio.get('http://127.0.0.1:8000/api/todo');
      print('Fetch todos response: ${response.data}'); // Log the response for debugging
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        setState(() {
          todos = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Failed to load todos');
      }
    } catch (e) {
      print('Failed to load todos: $e');
    }
  }

  void addTodo(String text) async {
    try {
      await dio.post('http://127.0.0.1:8000/api/todo', data: {'text': text});
      fetchTodos();
    } catch (e) {
      print('Failed to add todo: $e');
    }
  }

  void updateTodo(int id, String newText) async {
    try {
      await dio.put('http://127.0.0.1:8000/api/todo/$id', data: {'text': newText});
      fetchTodos();
    } catch (e) {
      print('Failed to update todo: $e');
    }
  }

  void deleteTodo(Map<String, dynamic> todo) async {
    try {
      int id = todo['id']; // Extract the id from the todo item
      await dio.delete('http://127.0.0.1:8000/api/todo/$id');
      fetchTodos();
    } catch (e) {
      print('Failed to delete todo: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTodos(); // Вызов функции для получения задач при инициализации виджета
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
        actions: [
          if (selectedItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // Удалите выбранные задачи
                selectedItems.forEach((todo) {
                  deleteTodo(todo);
                });
                setState(() {
                  selectedItems.clear();
                });
              },
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          return Dismissible(
            key: Key(todo.toString()),
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20.0),
              color: Colors.red,
              child: Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              setState(() {
                deleteTodo(todo);
              });
            },
            child: ListTile(
              title: Text(todo['text']),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return FocusScope(
                        child: AlertDialog(
                          title: Text('Редактировать'),
                          content: TextField(
                            controller: _controller,
                            autofocus: true,
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Add'),
                              onPressed: () {
                                updateTodo(todo['id'], _controller.text);
                                _controller.clear();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              onTap: () {
                setState(() {
                  if (selectedItems.contains(todo)) {
                    selectedItems.remove(todo);
                  } else {
                    selectedItems.add(todo);
                  }
                });
              },
              onLongPress: () {
                setState(() {
                  selectedItems.add(todo);
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.clear();
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return FocusScope(
                child: AlertDialog(
                  title: Text('Add Task'),
                  content: TextField(
                    controller: _controller,
                    autofocus: true,
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Add'),
                      onPressed: () {
                        addTodo(_controller.text);
                        _controller.clear();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}