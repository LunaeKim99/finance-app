import 'package:equatable/equatable.dart';
import '../../../../data/models/transaction_model.dart';

abstract class AiChatEvent extends Equatable {
  const AiChatEvent();

  @override
  List<Object?> get props => [];
}

class AiChatInitialize extends AiChatEvent {
  const AiChatInitialize();
}

class AiChatSendMessage extends AiChatEvent {
  final String message;

  const AiChatSendMessage({required this.message});

  @override
  List<Object?> get props => [message];
}

class AiChatClear extends AiChatEvent {
  const AiChatClear();
}

class AiChatLoadHistory extends AiChatEvent {
  const AiChatLoadHistory();
}

class AiChatRetry extends AiChatEvent {
  const AiChatRetry();
}

class AiChatScanImage extends AiChatEvent {
  final String source;

  const AiChatScanImage({required this.source});

  @override
  List<Object?> get props => [source];
}

class AiChatStartVoice extends AiChatEvent {
  const AiChatStartVoice();
}

class AiChatStopVoice extends AiChatEvent {
  const AiChatStopVoice();
}

class AiChatConfirmTransaction extends AiChatEvent {
  final TransactionModel transaction;
  final int messageIndex;

  const AiChatConfirmTransaction({
    required this.transaction,
    required this.messageIndex,
  });

  @override
  List<Object?> get props => [transaction, messageIndex];
}

class AiChatCancelTransaction extends AiChatEvent {
  final int messageIndex;

  const AiChatCancelTransaction({required this.messageIndex});

  @override
  List<Object?> get props => [messageIndex];
}
