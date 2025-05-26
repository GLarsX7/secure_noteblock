import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/storage_service.dart';
import 'note_editor_screen.dart';

class NoteViewerScreen extends StatefulWidget {
  final Note note;
  final String password;

  const NoteViewerScreen({
    super.key,
    required this.note,
    required this.password,
  });

  @override
  State<NoteViewerScreen> createState() => _NoteViewerScreenState();
}

class _NoteViewerScreenState extends State<NoteViewerScreen> {
  String _title = '';
  String _content = '';
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNoteContent();
  }

  Future<void> _loadNoteContent() async {
    try {
      final title = StorageService.decryptTitle(widget.note, widget.password);
      final content = StorageService.decryptContent(widget.note, widget.password);
      
      setState(() {
        _title = title;
        _content = content;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _editNote() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          password: widget.password,
          note: widget.note,
          isNewNote: false,
        ),
      ),
    );
    
    if (result == true) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteNote(widget.note.id);
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Loading...' : (_title.isEmpty ? 'Untitled' : _title)),
        actions: [
          if (!_isLoading && !_hasError) ...[
            IconButton(
              onPressed: _editNote,
              icon: const Icon(Icons.edit),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _deleteNote();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to decrypt note',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The note may be corrupted or the password is incorrect.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loadNoteContent,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_title.isNotEmpty) ...[
                        Text(
                          _title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Updated ${_formatDate(widget.note.updatedAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_content.isNotEmpty)
                        Text(
                          _content,
                          style: Theme.of(context).textTheme.bodyLarge,
                        )
                      else
                        Text(
                          'This note is empty.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}