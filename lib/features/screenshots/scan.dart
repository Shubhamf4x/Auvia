import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/scope.dart';
import '../../services/ai_service.dart';
import '../../widgets/common.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  int _stage = 0;
  String? _imagePath;
  ScanAnalysis? _analysis;
  static const _stageTexts = [
    'Reading image...',
    'Extracting text (OCR)...',
    'Understanding content...',
    'Categorizing...',
  ];
  int _stageText = 0;

  Future<void> _startScan(ImageSource source) async {
    if (_stage == 1) return;
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(source: source);
    } catch (_) {
      picked = null;
    }
    if (!mounted) return;
    if (picked == null && source == ImageSource.gallery) return;
    final file = picked ?? XFile('demo');
    final persisted = file.path == 'demo'
        ? null
        : await AppScope.of(context).persistImage(file.path);
    if (!mounted) return;
    setState(() {
      _stage = 1;
      _imagePath = persisted;
      _stageText = 0;
    });
    _tick();
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    final analysis = await AiService.instance.analyzeImageSmart(
            _imagePath, file.name, 'camera scan', AppScope.of(context)) ??
        await AiService.instance.provider.analyzeImage(file.name,
            hint: 'camera scan');
    if (!mounted) return;
    setState(() {
      _analysis = analysis;
      _stage = 2;
    });
  }

  void _tick() async {
    while (mounted && _stage == 1) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() {
        _stageText = (_stageText + 1) % _stageTexts.length;
      });
    }
  }

  void _saveResult() {
    final state = AppScope.of(context);
    final item = LifeItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: ItemType.screenshot,
      title: _analysis!.title,
      category: _analysis!.category,
      content: _analysis!.extractedText,
      keyPoints: _analysis!.keyInfo,
      imagePath: _imagePath,
      createdAt: DateTime.now(),
    );
    state.addItem(item);
    Navigator.pop(context);
    Navigator.pushNamed(context, '/document', arguments: item.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSoft),
                        color: AppColors.surface.withOpacity(0.5),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          size: 22, color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(t(context, 'scanTitle'),
                        textAlign: TextAlign.center,
                        style: AppText.sectionHeading),
                  ),
                  const SizedBox(width: 46),
                ],
              ),
              const SizedBox(height: 24),
              if (_stage == 0) ...[
                const Spacer(),
                _scanHero(),
                const Spacer(),
                PrimaryButton(
                  label: t(context, 'scanPhotoDoc'),
                  icon: Icons.document_scanner_outlined,
                  onTap: () => _startScan(ImageSource.camera),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: t(context, 'chooseFromGallery'),
                  icon: Icons.photo_library_outlined,
                  gradient: false,
                  onTap: () => _startScan(ImageSource.gallery),
                ),
                const SizedBox(height: 12),
                Text(
                  t(context, 'chooseImageHint'),
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ] else if (_stage == 1) ...[
                const Spacer(),
                _analyzing(),
                const Spacer(),
              ] else ...[
                Expanded(
                  child: ListView(
                    children: [
                      _result(),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: t(context, 'saveToLibrary'),
                        icon: Icons.check_rounded,
                        onTap: _saveResult,
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: t(context, 'discard'),
                        icon: Icons.close_rounded,
                        gradient: false,
                        onTap: () => setState(() => _stage = 0),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _scanHero() {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: AppColors.aiGradient,
            borderRadius: BorderRadius.circular(32),
            ),
          child: const Icon(Icons.document_scanner_outlined,
              color: Colors.white, size: 46),
        ),
        const SizedBox(height: 26),
        Text('Screenshot Organizer', style: AppText.pageTitle.copyWith(fontSize: 22)),
        const SizedBox(height: 8),
        Text(
          'Point at a ticket, receipt or document.\nAI turns it into searchable information.',
          textAlign: TextAlign.center,
          style: AppText.body,
        ),
      ],
    );
  }

  Widget _analyzing() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 92,
              height: 92,
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 4,
              ),
            ),
            Icon(Icons.auto_awesome,
                color: AppColors.accentSoft, size: 34),
          ],
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Text(
            _stageTexts[_stageText],
            key: ValueKey(_stageText),
            style: AppText.bodyStrong.copyWith(color: AppColors.accentSoft),
          ),
        ),
      ],
    );
  }

  Widget _result() {
    final a = _analysis!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(_imagePath!),
                  cacheWidth: 720,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          if (_imagePath != null) const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: AppColors.accentSoft, size: 18),
              const SizedBox(width: 8),
              Text(t(context, 'aiAnalysis'), style: AppText.cardTitle),
            ],
          ),
          const SizedBox(height: 14),
          Text(a.title, style: AppText.pageTitle.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text('Category: ${a.category}', style: AppText.caption),
          const Divider(height: 28),
          Text(t(context, 'extractedText'), style: AppText.label),
          const SizedBox(height: 6),
          Text(a.extractedText, style: AppText.body),
          const SizedBox(height: 12),
          Text(t(context, 'importantInfo'), style: AppText.label),
          const SizedBox(height: 6),
          ...a.keyInfo.map(
            (k) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ',
                      style: TextStyle(color: AppColors.accentSoft)),
                  Expanded(child: Text(k, style: AppText.bodyStrong)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('Date: ${DateTime.now().day} · Today', style: AppText.caption),
        ],
      ),
    );
  }
}
