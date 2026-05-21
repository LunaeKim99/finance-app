import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../blocs/usage/usage_bloc.dart';
import '../../blocs/usage/usage_event.dart';
import '../../blocs/usage/usage_state.dart';
import '../transaction/bloc/transaction_bloc.dart';
import '../transaction/bloc/transaction_event.dart';
import '../upgrade/upgrade_screen.dart';
import 'bloc/ai_chat_bloc.dart';
import 'bloc/ai_chat_event.dart';
import 'bloc/ai_chat_state.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<AiChatBloc>();
    bloc.onVoiceStart = () {
      if (mounted) setState(() => _isListening = true);
    };
    bloc.onVoiceStop = () {
      if (mounted) setState(() => _isListening = false);
    };
    bloc.onConfirmTransactionExternal = (transaction) async {
      if (!mounted) return false;
      context.read<TransactionBloc>().add(TransactionAddRequested(transaction: transaction));
      context.read<UsageBloc>().add(const UsageIncrementAiText());
      return true;
    };
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTextMessage(String text) {
    if (text.trim().isEmpty) return;

    final usageState = context.read<UsageBloc>().state;
    if (usageState is UsageLoaded && !usageState.canUseAiText()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Batas harian tercapai (10/10).'),
          action: SnackBarAction(
            label: 'Upgrade',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
            },
          ),
        ),
      );
      return;
    }
    _textController.clear();
    context.read<AiChatBloc>().add(AiChatSendMessage(message: text));
    context.read<UsageBloc>().add(const UsageIncrementAiText());
  }

  Future<void> _startVoiceInput() async {
    context.read<AiChatBloc>().add(const AiChatStartVoice());
  }

  Future<void> _stopVoiceInput() async {
    context.read<AiChatBloc>().add(const AiChatStopVoice());
  }

  Future<void> _scanImage() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    context.read<AiChatBloc>().add(AiChatScanImage(source: source));
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final usageState = context.watch<UsageBloc>().state;
    final isPremium = usageState is UsageLoaded && usageState.isPremium;

    return BlocConsumer<AiChatBloc, AiChatState>(
      listener: (context, state) {
        _scrollToBottom();
      },
      builder: (context, state) {
        final messages = state is AiChatMessageAdded
            ? state.messages
            : state is AiChatLoading
                ? state.messages
                : state is AiChatError
                    ? state.messages
                    : <ChatMessage>[];

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(isPremium, usageState),
                Expanded(
                  child: messages.isEmpty
                      ? _buildIntroCard()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(messages[index], index, currencyFormat, dateFormat);
                          },
                        ),
                ),
                _buildInputBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isPremium, UsageState usageState) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHighest, width: 0.5)),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: AppRadius.mdRadius),
              child: const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.onPrimaryContainer),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asisten Keuangan', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                if (isPremium)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: AppRadius.smRadius),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, size: 10, color: AppColors.onPrimaryContainer),
                        const SizedBox(width: 2),
                        Text('Premium', style: AppTypography.labelMono.copyWith(fontSize: 9, color: AppColors.onPrimaryContainer)),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            if (!isPremium && usageState is UsageLoaded)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: AppRadius.fullRadius),
                child: Text('${usageState.remainingAiText}/10', style: AppTypography.labelMono.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.onSurfaceVariant),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppRadius.xlRadius,
            border: Border.all(color: AppColors.surfaceContainerHighest),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('👋', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text('Halo! Saya asisten keuanganmu.', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                ],
              ),
              const SizedBox(height: 12),
              Text('Kamu bisa mencatat dengan cara:', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 16),
              _modeItem(Icons.keyboard_rounded, 'Ketik', 'Misal: "makan siang 35rb"', AppColors.primary),
              const SizedBox(height: 14),
              _modeItem(Icons.mic_rounded, 'Tahan mic', 'Ucapkan transaksimu langsung', AppColors.primary),
              const SizedBox(height: 14),
              _modeItem(Icons.document_scanner_rounded, 'Tap scan', 'Foto struk atau nota belanja', AppColors.secondary),
              const SizedBox(height: 16),
              Text('Mau catat transaksi apa hari ini?', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 4),
          child: Text('Hari ini, ${DateFormat('HH:mm', 'id_ID').format(DateTime.now())}',
            style: AppTypography.labelMono.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
        ),
      ],
    );
  }

  Widget _modeItem(IconData icon, String title, String subtitle, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppRadius.mdRadius, border: Border.all(color: color.withValues(alpha: 0.2))),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurface)),
            const SizedBox(height: 1),
            Text(subtitle, style: AppTypography.bodySm.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index, NumberFormat currencyFormat, DateFormat dateFormat) {
    if (message.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppRadius.lgRadius,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Mengetik...'),
            ],
          ),
        ),
      );
    }

    if (message.isRetryButton) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: AppRadius.lgRadius),
                child: Text(message.text, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface)),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => context.read<AiChatBloc>().add(const AiChatRetry()),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Hubungkan Ulang'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
              ),
            ],
          ),
        ),
      );
    }

    if (message.pendingTransaction != null) {
      final transaction = message.pendingTransaction!;
      final isIncome = transaction.type == TransactionType.income;
      final txColor = isIncome ? AppColors.primary : AppColors.secondary;

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: txColor.withValues(alpha: 0.06),
                  borderRadius: AppRadius.xlRadius,
                  border: Border.all(color: txColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: txColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: txColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transaction.category,
                          style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                        const SizedBox(height: 2),
                        Text(
                          transaction.currency != 'IDR'
                              ? '${AppCurrencies.symbolFor(transaction.currency)} ${NumberFormat('#,###', 'id_ID').format(transaction.amount.ceil())} (${currencyFormat.format(transaction.amountInIdr)})'
                              : currencyFormat.format(transaction.amount),
                          style: TextStyle(color: txColor, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(dateFormat.format(transaction.date),
                          style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              if (message.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: AppRadius.mdRadius),
                  child: Text(message.text, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.read<AiChatBloc>().add(AiChatCancelTransaction(messageIndex: index)),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Batal'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.read<AiChatBloc>().add(AiChatConfirmTransaction(transaction: transaction, messageIndex: index)),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppColors.primary
              : AppColors.surfaceContainerLowest,
          borderRadius: message.isUser
              ? const BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))
              : const BorderRadius.only(
                  topLeft: Radius.circular(4), topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.imageFile != null) ...[
              ClipRRect(
                borderRadius: AppRadius.mdRadius,
                child: Image.file(message.imageFile!, height: 150, width: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],
            Text(message.text, style: AppTypography.bodyMd.copyWith(color: message.isUser ? AppColors.onPrimary : AppColors.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceContainerHighest, width: 0.5)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _scanImage,
            borderRadius: AppRadius.fullRadius,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: AppRadius.xlRadius, border: Border.all(color: AppColors.surfaceContainerHighest)),
              child: const Icon(Icons.document_scanner_rounded, color: AppColors.onSurfaceVariant, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppRadius.xlRadius,
                border: Border.all(color: AppColors.surfaceContainerHighest),
              ),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: _isListening ? 'Mendengarkan...' : 'Ceritakan transaksimu...',
                  hintStyle: TextStyle(color: _isListening ? AppColors.error : AppColors.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  isDense: true,
                ),
                onSubmitted: (text) {
                  if (text.isNotEmpty) _sendTextMessage(text);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onLongPressStart: (_) => _startVoiceInput(),
            onLongPressEnd: (_) => _stopVoiceInput(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _isListening ? AppColors.secondary : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: (_isListening ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: AppColors.onPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
