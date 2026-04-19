import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doantotnghiep/core/theme/app_theme.dart';
import 'question_list_tab.dart';
import 'ask_question_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community Q&A'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Questions'),
              Tab(text: 'My Questions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            QuestionListTab(filter: 'all'),
            QuestionListTab(filter: 'my'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
             Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AskQuestionScreen()));
          },
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
