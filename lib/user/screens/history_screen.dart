import 'package:absensi_acara/user/widgets/event_history.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HistoryItem(title: 'title', date: 'date', status: 'status', time: 'time');
  }
}
