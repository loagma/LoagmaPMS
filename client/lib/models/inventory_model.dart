import 'dart:convert';
import 'package:flutter/material.dart';

class VendorProduct {
  final int id;
  final int vendorId;
  final int productId;
  final String productName;
  final String status;
  final String inStock;
  final List<Pack> packs;
  final String? defaultPackId;
  final double? totalStock; // Calculated total stock in base units

  VendorProduct({
    required this.id,
    required this.vendorId,
    required this.productId,
    required this.productName,
    required this.status,
    required this.inStock,
    required this.packs,
    this.defaultPackId,
    this.totalStock,
  });

  factory VendorProduct.fromJson(Map<String, dynamic> json) {
    final packsList = <Pack>[];

    if (json['packs'] != null) {
      if (json['packs'] is String) {
        // Parse JSON string
        try {
          final packsData = json['packs'] as String;
          if (packsData.isNotEmpty && packsData != '[]' && packsData != '{}') {
            final decoded = jsonDecode(packsData);

            if (decoded is List) {
              // Array format: [{"pi": "pack1", ...}, {"pi": "pack2", ...}]
              packsList.addAll(
                decoded.map((p) => Pack.fromJson(p as Map<String, dynamic>)),
              );
            } else if (decoded is Map) {
              // Object format: {"pack1": {...}, "pack2": {...}}
              decoded.forEach((key, value) {
                if (value is Map<String, dynamic>) {
                  // Ensure the pack has a pack_id (pi field)
                  if (!value.containsKey('pi')) {
                    value['pi'] = key; // Use the key as pack_id if not present
                  }
                  packsList.add(Pack.fromJson(value));
                }
              });
            }
          }
        } catch (e) {
          debugPrint('[INVENTORY] Failed to parse packs JSON: $e');
        }
      } else if (json['packs'] is List) {
        packsList.addAll(
          (json['packs'] as List).map(
            (p) => Pack.fromJson(p as Map<String, dynamic>),
          ),
        );
      } else if (json['packs'] is Map) {
        // Handle Map directly (not as string)
        final packsMap = json['packs'] as Map<String, dynamic>;
        packsMap.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            if (!value.containsKey('pi')) {
              value['pi'] = key;
            }
            packsList.add(Pack.fromJson(value));
          }
        });
      }
    }

    return VendorProduct(
      id: json['id'] ?? 0,
      vendorId: json['admin_vendor_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'Unknown Product',
      status: json['status'] ?? '0',
      inStock: json['in_stock'] ?? '0',
      packs: packsList,
      defaultPackId: json['default_pack_id'],
      totalStock: json['total_stock'] != null
          ? (json['total_stock'] is num
                ? (json['total_stock'] as num).toDouble()
                : double.tryParse(json['total_stock'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_vendor_id': vendorId,
      'product_id': productId,
      'product_name': productName,
      'status': status,
      'in_stock': inStock,
      'packs': packs.map((p) => p.toJson()).toList(),
      'default_pack_id': defaultPackId,
      'total_stock': totalStock,
    };
  }
}

class Pack {
  final String packId; // pi
  final String packSize; // ps
  final String packUnit; // pu
  final double stock; // stk
  final int inStock; // in_stk
  final String tax; // tx
  final String originalPrice; // op
  final String retailPrice; // rp
  final int serialNumber; // sn

  Pack({
    required this.packId,
    required this.packSize,
    required this.packUnit,
    required this.stock,
    required this.inStock,
    required this.tax,
    required this.originalPrice,
    required this.retailPrice,
    required this.serialNumber,
  });

  factory Pack.fromJson(Map<String, dynamic> json) {
    return Pack(
      packId: json['pi']?.toString() ?? '',
      packSize: json['ps']?.toString() ?? '0',
      packUnit: json['pu']?.toString() ?? '',
      stock: json['stk'] != null
          ? (json['stk'] is num
                ? (json['stk'] as num).toDouble()
                : double.tryParse(json['stk'].toString()) ?? 0.0)
          : 0.0,
      inStock: json['in_stk'] != null
          ? (json['in_stk'] is int
                ? json['in_stk']
                : int.tryParse(json['in_stk'].toString()) ?? 0)
          : 0,
      tax: json['tx']?.toString() ?? '0',
      originalPrice: json['op']?.toString() ?? '0',
      retailPrice: json['rp']?.toString() ?? '0',
      serialNumber: json['sn'] != null
          ? (json['sn'] is int
                ? json['sn']
                : int.tryParse(json['sn'].toString()) ?? 0)
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pi': packId,
      'ps': packSize,
      'pu': packUnit,
      'stk': stock,
      'in_stk': inStock,
      'tx': tax,
      'op': originalPrice,
      'rp': retailPrice,
      'sn': serialNumber,
    };
  }

  String get displayName => '$packSize $packUnit';
}
