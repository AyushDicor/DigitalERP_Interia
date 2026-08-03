// Models for the Tap Card module (ported from the standalone TapCard app).
// The mobile API returns camelCase keys inside the standard
// {success,data,message,status} envelope.

int _i(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
String _s(dynamic v) => v == null ? '' : '$v';
String? _sn(dynamic v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}

/// Card categories. Kept as plain strings (not an enum) because the column is
/// nvarchar and the API echoes whatever it was given.
class TapCardCategory {
  static const business = 'Business';
  static const personal = 'Personal';
  static const other = 'Other';
  static const all = <String>[business, personal, other];
  static const defaultCategory = business;
}

class TapCardModel {
  /// Server CardId, or 0 for a card saved offline that hasn't synced yet
  /// (those are identified by [localId] instead).
  final int id;

  /// Set only on offline-first rows: a client-generated key that survives app
  /// restarts, so a queued card can be matched to its server row after syncing.
  final String? localId;

  final String name;
  final String? phone;
  final String? email;
  final String? company;
  final String? title;
  final String? website;

  /// Front / back photos of the physical card. Either a full http URL (already
  /// uploaded) or a local file path (queued for upload).
  final String? imageUrl;
  final String? backImageUrl;

  final String? category;
  final DateTime? createdAt;

  /// True while the card exists only on this device. Never sent by the server.
  final bool pendingSync;

  const TapCardModel({
    this.id = 0,
    this.localId,
    this.name = '',
    this.phone,
    this.email,
    this.company,
    this.title,
    this.website,
    this.imageUrl,
    this.backImageUrl,
    this.category,
    this.createdAt,
    this.pendingSync = false,
  });

  TapCardModel copyWith({
    int? id,
    String? localId,
    String? name,
    String? phone,
    String? email,
    String? company,
    String? title,
    String? website,
    String? imageUrl,
    String? backImageUrl,
    String? category,
    DateTime? createdAt,
    bool? pendingSync,
  }) => TapCardModel(
    id: id ?? this.id,
    localId: localId ?? this.localId,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    company: company ?? this.company,
    title: title ?? this.title,
    website: website ?? this.website,
    imageUrl: imageUrl ?? this.imageUrl,
    backImageUrl: backImageUrl ?? this.backImageUrl,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    pendingSync: pendingSync ?? this.pendingSync,
  );

  factory TapCardModel.fromJson(Map<String, dynamic> j) => TapCardModel(
    id: _i(j['id'] ?? j['cardId']),
    localId: _sn(j['localId']),
    name: _s(j['name']),
    phone: _sn(j['phone']),
    email: _sn(j['email']),
    company: _sn(j['company']),
    title: _sn(j['title']),
    website: _sn(j['website']),
    imageUrl: _sn(j['imageUrl']),
    backImageUrl: _sn(j['backImageUrl']),
    category: _sn(j['category']),
    createdAt: j['createdAt'] == null
        ? null
        : DateTime.tryParse(j['createdAt'].toString()),
    pendingSync: j['pendingSync'] == true,
  );

  /// Used only for the local cache / sync queue — the API is posted
  /// form-encoded via [toFormBody], not with this JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    if (localId != null) 'localId': localId,
    'name': name,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (company != null) 'company': company,
    if (title != null) 'title': title,
    if (website != null) 'website': website,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (backImageUrl != null) 'backImageUrl': backImageUrl,
    if (category != null) 'category': category,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    'pendingSync': pendingSync,
  };

  /// The body for POST /api/tapcard/save. Every field is sent on every save —
  /// the API overwrites the row wholesale, so omitting one would blank it.
  Map<String, String> toFormBody({
    required String compid,
    required String branchid,
    required String userid,
  }) => {
    'compid': compid,
    'branchid': branchid,
    'userid': userid,
    if (id > 0) 'id': id.toString(),
    'name': name,
    'phone': phone ?? '',
    'email': email ?? '',
    'company': company ?? '',
    'title': title ?? '',
    'website': website ?? '',
    'imageurl': imageUrl ?? '',
    'backimageurl': backImageUrl ?? '',
    'category': category ?? TapCardCategory.defaultCategory,
  };

  /// Stable key for de-duping the local cache: server id when synced, else the
  /// client-generated local id.
  String get key => id > 0 ? 'srv_$id' : (localId ?? 'tmp_${name}_$phone');

  /// First alphanumeric character, for the avatar — handles names like
  /// "(ekansh)" which would otherwise show "(".
  String get initial {
    for (final ch in name.trim().split('')) {
      if (RegExp(r'[a-zA-Z0-9]').hasMatch(ch)) return ch.toUpperCase();
    }
    return '?';
  }

  /// A vCard 3.0 payload — what the QR code encodes and what a phone camera
  /// will offer to save straight into contacts.
  String toVCard() {
    final b = StringBuffer()
      ..writeln('BEGIN:VCARD')
      ..writeln('VERSION:3.0')
      ..writeln('FN:$name');
    if ((phone ?? '').isNotEmpty) b.writeln('TEL;TYPE=CELL:$phone');
    if ((email ?? '').isNotEmpty) b.writeln('EMAIL:$email');
    if ((company ?? '').isNotEmpty) b.writeln('ORG:$company');
    if ((title ?? '').isNotEmpty) b.writeln('TITLE:$title');
    if ((website ?? '').isNotEmpty) b.writeln('URL:$website');
    b.writeln('END:VCARD');
    return b.toString();
  }

  /// Plain-text version for the share sheet (WhatsApp etc.).
  String toShareText() {
    final lines = <String>[name];
    if ((title ?? '').isNotEmpty) lines.add(title!);
    if ((company ?? '').isNotEmpty) lines.add(company!);
    if ((phone ?? '').isNotEmpty) lines.add('Phone: $phone');
    if ((email ?? '').isNotEmpty) lines.add('Email: $email');
    if ((website ?? '').isNotEmpty) lines.add('Web: $website');
    return lines.join('\n');
  }
}

class TapCardListResponse {
  final int status;
  final String message;
  final List<TapCardModel> data;
  TapCardListResponse({
    this.status = 0,
    this.message = '',
    this.data = const [],
  });

  factory TapCardListResponse.fromJson(Map<String, dynamic> j) =>
      TapCardListResponse(
        status: _i(j['status']),
        message: _s(j['message']),
        data:
            (j['data'] as List?)
                ?.map((e) => TapCardModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class TapCardSaveResponse {
  final int status;
  final String message;
  final TapCardModel? data;
  TapCardSaveResponse({this.status = 0, this.message = '', this.data});

  factory TapCardSaveResponse.fromJson(Map<String, dynamic> j) =>
      TapCardSaveResponse(
        status: _i(j['status']),
        message: _s(j['message']),
        data: j['data'] is Map<String, dynamic>
            ? TapCardModel.fromJson(j['data'] as Map<String, dynamic>)
            : null,
      );
}

/// What the OCR scan hands to the create form. Mirrors TapCard's
/// ScannedCardData: every field is a guess the user then corrects.
class ScannedCardData {
  final String? name;
  final String? phone;
  final String? email;
  final String? company;
  final String? title;
  final String? website;
  final String? imageUrl; // local file path of the front photo
  final String? backImageUrl; // local file path of the back photo

  const ScannedCardData({
    this.name,
    this.phone,
    this.email,
    this.company,
    this.title,
    this.website,
    this.imageUrl,
    this.backImageUrl,
  });
}
