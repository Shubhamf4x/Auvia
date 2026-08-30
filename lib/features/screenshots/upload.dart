import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/scope.dart';
import '../../services/ai_service.dart';
import '../../widgets/common.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  int _stage = 0; // 0 choose, 1 analyzing, 2 result
  String? _imagePath;
  ScanAnalysis? _analysis;
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    final picker = ImagePicker();
    XFile? x;
    try {
      x = await picker.pickImage(source: ImageSource.gallery);
    } catch (_) {
      x = null;
    }
    if (!mounted) return;
    if (x == null) {
      setState(() => _busy = false);
      return;
    }
    final persisted = await AppScope.of(context).persistImage(x.path);
    setState(() {
      _stage = 1;
      _imagePath = persisted;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final analysis = await AiService.instance.analyzeImageSmart(
            x.path, x.name, 'gallery upload', AppScope.of(context)) ??
        await AiService.instance.provider.analyzeImage(x.name,
            hint: 'gallery upload');
    if (!mounted) return;
    setState(() {
      _analysis = analysis;
      _stage = 2;
      _busy = false;
    });
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
                    child: Text(t(context, 'uploadT'),
                        textAlign: TextAlign.center,
                        style: AppText.sectionHeading),
                  ),
                  const SizedBox(width: 46),
                ],
              ),
              const SizedBox(height: 24),
              if (_stage == 0) ...[
                const Spacer(),
                _chooseHero(),
                const Spacer(),
                PrimaryButton(
                  label: t(context, 'chooseFromGallery'),
                  icon: Icons.photo_library_outlined,
                  onTap: _pick,
                ),
                const SizedBox(height: 12),
                Text(
                  'Import a screenshot, receipt or document. AI will analyze it and file it into your library.',
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
                        label: t(context, 'chooseAnother'),
                        icon: Icons.refresh_rounded,
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

  Widget _chooseHero() {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: AppColors.aiGradient,
            borderRadius: BorderRadius.circular(32),
            ),
          child: const Icon(Icons.upload_file_outlined,
              color: Colors.white, size: 46),
        ),
        const SizedBox(height: 26),
        Text(t(context, 'importToLibrary'),
            style: AppText.pageTitle.copyWith(fontSize: 22)),
        const SizedBox(height: 8),
        Text(
          'Bring in images from your gallery.\nAI reads, titles and categorizes them.',
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
        Text('Analyzing with ${AiService.instance.providerName}...',
            style: AppText.bodyStrong.copyWith(color: AppColors.accentSoft)),
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
        ],
      ),
    );
  }
}
