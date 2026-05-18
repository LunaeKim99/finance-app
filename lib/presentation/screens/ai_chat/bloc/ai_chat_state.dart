import 'package:equatable/equatable.dart';
import '../../../screens/ai_chat/ai_chat_screen.dart';

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
