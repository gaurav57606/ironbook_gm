import 'package:hive/hive.dart';
import '../models/domain_event_model.dart';
import '../models/member_snapshot_model.dart';
import '../models/payment_model.dart';
import '../models/plan_model.dart';
import '../models/plan_component_model.dart';
import '../models/invoice_sequence.dart';
import '../models/owner_profile_model.dart';
import '../models/app_settings_model.dart';
import '../models/join_date_change_model.dart';

class DomainEventAdapter extends TypeAdapter<DomainEvent> {
  @override
  final int typeId = 10;

  @override
  DomainEvent read(BinaryReader reader) {
    return DomainEvent(
      id: reader.read(),
      entityId: reader.read(),
      eventType: reader.read(),
      payload: Map<String, dynamic>.from(reader.read()),
      deviceTimestamp: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      synced: reader.read(),
      hmacSignature: reader.read(),
      deviceId: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, DomainEvent obj) {
    writer.write(obj.id);
    writer.write(obj.entityId);
    writer.write(obj.eventType);
    writer.write(obj.payload);
    writer.write(obj.deviceTimestamp.millisecondsSinceEpoch);
    writer.write(obj.synced);
    writer.write(obj.hmacSignature);
    writer.write(obj.deviceId);
  }
}

class MemberSnapshotAdapter extends TypeAdapter<MemberSnapshot> {
  @override
  final int typeId = 11;

  @override
  MemberSnapshot read(BinaryReader reader) {
    return MemberSnapshot(
      memberId: reader.read(),
      name: reader.read(),
      phone: reader.read(),
      joinDate: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      planId: reader.read(),
      planName: reader.read(),
      expiryDate: reader.read() != null ? DateTime.fromMillisecondsSinceEpoch(reader.read()) : null,
      totalPaid: reader.read(),
      paymentIds: List<String>.from(reader.read()),
      joinDateHistory: List<JoinDateChange>.from(reader.read()),
      archived: reader.read(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(reader.read()),
    );
  }

  @override
  void write(BinaryWriter writer, MemberSnapshot obj) {
    writer.write(obj.memberId);
    writer.write(obj.name);
    writer.write(obj.phone);
    writer.write(obj.joinDate.millisecondsSinceEpoch);
    writer.write(obj.planId);
    writer.write(obj.planName);
    writer.write(obj.expiryDate?.millisecondsSinceEpoch);
    writer.write(obj.totalPaid);
    writer.write(obj.paymentIds);
    writer.write(obj.joinDateHistory);
    writer.write(obj.archived);
    writer.write(obj.lastUpdated.millisecondsSinceEpoch);
  }
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 1;

  @override
  Payment read(BinaryReader reader) {
    return Payment(
      id: reader.read(),
      memberId: reader.read(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      amount: reader.read(),
      method: reader.read(),
      reference: reader.read(),
      planId: reader.read(),
      planName: reader.read(),
      components: List<PlanComponentSnapshot>.from(reader.read()),
      invoiceNumber: reader.read(),
      subtotal: reader.read(),
      gstAmount: reader.read(),
      gstRate: reader.read(),
      durationMonths: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer.write(obj.id);
    writer.write(obj.memberId);
    writer.write(obj.date.millisecondsSinceEpoch);
    writer.write(obj.amount);
    writer.write(obj.method);
    writer.write(obj.reference);
    writer.write(obj.planId);
    writer.write(obj.planName);
    writer.write(obj.components);
    writer.write(obj.invoiceNumber);
    writer.write(obj.subtotal);
    writer.write(obj.gstAmount);
    writer.write(obj.gstRate);
    writer.write(obj.durationMonths);
  }
}

class PlanAdapter extends TypeAdapter<Plan> {
  @override
  final int typeId = 2;

  @override
  Plan read(BinaryReader reader) {
    return Plan(
      id: reader.read(),
      name: reader.read(),
      durationMonths: reader.read(),
      components: List<PlanComponent>.from(reader.read()),
      active: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Plan obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.durationMonths);
    writer.write(obj.components);
    writer.write(obj.active);
  }
}

class PlanComponentAdapter extends TypeAdapter<PlanComponent> {
  @override
  final int typeId = 3;

  @override
  PlanComponent read(BinaryReader reader) {
    return PlanComponent(
      id: reader.read(),
      name: reader.read(),
      price: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, PlanComponent obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.price);
  }
}

class PlanComponentSnapshotAdapter extends TypeAdapter<PlanComponentSnapshot> {
  @override
  final int typeId = 8;

  @override
  PlanComponentSnapshot read(BinaryReader reader) {
    return PlanComponentSnapshot(
      name: reader.read(),
      price: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, PlanComponentSnapshot obj) {
    writer.write(obj.name);
    writer.write(obj.price);
  }
}

class JoinDateChangeAdapter extends TypeAdapter<JoinDateChange> {
  @override
  final int typeId = 5;

  @override
  JoinDateChange read(BinaryReader reader) {
    return JoinDateChange(
      previousDate: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      newDate: DateTime.fromMillisecondsSinceEpoch(reader.read()),
      reason: reader.read(),
      changedAt: DateTime.fromMillisecondsSinceEpoch(reader.read()),
    );
  }

  @override
  void write(BinaryWriter writer, JoinDateChange obj) {
    writer.write(obj.previousDate.millisecondsSinceEpoch);
    writer.write(obj.newDate.millisecondsSinceEpoch);
    writer.write(obj.reason);
    writer.write(obj.changedAt.millisecondsSinceEpoch);
  }
}

class OwnerProfileAdapter extends TypeAdapter<OwnerProfile> {
  @override
  final int typeId = 4;

  @override
  OwnerProfile read(BinaryReader reader) {
    return OwnerProfile(
      gymName: reader.read(),
      ownerName: reader.read(),
      phone: reader.read(),
      address: reader.read(),
      gstin: reader.read(),
      bankName: reader.read(),
      accountNumber: reader.read(),
      ifsc: reader.read(),
      upiId: reader.read(),
      logoPath: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, OwnerProfile obj) {
    writer.write(obj.gymName);
    writer.write(obj.ownerName);
    writer.write(obj.phone);
    writer.write(obj.address);
    writer.write(obj.gstin);
    writer.write(obj.bankName);
    writer.write(obj.accountNumber);
    writer.write(obj.ifsc);
    writer.write(obj.upiId);
    writer.write(obj.logoPath);
  }
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 6;

  @override
  AppSettings read(BinaryReader reader) {
    return AppSettings(
      gstRate: reader.read(),
      expiryReminderDays: reader.read(),
      whatsappReminders: reader.read(),
      biometricEnabled: reader.read(),
      businessType: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer.write(obj.gstRate);
    writer.write(obj.expiryReminderDays);
    writer.write(obj.whatsappReminders);
    writer.write(obj.biometricEnabled);
    writer.write(obj.businessType);
  }
}

class InvoiceSequenceAdapter extends TypeAdapter<InvoiceSequence> {
  @override
  final int typeId = 12;

  @override
  InvoiceSequence read(BinaryReader reader) {
    return InvoiceSequence(
      prefix: reader.read(),
      nextNumber: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceSequence obj) {
    writer.write(obj.prefix);
    writer.write(obj.nextNumber);
  }
}
