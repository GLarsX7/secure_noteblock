import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/storage_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final String password;
  final Note? note;
  final bool isNewNote;

  const NoteEditorScreen({
    super.key,
    required this.password,
    this.note,
    this.isNewNote = false,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    
    if (!widget.isNewNote && widget.note != null) {
      _loadNoteContent();
    }
    
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _loadNoteContent() async {
    try {
      final title = StorageService.decryptTitle(widget.note!, widget.password);
      final content = StorageService.decryptContent(widget.note!, widget.password);
      
      setState(() {
        _titleController.text = title;
        _contentController.text = content;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to decrypt note')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveNote() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      
      if (title.isEmpty && content.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot save empty note')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (widget.isNewNote) {
        final note = StorageService.createEncryptedNote(title, content, widget.password);
        await StorageService.saveNote(note);
      } else {
        final updatedNote = StorageService.updateEncryptedNote(
          widget.note!,
          title,
          content,
          widget.password,
        );
        await StorageService.saveNote(updatedNote);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save note')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return shouldDiscard ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isNewNote ? 'New Note' : 'Edit Note'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveNote,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Note title...',
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
              ),
              const Divider(),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Start writing your note...',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}