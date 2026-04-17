class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Laravel stores the toArray() result in the 'data' column
    final dataContent = json['data'] as Map<String, dynamic>? ?? {};
    final notificationType =
        dataContent['type']?.toString() ??
        json['type']?.toString() ??
        'unknown';

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: notificationType,
      title: _extractTitle(dataContent, notificationType),
      body: _extractBody(dataContent, notificationType),
      data: dataContent,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Raccourcit une référence de commande pour l'affichage.
  /// "DR-69B6124EE359B" → "#...E359B"
  static String _shortRef(String ref) {
    if (ref.isEmpty) return '';
    if (ref.length <= 8) return '#$ref';
    return '#...${ref.substring(ref.length - 5)}';
  }

  /// Extracts a human-readable title from the notification data.
  /// Handles inconsistent key names across different notification types.
  static String _extractTitle(Map<String, dynamic> data, String type) {
    // Pour les commandes, on construit TOUJOURS un titre propre
    // (les titres stockés contiennent souvent la référence hex brute)
    switch (type) {
      case 'new_order':
      case 'new_order_received':
        // Chercher le nom du client (flat ou nested)
        final customerName =
            data['customer_name']?.toString() ??
            (data['order_data'] as Map<String, dynamic>?)?['customer_name']
                ?.toString() ??
            '';
        final itemsCount =
            data['items_count']?.toString() ??
            (data['order_data'] as Map<String, dynamic>?)?['items_count']
                ?.toString() ??
            '';

        if (customerName.isNotEmpty) {
          return '🛒 Commande de $customerName';
        }
        if (itemsCount.isNotEmpty) {
          return '🛒 Nouvelle commande · $itemsCount article(s)';
        }
        return '🛒 Nouvelle commande reçue';
      case 'order_status':
        final status = data['status']?.toString() ?? '';
        return _orderStatusTitle(status);
      case 'delivery_assigned':
        final courierName =
            data['courier_name']?.toString() ??
            (data['delivery_data'] as Map<String, dynamic>?)?['courier_name']
                ?.toString() ??
            '';
        if (courierName.isNotEmpty) {
          return '🚴 Livreur assigné · $courierName';
        }
        return '🚴 Livreur assigné';
      case 'courier_arrived':
        return '📍 Livreur arrivé à la pharmacie';
      case 'courier_arrived_at_client':
        return '📍 Livreur arrivé chez le client';
      case 'courier_assigned':
        final courierName2 = data['courier_name']?.toString() ?? '';
        if (courierName2.isNotEmpty) {
          return '🛵 Livreur assigné · $courierName2';
        }
        return '🛵 Livreur assigné à la commande';
      case 'delivery_timeout_cancelled':
        return '⏰ Livraison annulée (délai dépassé)';
      case 'order_delivered':
        final customerName = data['customer_name']?.toString() ?? '';
        if (customerName.isNotEmpty) {
          return '🎉 Commande livrée à $customerName';
        }
        return '🎉 Commande livrée avec succès';
      case 'new_prescription':
        return '📋 Nouvelle ordonnance reçue';
      case 'prescription_status':
        return '📋 Mise à jour ordonnance';
      case 'low_stock':
        final productName = data['product_name']?.toString() ?? '';
        if (productName.isNotEmpty) {
          return '⚠️ Stock bas · $productName';
        }
        return '⚠️ Alerte stock bas';
      case 'payment':
      case 'payout_completed':
        final amount = data['amount']?.toString() ?? '';
        if (amount.isNotEmpty) {
          return '💰 Paiement reçu · $amount F CFA';
        }
        return '💰 Paiement reçu';
      case 'chat_message':
        final sender = data['sender_name']?.toString() ?? '';
        return sender.isNotEmpty
            ? '💬 Message de $sender'
            : '💬 Nouveau message';
      case 'kyc_status_update':
        return '🔐 Mise à jour vérification KYC';
      default:
        // Utiliser le titre de l'API en dernier recours, mais nettoyé
        final rawTitle = data['title']?.toString() ?? '';
        if (rawTitle.isNotEmpty) {
          return rawTitle;
        }
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          final msg = data['message'].toString();
          return msg.length > 50 ? '${msg.substring(0, 50)}…' : msg;
        }
        return 'Notification';
    }
  }

  /// Extracts the notification body text.
  static String _extractBody(Map<String, dynamic> data, String type) {
    // Pour les commandes, on construit TOUJOURS un corps lisible
    switch (type) {
      case 'new_order':
      case 'new_order_received':
        return _buildOrderBody(data);
      case 'order_status':
        final status = data['status']?.toString() ?? '';
        final ref = data['order_reference']?.toString() ?? '';
        final shortRef = _shortRef(ref);
        return _orderStatusBody(status, shortRef);
      case 'delivery_assigned':
        final parts = <String>[];
        final courierName =
            data['courier_name']?.toString() ??
            (data['delivery_data'] as Map<String, dynamic>?)?['courier_name']
                ?.toString();
        if (courierName != null && courierName.isNotEmpty) {
          parts.add('Livreur: $courierName');
        }
        final pickupAddr =
            (data['delivery_data'] as Map<String, dynamic>?)?['pickup_address']
                ?.toString();
        if (pickupAddr != null && pickupAddr.isNotEmpty) {
          parts.add(pickupAddr);
        }
        final ref2 = data['order_reference']?.toString() ?? '';
        if (ref2.isNotEmpty) parts.add('Réf: ${_shortRef(ref2)}');
        return parts.isNotEmpty
            ? parts.join(' · ')
            : 'Un livreur a été assigné à votre commande';
      case 'order_delivered':
        final parts = <String>[];
        final customer = data['customer_name']?.toString();
        if (customer != null && customer.isNotEmpty)
          parts.add('Client: $customer');
        final ref3 = data['order_reference']?.toString() ?? '';
        if (ref3.isNotEmpty) parts.add('Réf: ${_shortRef(ref3)}');
        return parts.isNotEmpty
            ? parts.join(' · ')
            : 'La commande a été livrée avec succès';
      case 'courier_arrived':
        final ref4 = data['order_reference']?.toString() ?? '';
        return ref4.isNotEmpty
            ? 'Le livreur est arrivé pour récupérer la commande ${_shortRef(ref4)}'
            : 'Le livreur est arrivé pour récupérer la commande';
      case 'courier_arrived_at_client':
        final ref5 = data['order_reference']?.toString() ?? '';
        return ref5.isNotEmpty
            ? 'Le livreur est arrivé chez le client ${_shortRef(ref5)}'
            : 'Le livreur est arrivé à la destination';
      case 'courier_assigned':
        final parts2 = <String>[];
        final courierName3 = data['courier_name']?.toString() ?? '';
        final courierPhone = data['courier_phone']?.toString() ?? '';
        final vehicleType = data['courier_vehicle_type']?.toString() ?? '';
        if (courierName3.isNotEmpty) parts2.add(courierName3);
        if (vehicleType.isNotEmpty)
          parts2.add(vehicleType == 'moto' ? '🏍️' : '🚗');
        if (courierPhone.isNotEmpty) parts2.add(courierPhone);
        return parts2.isNotEmpty
            ? 'Préparez la commande · ${parts2.join(' ')}'
            : 'Un livreur a été assigné. Préparez la commande pour le retrait.';
      case 'delivery_timeout_cancelled':
        final ref6 = data['order_reference']?.toString() ?? '';
        return ref6.isNotEmpty
            ? 'La commande ${_shortRef(ref6)} a été annulée car le délai a été dépassé'
            : 'La commande a été annulée car le délai de livraison a été dépassé';
      case 'payout_completed':
        final amount = data['amount']?.toString() ?? '';
        return amount.isNotEmpty
            ? 'Montant versé: $amount F CFA'
            : 'Votre décaissement a été effectué';
      case 'chat_message':
        return data['message_preview']?.toString() ??
            'Vous avez reçu un nouveau message';
      case 'new_prescription':
        final customerP = data['customer_name']?.toString() ?? '';
        return customerP.isNotEmpty
            ? 'Ordonnance reçue de $customerP'
            : 'Une nouvelle ordonnance a été soumise';
      case 'prescription_status':
        final statusP = data['status']?.toString() ?? '';
        return statusP.isNotEmpty
            ? 'Statut: $statusP'
            : 'Le statut de l\'ordonnance a été mis à jour';
      case 'low_stock':
        final productName = data['product_name']?.toString() ?? '';
        final quantity = data['quantity']?.toString() ?? '';
        if (productName.isNotEmpty && quantity.isNotEmpty) {
          return '$productName — il ne reste que $quantity unité(s)';
        }
        return 'Un produit a atteint le seuil de stock minimum';
      case 'kyc_status_update':
        final kycStatus = data['status']?.toString() ?? '';
        return switch (kycStatus) {
          'approved' => 'Votre vérification KYC a été approuvée ✅',
          'rejected' =>
            'Votre vérification KYC a été refusée. Veuillez resoumettre.',
          'pending' => 'Votre vérification KYC est en cours d\'examen',
          _ => 'Le statut de votre vérification a été mis à jour',
        };
      default:
        // Fallback: utiliser body ou message de l'API
        if (data['body'] != null && data['body'].toString().isNotEmpty) {
          return data['body'].toString();
        }
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          return data['message'].toString();
        }
        return '';
    }
  }

  /// Construit un body d'information pour les commandes
  /// en cherchant les données dans les champs flat ET nested.
  static String _buildOrderBody(Map<String, dynamic> data) {
    final nested = data['order_data'] as Map<String, dynamic>? ?? {};
    final parts = <String>[];

    // Client
    final customerName =
        data['customer_name']?.toString() ??
        nested['customer_name']?.toString();
    if (customerName != null && customerName.isNotEmpty) {
      parts.add('Client: $customerName');
    }

    // Articles
    final itemsCount =
        data['items_count']?.toString() ?? nested['items_count']?.toString();
    if (itemsCount != null && itemsCount.isNotEmpty && itemsCount != '0') {
      parts.add('$itemsCount article(s)');
    }

    // Montant
    final totalAmount =
        data['total_amount']?.toString() ?? nested['total_amount']?.toString();
    if (totalAmount != null && totalAmount.isNotEmpty) {
      final currency =
          data['currency']?.toString() ??
          nested['currency']?.toString() ??
          'FCFA';
      parts.add('$totalAmount $currency');
    }

    // Mode de paiement
    final paymentMode =
        data['payment_mode']?.toString() ?? nested['payment_mode']?.toString();
    if (paymentMode != null && paymentMode.isNotEmpty) {
      final label = switch (paymentMode) {
        'cash' => 'Espèces',
        'mobile_money' => 'Mobile Money',
        'card' => 'Carte',
        'wave' => 'Wave',
        'orange' => 'Orange Money',
        _ => paymentMode,
      };
      parts.add(label);
    }

    // Référence courte en dernier
    final ref = data['order_reference']?.toString() ?? '';
    if (ref.isNotEmpty) {
      parts.add('Réf: ${_shortRef(ref)}');
    }

    return parts.isNotEmpty ? parts.join(' · ') : 'Nouvelle commande reçue';
  }

  static String _orderStatusTitle(String status) {
    return switch (status) {
      'confirmed' => '✅ Commande confirmée',
      'preparing' => '💊 Préparation en cours',
      'ready' || 'ready_for_pickup' => '📦 Commande prête',
      'assigned' => '🚴 Livreur assigné',
      'on_the_way' || 'picked_up' => '🚀 En livraison',
      'delivered' => '🎉 Commande livrée',
      'cancelled' => '❌ Commande annulée',
      _ => '📱 Mise à jour commande',
    };
  }

  static String _orderStatusBody(String status, String shortRef) {
    final refStr = shortRef.isNotEmpty ? ' $shortRef' : '';
    return switch (status) {
      'confirmed' => 'La commande$refStr a été confirmée par la pharmacie.',
      'preparing' => 'La commande$refStr est en cours de préparation.',
      'ready' ||
      'ready_for_pickup' => 'La commande$refStr est prête pour le ramassage.',
      'assigned' => 'Un livreur a été assigné à la commande$refStr.',
      'on_the_way' ||
      'picked_up' => 'La commande$refStr est en cours de livraison.',
      'delivered' => 'La commande$refStr a été livrée avec succès. 🎉',
      'cancelled' => 'La commande$refStr a été annulée.',
      _ => 'Mise à jour de la commande$refStr.',
    };
  }

  bool get isRead => readAt != null;
}
