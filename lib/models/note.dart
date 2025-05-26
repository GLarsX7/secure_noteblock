import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String encryptedTitle;

  @HiveField(2)
  String encryptedContent;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  Note({
    required this.id,
    required this.encryptedTitle,
    required this.encryptedContent,
    required this.createdAt,
    required this.updatedAt,
  });

  Note.create({
    required this.encryptedTitle,
    required this.encryptedContent,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = DateTime.now(),
       updatedAt = DateTime.now();
}