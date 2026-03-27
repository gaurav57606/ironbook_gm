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
import '../models/product_model.dart';
import '../models/sale_model.dart';

class DomainEventAdapter extends TypeAdapter<DomainEvent> {
  @override
  final int typeId = 10;

  @override
  DomainEvent read(BinaryReader reader) {
    return DomainEvent(
      id: reader.read() as String,
      entityId: reader.read() as String,
      eventType: reader.read() as String,
      payload: Map<String, dynamic>.from(reader.read()),
      deviceTimestamp: DateTime.fromMillisecondsSinceEpoch((reader.read() as num).toInt()),
      synced: reader.read() as bool,
      hmacSignature: reader.read() as String,
      deviceId: reader.read() as String,
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
    final memberId = reader.read() as String;
    final name = reader.read() as String;
    final phone = reader.read() as String;
    final joinDate = DateTime.fromMillisecondsSinceEpoch((reader.read() as num).toInt());
    final planId = reader.read() as String?;
    final planName = reader.read() as String?;
    final expiryTs = reader.read() as num?;
    final expiryDate = expiryTs != null ? DateTime.fromMillisecondsSinceEpoch(expiryTs.toInt()) : null;
    
    final totalPaid = (reader.read() as num).toInt();
    final paymentIds = List<String>.from(reader.read());
    final joinDateHistory = List<JoinDateChange>.from(reader.read());
    final archived = reader.read() as bool;
    final lastUpdated = DateTime.fromMillisecondsSinceEpoch((reader.read() as num).toInt());
    final gender = reader.read() as String?;
    final age = (reader.read() as num?)?.toInt();
    final checkInPin = reader.read() as String?;
    
    return MemberSnapshot(
      memberId: memberId,
      name: name,
      phone: phone,
      joinDate: joinDate,
      planId: planId,
      planName: planName,
      expiryDate: expiryDate,
      totalPaid: totalPaid,
      paymentIds: paymentIds,
      joinDateHistory: joinDateHistory,
      archived: archived,
      lastUpdated: lastUpdated,
      gender: gender,
      age: age,
      checkInPin: checkInPin,
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
    writer.write(obj.gender);
    writer.write(obj.age);
    writer.write(obj.checkInPin);
  }
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 1;

  @override
  Payment read(BinaryReader reader) {
    return Payment(
      id: reader.read() as String,
      memberId: reader.read() as String,
      date: DateTime.fromMillisecondsSinceEpoch((reader.read() as num).toInt()),
      amount: (reader.read() as num).toDouble(),
      method: reader.read() as String,
      reference: reader.read() as String?,
      planId: reader.read() as String,
      planName: reader.read() as String,
      components: List<PlanComponentSnapshot>.from(reader.read()),
      invoiceNumber: reader.read() as String,
      subtotal: (reader.read() as num).toDouble(),
      gstAmount: (reader.read() as num).toDouble(),
      gstRate: (reader.read() as num).toDouble(),
      durationMonths: (reader.read() as num).toInt(),
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
      id: reader.read() as String,
      name: reader.read() as String,
      durationMonths: (reader.read() as num).toInt(),
      components: List<PlanComponent>.from(reader.read()),
      active: reader.read() as bool,
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
      id: reader.read() as String,
      name: reader.read() as String,
      price: (reader.read() as num).toDouble(),
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
  final int typeId = 13;

  @override
  PlanComponentSnapshot read(BinaryReader reader) {
    return PlanComponentSnapshot(
      name: reader.read() as String,
      price: (reader.read() as num).toDouble(),
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
      previousDate: DateTime.fromMillisecondsSinceEpoch((reader.read() as num).toInt()),
      newDate: DateTime.fromMillisecondsSinceEpoch((reader.read() as num).toInt()),
      reason: reader.read() as String,
      changedAt: DateTime.fromMillisecondsSinceEpoch((reader.read() as num).toInt()),
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
      gstRate: (reader.read() as num).toDouble(),
      expiryReminderDays: (reader.read() as num).toInt(),
      whatsappReminders: reader.read() as bool,
      biometricEnabled: reader.read() as bool,
      businessType: reader.read() as String,
      useBiometrics: reader.read() as bool,
      auditMode: reader.read() as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer.write(obj.gstRate);
    writer.write(obj.expiryReminderDays);
    writer.write(obj.whatsappReminders);
    writer.write(obj.biometricEnabled);
    writer.write(obj.businessType);
    writer.write(obj.useBiometrics);
    writer.write(obj.auditMode);
  }
}

class InvoiceSequenceAdapter extends TypeAdapter<InvoiceSequence> {
  @override
  final int typeId = 12;

  @override
  InvoiceSequence read(BinaryReader reader) {
    return InvoiceSequence(
      prefix: reader.read() as String,
      nextNumber: (reader.read() as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceSequence obj) {
    writer.write(obj.prefix);
    writer.write(obj.nextNumber);
  }
}

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 14;

  @override
  Product read(BinaryReader reader) {
    return Product(
      id: reader.read() as String,
      name: reader.read() as String,
      price: (reader.read() as num).toDouble(),
      category: reader.read() as String,
      iconCodePoint: (reader.read() as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.price);
    writer.write(obj.category);
    writer.write(obj.iconCodePoint);
  }
}

class SaleAdapter extends TypeAdapter<Sale> {
  @override
  final int typeId = 15;

  @override
  Sale read(BinaryReader reader) {
    return Sale(
      id: reader.read() as String,
      date: DateTime.fromMillisecondsSinceEpoch((reader.read() as num).toInt()),
      totalAmount: (reader.read() as num).toDouble(),
      paymentMethod: reader.read() as String,
      items: List<SaleItem>.from(reader.read()),
      invoiceNumber: reader.read() as String,
    );
  }

  @override
  void write(BinaryWriter writer, Sale obj) {
    writer.write(obj.id);
    writer.write(obj.date.millisecondsSinceEpoch);
    writer.write(obj.totalAmount);
    writer.write(obj.paymentMethod);
    writer.write(obj.items);
    writer.write(obj.invoiceNumber);
  }
}

class SaleItemAdapter extends TypeAdapter<SaleItem> {
  @override
  final int typeId = 16;

  @override
  SaleItem read(BinaryReader reader) {
    return SaleItem(
      productId: reader.read() as String,
      productName: reader.read() as String,
      price: (reader.read() as num).toDouble(),
      quantity: (reader.read() as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, SaleItem obj) {
    writer.write(obj.productId);
    writer.write(obj.productName);
    writer.write(obj.price);
    writer.write(obj.quantity);
  }
}
