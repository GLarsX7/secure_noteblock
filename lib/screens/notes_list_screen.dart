import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/storage_service.dart';
import 'note_editor_screen.dart';
import 'note_viewer_screen.dart';

class NotesListScreen extends StatefulWidget {
  final String password;
  final VoidCallback onThemeToggle;

  const NotesListScreen({
    super.key,
    required this.password,
    required this.onThemeToggle,
  });

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    setState(() {
      _notes = StorageService.getAllNotes();
    });
  }

  Future<void> _createNewNote() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          password: widget.password,
          isNewNote: true,
        ),
      ),
    );
    
    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _viewNote(Note note) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => NoteViewerScreen(
          note: note,
          password: widget.password,
        ),
      ),
    );
    
    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _deleteNote(Note note) async {
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
      await StorageService.deleteNote(note.id);
      _loadNotes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      }
    }
  }

  String _getDecryptedTitle(Note note) {
    try {
      return StorageService.decryptTitle(note, widget.password);
    } catch (e) {
      return 'Unable to decrypt';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure NoteBlock'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
          ),
        ],
      ),
      body: _notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first encrypted note',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                final title = _getDecryptedTitle(note);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      title.isEmpty ? 'Untitled' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: title == 'Unable to decrypt' 
                          ? TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontStyle: FontStyle.italic,
                            )
                          : null,
                    ),
                    subtitle: Text(_formatDate(note.updatedAt)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'delete':
                            _deleteNote(note);
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
                    onTap: () => _viewNote(note),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}