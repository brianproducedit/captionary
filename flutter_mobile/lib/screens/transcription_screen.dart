import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_pill_button.dart';
import '../providers/transcription_provider.dart';

class TranscriptionScreen extends ConsumerStatefulWidget {
  final String videoPath;

  const TranscriptionScreen({super.key, required this.videoPath});

  @override
  ConsumerState<TranscriptionScreen> createState() =>
      _TranscriptionScreenState();
}

class _TranscriptionScreenState extends ConsumerState<TranscriptionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start transcription after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(transcriptionProvider.notifier)
          .startTranscription(widget.videoPath);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transcriptionProvider);

    // Listen for success state to navigate away
    ref.listen<TranscriptionState>(transcriptionProvider, (previous, next) {
      if (next.status == TranscriptionStatus.success) {
        context.pushReplacement(
          '/studio',
          extra: widget.videoPath,
        ); // Proceed to studio
      }
    });

    return Scaffold(
      backgroundColor: AppColors.baseCanvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.status == TranscriptionStatus.error)
                  _buildErrorState(context, state)
                else
                  _buildProcessingState(context, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingState(BuildContext context, TranscriptionState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fake pulsing waveform logo
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(
              Symbols.graphic_eq,
              size: 48,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 48),
        Text(
          state.currentAction ?? "Processing...",
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: state.status == TranscriptionStatus.extractingAudio
              ? null
              : state.progress,
          backgroundColor: AppColors.surfaceContainerHigh,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          borderRadius: BorderRadius.circular(9999),
          minHeight: 6,
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () {
            ref.read(transcriptionProvider.notifier).abortTranscription();
            context.pop(); // Go back
          },
          child: Text(
            'Cancel',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, TranscriptionState state) {
    return GlassCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.error, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            'Transcription Failed',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage ?? "An unknown error occurred.",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GradientPillButton(
            label: 'Retry',
            icon: Symbols.refresh,
            onTap: () {
              ref
                  .read(transcriptionProvider.notifier)
                  .retryTranscription(widget.videoPath);
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ref.read(transcriptionProvider.notifier).abortTranscription();
              context.pop();
            },
            child: Text(
              'Abort',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
