import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:doantotnghiep/core/theme/app_theme.dart';
import '../data/smart_match_repository.dart';

class LearningStyleQuizScreen extends ConsumerStatefulWidget {
  const LearningStyleQuizScreen({super.key});

  @override
  ConsumerState<LearningStyleQuizScreen> createState() => _LearningStyleQuizScreenState();
}

class _LearningStyleQuizScreenState extends ConsumerState<LearningStyleQuizScreen> {
  final List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'Visual', 'Auditory', 'Kinesthetic', 'Beginner', 'Advanced',
    'Fast-paced', 'Slow-paced', 'Theory-focused', 'Practice-focused',
    'Exam Prep', 'Conversational', 'Business'
  ];

  bool _isLoading = false;

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one tag.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(smartMatchRepositoryProvider);
      await repo.saveLearningTags(_selectedTags); // Save preferences
      
      if (mounted) {
         // Pass tags to results screen or just navigate and let it fetch from user profile/state
         // For now, passing tags via extra or argument could be useful, 
         // but simpler to just navigate and let the results screen fetch matches based on saved profile.
         // However, the API getMatches allows passing tags directly.
         
         context.push('/smart-match/results', extra: _selectedTags);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Style & Goals'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What are your learning preferences?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Select tags that describe you best to help AI match you with the perfect tutor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return InkWell(
                    onTap: () => _toggleTag(tag),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                        ),
                        boxShadow: [
                          if (!isSelected)
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                            )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Find My Tutors', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
