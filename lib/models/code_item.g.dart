// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CodeItemAdapter extends TypeAdapter<CodeItem> {
  @override
  final int typeId = 0;

  @override
  CodeItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CodeItem(
      type: fields[1] as String,
      subtype: fields[2] as String,
      data: fields[3] as String,
      label: fields[4] as String,
      isGenerated: fields[7] as bool,
      imagePath: fields[8] as String?,
    )
      ..id = fields[0] as String
      ..createdAt = fields[5] as DateTime
      ..isFavorite = fields[6] as bool;
  }

  @override
  void write(BinaryWriter writer, CodeItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.subtype)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.label)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isFavorite)
      ..writeByte(7)
      ..write(obj.isGenerated)
      ..writeByte(8)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
