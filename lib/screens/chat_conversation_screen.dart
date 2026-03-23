import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/session_service.dart';
import '../utils/colors.dart';

class ChatConversationScreen extends StatefulWidget {
  final ChatContact contact;

  const ChatConversationScreen({Key? key, required this.contact}) : super(key: key);

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  final Set<int> _messageIds = {};
  final Map<String, int> _pendingIndexes = {};

  WebSocketChannel? _channel;
  StreamSubscription? _socketSub;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  bool _connecting = false;
  bool _socketReady = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;

  int? get _currentUserId => SessionManager.instance.currentUser?.id;
  String? get _currentUserName => SessionManager.instance.currentUser?.name;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _connectSocket();
    _startPollingFallback();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: false));
  }

  @override
  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
    _socketSub?.cancel();
    _channel?.sink.close();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _chatService.fetchMessages(widget.contact.id);
      setState(() {
        _messages.clear();
        _messages.addAll(history);
        _messageIds.addAll(history.where((m) => m.id != null).map((m) => m.id!));
      });
      debugPrint('[chat] history loaded count=${history.length}');
      _scrollToBottom(animate: false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar el historial de mensajes')),
      );
    }
  }

  Future<void> _connectSocket() async {
    if (_connecting) return;
    _connecting = true;

    var token = SessionManager.instance.accessToken;
    if (token == null) {
      await SessionManager.instance.refreshTokens();
      token = SessionManager.instance.accessToken;
    }
    if (token == null) {
      debugPrint('[chat] no token, skip connect');
      _connecting = false;
      return;
    }

    debugPrint('[chat] connect user=${_currentUserId} contact=${widget.contact.id}');
    _channel?.sink.close();
    _socketSub?.cancel();
    _channel = _chatService.connectSocket(token: token);
    _socketReady = true;
    _reconnectAttempts = 0;
    debugPrint('[chat] ws connect: contact=${widget.contact.id}');
    _socketSub = _channel!.stream.listen(
      (payload) {
        try {
          final event = _chatService.decodeSocketEvent(payload);
          debugPrint('[chat] ws recv: $event');
          if (event['type'] != 'message') return;
          final messageJson = event['message'] as Map<String, dynamic>;
          final message = ChatMessage.fromJson(messageJson);
          debugPrint(
            '[chat] message recv id=${message.id} from=${message.senderId} to=${message.recipientId} content=${message.content}',
          );
          _handleIncomingMessage(message);
        } catch (error) {
          debugPrint('[chat] ws decode error: $error');
        }
      },
      onError: (_) {
        debugPrint('[chat] ws error -> reconnect');
        _scheduleReconnect();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conexion de chat interrumpida')),
        );
      },
      onDone: () {
        debugPrint('[chat] ws closed -> reconnect');
        _scheduleReconnect();
      },
    );
    _connecting = false;
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _socketReady = false;
    _socketSub?.cancel();
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    _reconnectAttempts = (_reconnectAttempts + 1).clamp(1, 6);
    final delaySeconds = 2 * _reconnectAttempts;
    debugPrint('[chat] schedule reconnect in ${delaySeconds}s');
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      _connectSocket();
    });
  }

  void _startPollingFallback() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!_shouldReconnect) return;
      //if (_socketReady) return;
      try {
        final history = await _chatService.fetchMessages(widget.contact.id);
        _mergeHistory(history);
      } catch (_) {
        // ignore polling errors
      }
    });
  }

  void _mergeHistory(List<ChatMessage> history) {
    bool changed = false;
    for (final message in history) {
      if (message.id != null && _messageIds.contains(message.id)) {
        continue;
      }
      if (_replacePendingMessage(message)) {
        changed = true;
        continue;
      }
      _messages.add(message);
      if (message.id != null) {
        _messageIds.add(message.id!);
      }
      changed = true;
    }
    if (changed && mounted) {
      debugPrint('[chat] polling merge added');
      setState(() {});
      _scrollToBottom();
    }
  }

  void _handleIncomingMessage(ChatMessage message) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    final isConversationMatch = (message.senderId == widget.contact.id && message.recipientId == currentUserId) ||
        (message.senderId == currentUserId && message.recipientId == widget.contact.id);
    if (!isConversationMatch) {
      debugPrint(
        '[chat] message ignored for chat contact=${widget.contact.id} current=$currentUserId '
        'from=${message.senderId} to=${message.recipientId}',
      );
      return;
    }

    if (message.clientMessageId != null && _pendingIndexes.containsKey(message.clientMessageId)) {
      final index = _pendingIndexes.remove(message.clientMessageId);
      if (index != null && index >= 0 && index < _messages.length) {
        setState(() {
          _messages[index] = message;
          if (message.id != null) {
            _messageIds.add(message.id!);
          }
        });
        debugPrint('[chat] message ack replace index=$index');
        _scrollToBottom();
        return;
      }
    }

    if (_replacePendingMessage(message)) {
      _scrollToBottom();
      return;
    }

    if (message.id != null && _messageIds.contains(message.id)) {
      return;
    }

    setState(() {
      _messages.add(message);
      if (message.id != null) {
        _messageIds.add(message.id!);
      }
    });
    debugPrint('[chat] message append total=${_messages.length}');
    _scrollToBottom();
  }

  bool _replacePendingMessage(ChatMessage message) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return false;
    if (message.senderId != currentUserId) return false;
    final index = _messages.indexWhere(
      (m) =>
          m.id == null &&
          m.senderId == message.senderId &&
          m.recipientId == message.recipientId &&
          m.content == message.content,
    );
    if (index == -1) return false;
    setState(() {
      _messages[index] = message;
      if (message.id != null) {
        _messageIds.add(message.id!);
      }
    });
    debugPrint('[chat] pending replaced by content index=$index');
    return true;
  }

  Future<void> _sendMessage() async {
    final content = _inputController.text.trim();
    if (content.isEmpty) return;
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    _inputController.clear();
    final clientId = DateTime.now().microsecondsSinceEpoch.toString();
    final localMessage = ChatMessage(
      id: null,
      senderId: currentUserId,
      recipientId: widget.contact.id,
      content: content,
      createdAt: DateTime.now(),
      senderName: _currentUserName,
      clientMessageId: clientId,
    );

    setState(() {
      _messages.add(localMessage);
      _pendingIndexes[clientId] = _messages.length - 1;
    });
    debugPrint('[chat] local send queued id=$clientId');
    _scrollToBottom();

    if (_channel != null && _socketReady) {
      final payload = _chatService.encodeSocketMessage(
        recipientId: widget.contact.id,
        content: content,
        clientMessageId: clientId,
      );
      try {
        debugPrint('[chat] ws send: $payload');
        _channel!.sink.add(jsonEncode(payload));
        return;
      } catch (_) {
        debugPrint('[chat] ws send failed -> fallback');
        _scheduleReconnect();
      }
    }
    try {
      final sent = await _chatService.sendMessage(
        widget.contact.id,
        content,
        clientMessageId: clientId,
      );
      _handleIncomingMessage(sent.copyWith(senderName: _currentUserName));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el mensaje')),
      );
    }
    return;
  }

  void _scrollToBottom({bool animate = true, int retries = 3}) {
    if (!_scrollController.hasClients) {
      if (retries > 0) {
        Timer(const Duration(milliseconds: 60), () {
          _scrollToBottom(animate: animate, retries: retries - 1);
        });
      }
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.position.maxScrollExtent + 80;
      if (animate) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(offset);
      }
    });
    Timer(const Duration(milliseconds: 120), () {
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.position.maxScrollExtent + 80;
      _scrollController.jumpTo(offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;
          final contentWidth = isWide ? 820.0 : double.infinity;
          final sidePadding = isWide ? 24.0 : 16.0;
          final maxBubbleWidth = isWide ? 440.0 : constraints.maxWidth * 0.7;

          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: AppColors.bgSlate100,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: _messages.isEmpty
                          ? const Center(
                              child: Text(
                                'Inicia la conversacion enviando un mensaje.',
                                style: TextStyle(color: AppColors.textGray700),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.fromLTRB(sidePadding, 18, sidePadding, 24),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isMine = message.senderId == _currentUserId;
                                return _buildMessageBubble(message, isMine, maxBubbleWidth);
                              },
                            ),
                    ),
                  ),
                ),
              ),
              _buildComposer(maxWidth: contentWidth, sidePadding: sidePadding),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E40AF),
            Color(0xFF0E7490),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1E40AF),
                child: Text(
                  widget.contact.name.isNotEmpty ? widget.contact.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.contact.name,
                      style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.contact.roles.join(', '),
                      style: const TextStyle(
                        color: AppColors.textOnDarkMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMine, double maxWidth) {
    final bubbleColor = isMine ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC);
    final textColor = isMine ? Colors.white : const Color(0xFF0F172A);
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(14),
              border: isMine ? null : Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(message.createdAt),
            style: const TextStyle(fontSize: 10, color: AppColors.textGray400),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer({required double maxWidth, required double sidePadding}) {
    return Container(
      padding: EdgeInsets.fromLTRB(sidePadding, 10, sidePadding, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
