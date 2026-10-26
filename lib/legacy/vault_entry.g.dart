// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VaultEntryAdapter extends TypeAdapter<VaultEntry> {
  @override
  final int typeId = 0;

  @override
  VaultEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VaultEntry(
      title: fields[0] as String,
      username: fields[1] as String,
      password: fields[2] as String,
      url: fields[3] as String,
      category: fields[4] as String,
      notes: fields[5] as String,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VaultEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
