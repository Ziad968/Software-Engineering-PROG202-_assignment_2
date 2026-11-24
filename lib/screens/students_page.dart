import 'package:flutter/material.dart';
import '../services/results_service.dart';
import '../core/routes.dart';
import '../widgets/empty_state.dart';
import '../widgets/student_tile.dart';

/// Screen 4 (Tab 2): Role-aware student list (full searchable list for
/// Administrator/Lecturer; own result record for Student).
class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ResultsService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final filtered = service.searchStudents(_query);

        return Column(
          children: [
            if (service.canViewAllStudents)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _query = val),
                  decoration: InputDecoration(
                    hintText: 'Search by student name, ID, or programme...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_search,
                      title: 'No Students Found',
                      subtitle:
                          'Try a different search term or register a new student.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final student = filtered[index];
                        return StudentTile(
                          student: student,
                          onTap: () => Navigator.pushNamed(
                            context,
                            Routes.studentDetail,
                            arguments: student.studentId,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}