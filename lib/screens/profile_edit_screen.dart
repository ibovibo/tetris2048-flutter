import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../avatar_manager.dart';
import '../l10n.dart';
import '../profile_manager.dart';
import '../stats_manager.dart';
import '../widgets/avatar_display.dart';
import 'avatar_select_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  String _userName = 'Guest';
  String _selectedCountry = '🇹🇷 Türkiye';
  bool _isEditingName = false;
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  int _bestBlock = 0;
  int _highestScore = 0;
  int _totalMerges = 0;
  int _gamesPlayed = 0;

  static const _countries = [
    '🇦🇫 افغانستان',
    '🇦🇱 Shqipëri',
    '🇩🇿 الجزائر',
    '🇦🇩 Andorra',
    '🇦🇴 Angola',
    '🇦🇬 Antigua & Barbuda',
    '🇦🇷 Argentina',
    '🇦🇲 Հայաստան',
    '🇦🇺 Australia',
    '🇦🇹 Österreich',
    '🇦🇿 Azərbaycan',
    '🇧🇸 Bahamas',
    '🇧🇭 البحرين',
    '🇧🇩 বাংলাদেশ',
    '🇧🇧 Barbados',
    '🇧🇾 Беларусь',
    '🇧🇪 België',
    '🇧🇿 Belize',
    '🇧🇯 Bénin',
    '🇧🇹 འབྲུག',
    '🇧🇴 Bolivia',
    '🇧🇦 Bosna i Hercegovina',
    '🇧🇼 Botswana',
    '🇧🇷 Brasil',
    '🇧🇳 Brunei',
    '🇧🇬 България',
    '🇧🇫 Burkina Faso',
    '🇧🇮 Burundi',
    '🇨🇻 Cabo Verde',
    '🇰🇭 កម្ពុជា',
    '🇨🇲 Cameroun',
    '🇨🇦 Canada',
    '🇨🇫 Centrafrique',
    '🇹🇩 Tchad',
    '🇨🇱 Chile',
    '🇨🇳 中国',
    '🇨🇴 Colombia',
    '🇰🇲 Comores',
    '🇨🇬 Congo',
    '🇨🇩 Congo (RDC)',
    '🇨🇷 Costa Rica',
    '🇭🇷 Hrvatska',
    '🇨🇺 Cuba',
    '🇨🇾 Κύπρος',
    '🇨🇿 Česko',
    '🇩🇰 Danmark',
    '🇩🇯 Djibouti',
    '🇩🇴 Rep. Dominicana',
    '🇪🇨 Ecuador',
    '🇪🇬 مصر',
    '🇸🇻 El Salvador',
    '🇬🇶 Guinea Ecuatorial',
    '🇪🇷 ኤርትራ',
    '🇪🇪 Eesti',
    '🇸🇿 eSwatini',
    '🇪🇹 ኢትዮጵያ',
    '🇫🇯 Fiji',
    '🇫🇮 Suomi',
    '🇫🇷 France',
    '🇬🇦 Gabon',
    '🇬🇲 Gambia',
    '🇬🇪 საქართველო',
    '🇩🇪 Deutschland',
    '🇬🇭 Ghana',
    '🇬🇷 Ελλάδα',
    '🇬🇩 Grenada',
    '🇬🇹 Guatemala',
    '🇬🇳 Guinée',
    '🇬🇼 Guiné-Bissau',
    '🇬🇾 Guyana',
    '🇭🇹 Haïti',
    '🇭🇳 Honduras',
    '🇭🇺 Magyarország',
    '🇮🇸 Ísland',
    '🇮🇳 भारत',
    '🇮🇩 Indonesia',
    '🇮🇷 ایران',
    '🇮🇶 العراق',
    '🇮🇪 Éire',
    '🇮🇱 ישראל',
    '🇮🇹 Italia',
    '🇯🇲 Jamaica',
    '🇯🇵 日本',
    '🇯🇴 الأردن',
    '🇰🇿 Қазақстан',
    '🇰🇪 Kenya',
    '🇰🇮 Kiribati',
    '🇽🇰 Kosovë',
    '🇰🇼 الكويت',
    '🇰🇬 Кыргызстан',
    '🇱🇦 ລາວ',
    '🇱🇻 Latvija',
    '🇱🇧 لبنان',
    '🇱🇸 Lesotho',
    '🇱🇷 Liberia',
    '🇱🇾 ليبيا',
    '🇱🇮 Liechtenstein',
    '🇱🇹 Lietuva',
    '🇱🇺 Lëtzebuerg',
    '🇲🇬 Madagasikara',
    '🇲🇼 Malawi',
    '🇲🇾 Malaysia',
    '🇲🇻 ދިވެހިރާއްޖެ',
    '🇲🇱 Mali',
    '🇲🇹 Malta',
    '🇲🇭 Marshall Islands',
    '🇲🇷 موريتانيا',
    '🇲🇺 Maurice',
    '🇲🇽 México',
    '🇫🇲 Micronesia',
    '🇲🇩 Moldova',
    '🇲🇨 Monaco',
    '🇲🇳 Монгол Улс',
    '🇲🇪 Crna Gora',
    '🇲🇦 المغرب',
    '🇲🇿 Moçambique',
    '🇲🇲 မြန်မာ',
    '🇳🇦 Namibia',
    '🇳🇷 Nauru',
    '🇳🇵 नेपाल',
    '🇳🇱 Nederland',
    '🇳🇿 Aotearoa',
    '🇳🇮 Nicaragua',
    '🇳🇪 Niger',
    '🇳🇬 Nigeria',
    '🇰🇵 조선',
    '🇲🇰 Сев. Македонија',
    '🇳🇴 Norge',
    '🇴🇲 عُمان',
    '🇵🇰 پاکستان',
    '🇵🇼 Palau',
    '🇵🇸 فلسطين',
    '🇵🇦 Panamá',
    '🇵🇬 Papua New Guinea',
    '🇵🇾 Paraguay',
    '🇵🇪 Perú',
    '🇵🇭 Pilipinas',
    '🇵🇱 Polska',
    '🇵🇹 Portugal',
    '🇶🇦 قطر',
    '🇷🇴 România',
    '🇷🇺 Россия',
    '🇷🇼 Rwanda',
    '🇰🇳 Saint Kitts & Nevis',
    '🇱🇨 Saint Lucia',
    '🇻🇨 Saint Vincent',
    '🇼🇸 Sāmoa',
    '🇸🇲 San Marino',
    '🇸🇹 São Tomé e Príncipe',
    '🇸🇦 السعودية',
    '🇸🇳 Sénégal',
    '🇷🇸 Srbija',
    '🇸🇨 Seychelles',
    '🇸🇱 Sierra Leone',
    '🇸🇬 Singapura',
    '🇸🇰 Slovensko',
    '🇸🇮 Slovenija',
    '🇸🇧 Solomon Islands',
    '🇸🇴 Soomaaliya',
    '🇿🇦 South Africa',
    '🇸🇸 South Sudan',
    '🇰🇷 한국',
    '🇪🇸 España',
    '🇱🇰 ශ්‍රී ලංකා',
    '🇸🇩 السودان',
    '🇸🇷 Suriname',
    '🇸🇪 Sverige',
    '🇨🇭 Schweiz',
    '🇸🇾 سوريا',
    '🇹🇼 臺灣',
    '🇹🇯 Тоҷикистон',
    '🇹🇿 Tanzania',
    '🇹🇭 ไทย',
    '🇹🇱 Timor-Leste',
    '🇹🇬 Togo',
    '🇹🇴 Tonga',
    '🇹🇹 Trinidad & Tobago',
    '🇹🇳 تونس',
    '🇹🇷 Türkiye',
    '🇹🇲 Türkmenistan',
    '🇹🇻 Tuvalu',
    '🇺🇬 Uganda',
    '🇺🇦 Україна',
    '🇦🇪 الإمارات',
    '🇬🇧 United Kingdom',
    '🇺🇸 United States',
    '🇺🇾 Uruguay',
    '🇺🇿 Oʻzbekiston',
    '🇻🇺 Vanuatu',
    '🇻🇦 Città del Vaticano',
    '🇻🇪 Venezuela',
    '🇻🇳 Việt Nam',
    '🇾🇪 اليمن',
    '🇿🇲 Zambia',
    '🇿🇼 Zimbabwe',
  ];

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(_onFocusChange);
    _loadData();
  }

  void _onFocusChange() {
    if (!_nameFocusNode.hasFocus && _isEditingName) {
      _finishEditing();
    }
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onFocusChange);
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    await StatsManager.load();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Guest';
      _selectedCountry = prefs.getString('user_country') ?? '🇹🇷 Türkiye';
      _bestBlock = StatsManager.bestBlock;
      _highestScore = StatsManager.highestScore;
      _totalMerges = StatsManager.totalMerges;
      _gamesPlayed = StatsManager.gamesPlayed;
      _nameController.text = _userName;
    });
  }

  void _startEditing() {
    _nameController.text = _userName;
    setState(() => _isEditingName = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  void _finishEditing() {
    final text = _nameController.text.trim();
    setState(() {
      if (text.isNotEmpty) _userName = text;
      _isEditingName = false;
    });
  }

  Future<void> _showAvatarPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: Color(0xFF1E3A8A)),
              title: Text('Galeriden Seç',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: Color(0xFF1E3A8A)),
              title: Text('Fotoğraf Çek',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickImage(ImageSource.camera);
              },
            ),
            if (AvatarManager.hasCustomAvatar)
              ListTile(
                leading:
                    const Icon(Icons.person_rounded, color: Color(0xFF94A3B8)),
                title: Text('Varsayılana Dön',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8))),
                onTap: () async {
                  Navigator.pop(ctx);
                  await AvatarManager.resetToDefault();
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final savedPath = '${appDir.path}/avatar.png';
    await File(image.path).copy(savedPath);
    await AvatarManager.setAvatar(savedPath);
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (_isEditingName) _finishEditing();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userName);
    await prefs.setString('user_country', _selectedCountry);
    ProfileManager.userName = _userName;
    if (mounted) Navigator.pop(context);
  }

  String _compact(double d) =>
      d == d.truncateToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);

  String _formatBlock(int value) {
    if (value == 0) return '0';
    if (value >= 1000000000) return '${_compact(value / 1000000000)}B';
    if (value >= 1000000) return '${_compact(value / 1000000)}M';
    if (value >= 1000) return '${_compact(value / 1000)}K';
    return value.toString();
  }

  String _formatNumber(int value) {
    final str = value.toString();
    final buf = StringBuffer();
    final len = str.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  void _showCountryPicker() {
    final sorted = [
      if (_selectedCountry != null) _selectedCountry!,
      ..._countries.where((c) => c != _selectedCountry),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListView.builder(
        itemCount: sorted.length,
        itemBuilder: (_, i) {
          final country = sorted[i];
          final isSelected = country == _selectedCountry;
          return ListTile(
            title: Text(
              country,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isSelected
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF16A34A))
                : null,
            onTap: () {
              setState(() => _selectedCountry = country);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  TextStyle _ts(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = const Color(0xFF1E3A8A),
  }) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color);

  // Her 5 karakteri aşan rakam için font boyutunu %5 küçült
  double _scaledStatFontSize(String text, double base) {
    final extra = (text.length - 5).clamp(0, 20);
    return base * pow(0.95, extra);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return GestureDetector(
            behavior: _isEditingName
                ? HitTestBehavior.opaque
                : HitTestBehavior.deferToChild,
            onTap: _isEditingName ? () => _nameFocusNode.unfocus() : null,
            child: Stack(
              children: [
                // ── Background image ──────────────────────────────────────
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/profil_ekran.png',
                    fit: BoxFit.fill,
                  ),
                ),


                // ── Avatar overlay (asset'teki dairenin üstüne) ──────────
                Positioned(
                  left: w * 0.325,
                  top: h * 0.092,
                  width: w * 0.35,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AvatarSelectScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    child: Stack(
                      children: [
                        if (AvatarManager.avatarPath != null)
                          ClipOval(
                            child: Image.file(
                              File(AvatarManager.avatarPath!),
                              width: w * 0.35,
                              height: w * 0.35,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Image.asset(
                            AvatarManager.avatarIndex != null
                                ? 'assets/ui/avatars/pp${AvatarManager.avatarIndex}.png'
                                : 'assets/images/anonpp.png',
                            width: w * 0.35,
                          ),
                        // Kamera ikonu — sağ alt köşe
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: w * 0.11,
                            height: w * 0.11,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF59E0B),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: w * 0.065),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Title "EDIT PROFILE" (center x, y≈4.8%) ──────────────
                Positioned(
                  left: 0,
                  right: 0,
                  top: h * 0.032,
                  child: Text(
                    L10n.t('edit_profile'),
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    style: _ts(h * 0.030, weight: FontWeight.w800),
                  ),
                ),

                // ── User name below avatar (center, y≈31%) ────────────────
                Positioned(
                  left: w * 0.10,
                  right: w * 0.10,
                  top: h * 0.294,
                  child: Text(
                    _userName,
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ts(h * 0.030, weight: FontWeight.w800),
                  ),
                ),

                // ── Level badge (center, y≈35.3%) ────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  top: h * 0.338,
                  child: Text(
                    '${L10n.t('level')} ${ProfileManager.level}',
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    style: _ts(
                      h * 0.020,
                      weight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),

                // ── ACCOUNT INFO header (x≈23.4%, y≈41.9%) ───────────────
                Positioned(
                  left: w * 0.08,
                  top: h * 0.405,
                  child: Text(
                    L10n.t('account_info'),
                    textScaler: TextScaler.noScaling,
                    style: _ts(h * 0.018),
                  ),
                ),

                // ── Display Name label (x≈28.2%, y≈47.2%) ────────────────
                Positioned(
                  left: w * 0.26,
                  top: h * 0.446,
                  child: Text(
                    L10n.t('display_name'),
                    textScaler: TextScaler.noScaling,
                    style: _ts(h * 0.018),
                  ),
                ),

                // ── Display Name input (x 50%–82%, y≈47.2%) ──────────────
                Positioned(
                  left: w * 0.50,
                  right: w * 0.175,
                  top: h * 0.436,
                  height: h * 0.052,
                  child: _isEditingName
                      ? TextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          style: _ts(h * 0.022, weight: FontWeight.w600),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 4),
                          ),
                          onSubmitted: (_) => _finishEditing(),
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _startEditing,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _userName,
                              textScaler: TextScaler.noScaling,
                              style:
                                  _ts(h * 0.022, weight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                ),

                // ── Edit / Confirm icon (x≈87%, y≈47.2%) ─────────────────
                Positioned(
                  right: w * 0.12,
                  top: h * 0.436,
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _isEditingName ? _finishEditing : _startEditing,
                    child: Center(
                      child: Icon(
                        _isEditingName
                            ? Icons.check_rounded
                            : Icons.edit_rounded,
                        color: const Color(0xFF1E3A8A),
                        size: h * 0.028,
                      ),
                    ),
                  ),
                ),

                // ── Country label (x≈25%, y≈55%) ─────────────────────────
                Positioned(
                  left: w * 0.26,
                  top: h * 0.533,
                  child: Text(
                    L10n.t('country'),
                    textScaler: TextScaler.noScaling,
                    style: _ts(h * 0.018),
                  ),
                ),

                // ── Country value + dropdown trigger (x 50%–86.6%) ────────
                Positioned(
                  left: w * 0.50,
                  right: w * 0.10,
                  top: h * 0.518,
                  height: h * 0.056,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showCountryPicker,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedCountry,
                        textScaler: TextScaler.noScaling,
                        style: _ts(h * 0.022, weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),

                // ── STATISTICS header (x≈22.3%, y≈63.3%) ─────────────────
                Positioned(
                  left: w * 0.08,
                  top: h * 0.617,
                  child: Text(
                    L10n.t('statistics'),
                    textScaler: TextScaler.noScaling,
                    style: _ts(h * 0.015),
                  ),
                ),

                // ── EN İYİ BLOK yazısı ───────────────────────────────────
                Positioned(
                  left: w * 0.24,
                  width: w * 0.20,
                  top: h * 0.650,
                  child: Text(
                    L10n.t('best_block'),
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: GoogleFonts.poppins(
                      fontSize: h * 0.013,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),

                // ── EN İYİ BLOK sayacı (biraz sağa) ─────────────────────
                Positioned(
                  left: w * 0.15,
                  width: w * 0.38,
                  top: h * 0.691,
                  child: Text(
                    _formatBlock(_bestBlock),
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: _scaledStatFontSize(_formatBlock(_bestBlock), h * 0.030),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),

                // ── EN YÜKSEK SKOR yazısı ─────────────────────────────────
                Positioned(
                  left: w * 0.68,
                  width: w * 0.20,
                  top: h * 0.650,
                  child: Text(
                    L10n.t('highest_score'),
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: GoogleFonts.poppins(
                      fontSize: h * 0.013,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),

                // ── EN YÜKSEK SKOR sayacı ────────────────────────────────
                Positioned(
                  left: w * 0.58,
                  right: w * 0.02,
                  top: h * 0.691,
                  child: Text(
                    _formatNumber(_highestScore),
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: _scaledStatFontSize(_formatNumber(_highestScore), h * 0.030),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),

                // ── TOPLAM BİRLEŞTİRME yazısı ────────────────────────────
                Positioned(
                  left: w * 0.24,
                  width: w * 0.20,
                  top: h * 0.775,
                  child: Text(
                    L10n.t('total_merges'),
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: GoogleFonts.poppins(
                      fontSize: h * 0.013,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),

                // ── TOPLAM BİRLEŞTİRME sayacı (sağ alta) ────────────────
                Positioned(
                  left: w * 0.15,
                  width: w * 0.38,
                  top: h * 0.815,
                  child: Text(
                    _formatNumber(_totalMerges),
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: _scaledStatFontSize(_formatNumber(_totalMerges), h * 0.030),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),

                // ── OYNANAN OYUN yazısı (çok az aşağı) ───────────────────
                Positioned(
                  left: w * 0.68,
                  width: w * 0.20,
                  top: h * 0.779,
                  child: Text(
                    L10n.t('games_played'),
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: GoogleFonts.poppins(
                      fontSize: h * 0.013,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),

                // ── OYNANAN OYUN sayacı (sağ alta) ───────────────────────
                Positioned(
                  left: w * 0.58,
                  right: w * 0.02,
                  top: h * 0.818,
                  child: Text(
                    _formatNumber(_gamesPlayed),
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: _scaledStatFontSize(_formatNumber(_gamesPlayed), h * 0.030),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),

                // ── Back button hit area ──────────────────────────────────
                Positioned(
                  left: 0,
                  top: h * 0.005,
                  width: w * 0.18,
                  height: h * 0.09,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                  ),
                ),

                // ── SAVE button (center x=50%, y≈94.2%) ──────────────────
                Positioned(
                  left: w * 0.20,
                  right: w * 0.20,
                  top: h * 0.922,
                  height: h * 0.055,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _save,
                    child: Center(
                      child: Text(
                        L10n.t('save'),
                        textScaler: TextScaler.noScaling,
                        style: _ts(
                          h * 0.028,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

