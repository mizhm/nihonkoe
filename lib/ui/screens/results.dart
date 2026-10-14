import 'package:flutter/material.dart';

import '../../api/models.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.query, this.sort = ListSort.newest, this.title});
  final ListQuery query;
  final ListSort sort;
  final String? title;
  @override
  Widget build(BuildContext context) => const Scaffold();
}
