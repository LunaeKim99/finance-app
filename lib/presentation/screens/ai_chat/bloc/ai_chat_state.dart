import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../../data/models/transaction_model.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;
  final bool isRetryButton;
  final TransactionModel? pendingTransaction;
  final File? imageFile;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
    this.isRetryButton = false,
    this.pendingTransaction,
    this.imageFile,
    required this.timestamp,
  });
}

abstract class AiChatState extends Equatable {
  const AiChatState();

  @override
  List<Object?> get props => [];
}

class AiChatInitial extends AiChatState {
  const AiChatInitial();
}

class AiChatLoading extends AiChatState {
  final List<ChatMessage> messages;

  const AiChatLoading({required this.messages});

  @override
  List<Object?> get props => [messages];
}

class AiChatMessageAdded extends AiChatState {
  final List<ChatMessage> messages;

  const AiChatMessageAdded({required this.messages});

  @override
  List<Object?> get props => [messages];
}

class AiChatError extends AiChatState {
  final String message;
  final List<ChatMessage> messages;

  const AiChatError({required this.message, required this.messages});

  @override
  List<Object?> get props => [message, messages];
}
