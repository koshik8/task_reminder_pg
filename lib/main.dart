import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones(); // Initialize time zone database

  

  // Initialize notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // Handle notification tap (e.g., snooze or stop)
      if (response.actionId == 'snooze') {
        print("Snooze pressed");
      } else if (response.actionId == 'stop') {
        print("Stop pressed");
      }
    },
  );
  if (Platform.isAndroid) {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NewTaskScreen(),
    );
  }
}

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  _NewTaskScreenState createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  String repeatType = "Never";
  DateTime? filterDate;
  DateTime? taskDate;
  DateTime? selectedDate;
  TimeOfDay? reminderTime;
  bool isTillAlways = true;
  TextEditingController dateController = TextEditingController();
  TextEditingController taskController = TextEditingController();
  TextEditingController taskDateController = TextEditingController();
  List<bool> daysSelected = List.filled(7, false);
  List<Task> tasks = [];

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Date Field
            const Text(
              "Filter Date",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: (){testNotification();}, child: Text('test')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setState(() {
                          filterDate = picked;
                          dateController.text =
                              DateFormat.yMMMMd().format(filterDate!);
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      filterDate = null;
                      dateController.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Task Title Input
            TextField(
              controller: taskController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Task Date Field
            const Text(
              "Task Date",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: taskDateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  setState(() {
                    taskDate = picked;
                    taskDateController.text =
                        DateFormat.yMMMMd().format(taskDate!);
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // Reminder Time Field
            const Text(
              "Reminder Time",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    reminderTime = pickedTime;
                  });
                }
              },
              child: Text(
                reminderTime == null
                    ? "Select Time"
                    : "Selected Time: ${reminderTime!.format(context)}",
              ),
            ),
            const SizedBox(height: 20),

            // Repeat Section
            const Text(
              "Repeat",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final selectedRepeatType = await _showRepeatDialog(context);
                if (selectedRepeatType != null) {
                  setState(() {
                    repeatType = selectedRepeatType;
                  });
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      repeatType,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Add Task Button
            ElevatedButton(
              onPressed: () {
                _addTask();
              },
              child: const Text('Add Task'),
            ),
            const SizedBox(height: 20),

            // Task List
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  if (filterDate != null && !_shouldDisplayTask(task)) {
                    return Container(); // Skip tasks that don't match the filter
                  }
                  return ListTile(
                    title: Text(task.title),
                    subtitle: Text(
                        "${DateFormat.yMMMMd().format(task.date)} at ${task.reminderTime.format(context)}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          tasks.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showRepeatDialog(BuildContext context) {
    String localRepeatType = repeatType;

    return showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24))),
            titlePadding: const EdgeInsets.fromLTRB(125, 0, 12, 5),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Repeat",
                    style: TextStyle(color: Color(0xFF0D47A1))),
                IconButton(
                  icon: const Icon(Icons.check,
                      color: Color(0xFF0D47A1), size: 30),
                  onPressed: () {
                    Navigator.of(context).pop(localRepeatType);
                  },
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        localRepeatType = "Never";
                        isTillAlways = true;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Never", style: TextStyle(fontSize: 18)),
                        Icon(
                          localRepeatType == "Never" ? Icons.check : null,
                          color: const Color(0xFF0486FF),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        localRepeatType = "Days";
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Days", style: TextStyle(fontSize: 18)),
                        Icon(
                          localRepeatType == "Days" ? Icons.check : null,
                          color: const Color(0xFF0486FF),
                        ),
                      ],
                    ),
                  ),
                ),
                if (localRepeatType == "Days")
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      final days = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
                      return ChoiceChip(
                        label: Text(
                          days[index],
                          style: TextStyle(
                            color: daysSelected[index]
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                        selected: daysSelected[index],
                        onSelected: (selected) {
                          setState(() {
                            daysSelected[index] = selected;
                          });
                        },
                        shape: const CircleBorder(),
                        selectedColor: Colors.blue,
                        backgroundColor: const Color(0xFF004177),
                        showCheckmark: false,
                      );
                    }),
                  ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        localRepeatType = "Monthly";
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Monthly", style: TextStyle(fontSize: 18)),
                        Icon(
                          localRepeatType == "Monthly" ? Icons.check : null,
                          color: const Color(0xFF0486FF),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        localRepeatType = "Yearly";
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Yearly", style: TextStyle(fontSize: 18)),
                        Icon(
                          localRepeatType == "Yearly" ? Icons.check : null,
                          color: const Color(0xFF0486FF),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 8, 250, 8),
                  child: Text(
                    "Till",
                    style: TextStyle(
                      color: Color.fromARGB(255, 3, 44, 111),
                      fontSize: 20,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 32, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: isTillAlways,
                            onChanged: (value) {
                              setState(() {
                                isTillAlways = value!;
                              });
                            },
                          ),
                          const Text(
                            "Always",
                            style: TextStyle(
                                fontSize: 18, color: Color(0xFF004479)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Radio<bool>(
                            value: false,
                            groupValue: isTillAlways,
                            onChanged: (value) {
                              setState(() {
                                isTillAlways = !isTillAlways;
                              });
                            },
                          ),
                          const Text(
                            "Date",
                            style: TextStyle(
                                fontSize: 18, color: Color(0xFF0D47A1)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isTillAlways)
                  SizedBox(
                    height: 200,
                    width: 300,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: DateTime.now(),
                      onDateTimeChanged: (date) {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                    ),
                  ),
                const Divider(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addTask() {
    final title = taskController.text;
    if (title.isNotEmpty && taskDate != null && reminderTime != null) {
      setState(() {
        tasks.add(Task(
          title: title,
          date: taskDate!,
          reminderTime: reminderTime!,
          repeatType: repeatType,
          tillDate:
              (repeatType != "Never" && !isTillAlways) ? selectedDate : null,
        ));
        taskController.clear();
        taskDateController.clear();
        reminderTime = null;
        repeatType = "Never"; // Reset repeat type
        daysSelected = List.filled(7, false); // Reset days selection
      });

      // Schedule system notification
      _scheduleNotification(tasks.last);
    }
  }

  bool _shouldDisplayTask(Task task) {
    if (filterDate == null) return true; // Show all tasks if no filter date

    // Check if the task date matches the filter date
    if (task.date.year == filterDate!.year &&
        task.date.month == filterDate!.month &&
        task.date.day == filterDate!.day) {
      return true;
    }

    // Check repeat logic
    switch (task.repeatType) {
      case "Days":
        // Check if the filter date matches any of the selected days
        if (daysSelected[filterDate!.weekday % 7]) {
          return true;
        }
        break;
      case "Monthly":
        // Check if the filter date's day matches the task date's day
        if (task.date.day == filterDate!.day) {
          return true;
        }
        break;
      case "Yearly":
        // Check if the filter date's month and day match the task date's month and day
        if (task.date.month == filterDate!.month &&
            task.date.day == filterDate!.day) {
          return true;
        }
        break;
      default:
        // For "Never" or other cases, only show if the dates match exactly
        return false;
    }

    return false;
  }

  Future<void> _scheduleNotification(Task task) async {

  final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  final tz.Location _localTimeZone = tz.getLocation(timeZoneName);
  final DateTime notificationDate = DateTime(
    task.date.year,
    task.date.month,
    task.date.day,
    task.reminderTime.hour,
    task.reminderTime.minute,
  );

  
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'your_channel_id', // Channel ID
    'your_channel_name', // Channel Name
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('alarm'), // Sound file
  );

  // Create the notification channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Define notification details
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id', // Channel ID
    'your_channel_name', // Channel Name
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('alarm'), // Sound file
    enableVibration: true, // Enable vibration
    actions: [
      AndroidNotificationAction('snooze', 'Snooze'), // Snooze action
      AndroidNotificationAction('stop', 'Stop'), // Stop action
    ],
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  
  /*await flutterLocalNotificationsPlugin.zonedSchedule(
    task.hashCode, // Unique ID for the notification
    'Task Reminder', // Notification title
    'Time to complete: ${task.title}', // Notification body
    tz.TZDateTime.from(notificationDate, _localTimeZone), // Scheduled time
    platformChannelSpecifics,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Exact scheduling
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );*/
  await flutterLocalNotificationsPlugin.zonedSchedule(
  0, // Unique ID for the notification
  'Test Notification', // Notification title
  'This is a test notification', // Notification body
  tz.TZDateTime.now(_localTimeZone).add(const Duration(seconds: 5)), // Schedule after 5 seconds
  platformChannelSpecifics,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
);
}

Future<void> testNotification() async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Instant Notification',
    'This should appear immediately!',
    platformChannelSpecifics,
  );
}

}

class Task {
  final String title;
  final DateTime date;
  final TimeOfDay reminderTime;
  final String repeatType;
  final DateTime? tillDate;

  Task({
    required this.title,
    required this.date,
    required this.reminderTime,
    required this.repeatType,
    this.tillDate,
  });
}