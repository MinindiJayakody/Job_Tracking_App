import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const JobTrackerApp());
}

enum JobStatus { saved, toApply, applied }

extension JobStatusX on JobStatus {
  String get label => switch (this) {
        JobStatus.saved => 'Saved',
        JobStatus.toApply => 'To apply',
        JobStatus.applied => 'Applied',
      };

  String get storageValue => name;

  Color color(ColorScheme scheme) => switch (this) {
        JobStatus.saved => scheme.tertiary,
        JobStatus.toApply => scheme.primary,
        JobStatus.applied => Colors.green,
      };
}

class JobOpportunity {
  const JobOpportunity({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final String description;
  final JobStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  JobOpportunity copyWith({
    String? id,
    String? title,
    String? company,
    String? location,
    String? salary,
    String? description,
    JobStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobOpportunity(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'salary': salary,
      'description': description,
      'status': status.storageValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory JobOpportunity.fromJson(Map<String, dynamic> json) {
    return JobOpportunity(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
      location: json['location'] as String,
      salary: json['salary'] as String,
      description: json['description'] as String,
      status: JobStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => JobStatus.saved,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class JobTrackerApp extends StatelessWidget {
  const JobTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF145A5C);
    final scheme = ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Job Tracker',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: const JobTrackerHome(),
    );
  }
}

class JobTrackerHome extends StatefulWidget {
  const JobTrackerHome({super.key});

  @override
  State<JobTrackerHome> createState() => _JobTrackerHomeState();
}

class _JobTrackerHomeState extends State<JobTrackerHome> {
  static const String _storageKey = 'job_tracker.jobs.v1';

  final List<JobOpportunity> _seedJobs = <JobOpportunity>[
    JobOpportunity(
      id: 'seed-1',
      title: 'Flutter Developer',
      company: 'CloudLine Studio',
      location: 'Remote',
      salary: 'PKR 80k - 120k',
      description: 'Build customer-facing mobile products with Flutter and Firebase.',
      status: JobStatus.toApply,
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    ),
    JobOpportunity(
      id: 'seed-2',
      title: 'Junior Mobile Engineer',
      company: 'Nexa Works',
      location: 'Lahore',
      salary: 'PKR 70k - 90k',
      description: 'Support app features, bug fixes, and release preparation.',
      status: JobStatus.saved,
      createdAt: DateTime(2026, 9, 3),
      updatedAt: DateTime(2026, 9, 3),
    ),
    JobOpportunity(
      id: 'seed-3',
      title: 'Product Designer',
      company: 'ArcByte',
      location: 'Hybrid',
      salary: 'PKR 110k - 150k',
      description: 'Design dashboards and mobile flows for a growing startup team.',
      status: JobStatus.applied,
      createdAt: DateTime(2026, 8, 28),
      updatedAt: DateTime(2026, 9, 5),
    ),
  ];

  bool _isLoading = true;
  String _searchQuery = '';
  List<JobOpportunity> _jobs = <JobOpportunity>[];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJobs = prefs.getString(_storageKey);

    if (rawJobs == null || rawJobs.isEmpty) {
      _jobs = List<JobOpportunity>.from(_seedJobs);
      await prefs.setString(
        _storageKey,
        jsonEncode(_jobs.map((job) => job.toJson()).toList()),
      );
    } else {
      final decoded = jsonDecode(rawJobs) as List<dynamic>;
      _jobs = decoded
          .map((item) => JobOpportunity.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    _sortJobs();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortJobs() {
    _jobs.sort((left, right) {
      final statusOrder = <JobStatus, int>{
        JobStatus.toApply: 0,
        JobStatus.saved: 1,
        JobStatus.applied: 2,
      };
      final statusCompare = statusOrder[left.status]!.compareTo(statusOrder[right.status]!);
      if (statusCompare != 0) {
        return statusCompare;
      }
      return right.updatedAt
              ?.compareTo(left.updatedAt ?? left.createdAt) ??
          right.createdAt.compareTo(left.createdAt);
    });
  }

  Future<void> _persistJobs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_jobs.map((job) => job.toJson()).toList()),
    );
  }

  List<JobOpportunity> get _filteredJobs {
    final query = _searchQuery.trim().toLowerCase();
    return _jobs.where((job) {
      final matchesQuery = query.isEmpty ||
          job.title.toLowerCase().contains(query) ||
          job.company.toLowerCase().contains(query) ||
          job.location.toLowerCase().contains(query) ||
          job.salary.toLowerCase().contains(query) ||
          job.description.toLowerCase().contains(query);
      return matchesQuery;
    }).toList();
  }

  int _countFor(JobStatus status) => _jobs.where((job) => job.status == status).length;

  Future<void> _upsertJob(JobOpportunity job) async {
    setState(() {
      final index = _jobs.indexWhere((item) => item.id == job.id);
      if (index == -1) {
        _jobs.insert(0, job);
      } else {
        _jobs[index] = job;
      }
      _sortJobs();
    });
    await _persistJobs();
  }

  Future<void> _deleteJob(String id) async {
    setState(() {
      _jobs.removeWhere((job) => job.id == id);
    });
    await _persistJobs();
  }

  Future<void> _changeStatus(JobOpportunity job, JobStatus status) async {
    await _upsertJob(
      job.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${job.title} moved to ${status.label}')),
    );
  }

  Future<void> _showAddJobSheet() async {
    final result = await showModalBottomSheet<JobOpportunity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _JobEditorSheet(
        title: 'Add job',
        submitLabel: 'Save job',
        initialStatus: JobStatus.saved,
      ),
    );

    if (result != null) {
      await _upsertJob(
        result.copyWith(
          id: 'job-${DateTime.now().microsecondsSinceEpoch}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _showJobActions(JobOpportunity job) async {
    final action = await showModalBottomSheet<_JobAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => _JobActionsSheet(job: job),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _JobAction.edit:
        final result = await showModalBottomSheet<JobOpportunity>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => _JobEditorSheet(
            title: 'Edit job',
            submitLabel: 'Update job',
            initialJob: job,
            initialStatus: job.status,
          ),
        );
        if (result != null) {
          await _upsertJob(
            result.copyWith(
              id: job.id,
              createdAt: job.createdAt,
              updatedAt: DateTime.now(),
            ),
          );
        }
        break;
      case _JobAction.delete:
        await _deleteJob(job.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${job.title} removed')),
          );
        }
        break;
    }
  }

  Widget _buildSummaryCard(BuildContext context, String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color)),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(JobOpportunity job) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showJobActions(job),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: <Color>[scheme.primary, scheme.primaryContainer],
                      ),
                    ),
                    child: const Icon(Icons.work_outline, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${job.company}  •  ${job.location}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: job.status),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                job.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.payments_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(job.salary, style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (job.status != JobStatus.toApply)
                    FilledButton.tonal(
                      onPressed: () => _changeStatus(job, JobStatus.toApply),
                      child: const Text('Move to apply'),
                    ),
                  if (job.status != JobStatus.saved)
                    OutlinedButton(
                      onPressed: () => _changeStatus(job, JobStatus.saved),
                      child: const Text('Save'),
                    ),
                  if (job.status != JobStatus.applied)
                    FilledButton(
                      onPressed: () => _changeStatus(job, JobStatus.applied),
                      child: const Text('Mark applied'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobList(List<JobOpportunity> jobs, JobStatus? statusFilter) {
    final filteredJobs = jobs.where((job) => statusFilter == null || job.status == statusFilter).toList();

    if (filteredJobs.isEmpty) {
      return _EmptyState(
        title: _searchQuery.isEmpty
            ? 'No jobs in this section yet'
            : 'No jobs match your search',
        message: _searchQuery.isEmpty
            ? 'Add a vacancy or move one of the current jobs into this bucket.'
            : 'Try another keyword or clear the search field.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: filteredJobs.length,
      separatorBuilder: (context, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _buildJobCard(filteredJobs[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filteredJobs = _filteredJobs;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddJobSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add job'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF8FBFA), Color(0xFFE7F1EF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Job Tracker',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Track vacancies you are interested in, jobs you still need to apply for, and the roles you already submitted.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.black54,
                                    height: 1.35,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                _buildSummaryCard(context, 'To apply', _countFor(JobStatus.toApply), scheme.primary),
                                const SizedBox(width: 12),
                                _buildSummaryCard(context, 'Saved', _countFor(JobStatus.saved), scheme.tertiary),
                                const SizedBox(width: 12),
                                _buildSummaryCard(context, 'Applied', _countFor(JobStatus.applied), Colors.green),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              onChanged: (value) => setState(() => _searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search title, company, location, or salary',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: TabBar(
                            dividerColor: Colors.transparent,
                            indicatorSize: TabBarIndicatorSize.tab,
                            tabs: const [
                              Tab(text: 'All'),
                              Tab(text: 'To apply'),
                              Tab(text: 'Saved'),
                              Tab(text: 'Applied'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildJobList(filteredJobs, null),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildJobList(filteredJobs, JobStatus.toApply),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildJobList(filteredJobs, JobStatus.saved),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildJobList(filteredJobs, JobStatus.applied),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color(Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.work_outline,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

enum _JobAction { edit, delete }

class _JobActionsSheet extends StatelessWidget {
  const _JobActionsSheet({required this.job});

  final JobOpportunity job;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${job.company} • ${job.location}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit job'),
              onTap: () => Navigator.pop(context, _JobAction.edit),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete job'),
              onTap: () => Navigator.pop(context, _JobAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobEditorSheet extends StatefulWidget {
  const _JobEditorSheet({
    required this.title,
    required this.submitLabel,
    required this.initialStatus,
    this.initialJob,
  });

  final String title;
  final String submitLabel;
  final JobStatus initialStatus;
  final JobOpportunity? initialJob;

  @override
  State<_JobEditorSheet> createState() => _JobEditorSheetState();
}

class _JobEditorSheetState extends State<_JobEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _companyController;
  late final TextEditingController _locationController;
  late final TextEditingController _salaryController;
  late final TextEditingController _descriptionController;
  late JobStatus _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialJob?.title ?? '');
    _companyController = TextEditingController(text: widget.initialJob?.company ?? '');
    _locationController = TextEditingController(text: widget.initialJob?.location ?? '');
    _salaryController = TextEditingController(text: widget.initialJob?.salary ?? '');
    _descriptionController = TextEditingController(text: widget.initialJob?.description ?? '');
    _status = widget.initialJob?.status ?? widget.initialStatus;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty || _companyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least a title and company.')),
      );
      return;
    }

    Navigator.pop(
      context,
      JobOpportunity(
        id: widget.initialJob?.id ?? 'temp',
        title: _titleController.text.trim(),
        company: _companyController.text.trim(),
        location: _locationController.text.trim().isEmpty ? 'Remote' : _locationController.text.trim(),
        salary: _salaryController.text.trim().isEmpty ? 'Salary not listed' : _salaryController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? 'No extra notes yet.'
            : _descriptionController.text.trim(),
        status: _status,
        createdAt: widget.initialJob?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            _EditorField(controller: _titleController, label: 'Job title'),
            const SizedBox(height: 12),
            _EditorField(controller: _companyController, label: 'Company'),
            const SizedBox(height: 12),
            _EditorField(controller: _locationController, label: 'Location'),
            const SizedBox(height: 12),
            _EditorField(controller: _salaryController, label: 'Salary / package'),
            const SizedBox(height: 12),
            _EditorField(
              controller: _descriptionController,
              label: 'Notes',
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<JobStatus>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Status',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: JobStatus.values
                  .map(
                    (status) => DropdownMenuItem<JobStatus>(
                      value: status,
                      child: Text(status.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(widget.submitLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.label,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
