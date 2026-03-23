import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/chat_service.dart';
import '../utils/colors.dart';
import 'chat_conversation_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  late Future<List<ChatContact>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _contactsFuture = _chatService.fetchContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final contentWidth = isWide ? 760.0 : double.infinity;
          final sidePadding = isWide ? 24.0 : 16.0;

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
                      child: FutureBuilder<List<ChatContact>>(
                        future: _contactsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error al cargar contactos: ${snapshot.error}'),
                            );
                          }
                          final contacts = snapshot.data ?? [];
                          if (contacts.isEmpty) {
                            return const Center(
                              child: Text(
                                'No hay contactos disponibles para tu rol.',
                                style: TextStyle(color: AppColors.textGray700),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 20),
                            itemCount: contacts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final contact = contacts[index];
                              return _buildContactCard(context, contact);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
            Color(0xFF0E7490),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Mensajes',
                style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Conversaciones habilitadas segun tu rol',
                style: TextStyle(
                  color: AppColors.textOnDarkMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, ChatContact contact) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(contact: contact),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.bgBlue50,
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.textGray900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textGray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: contact.roles
                        .map(
                          (role) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.bgGray100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              role,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGray600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textGray400),
          ],
        ),
      ),
    );
  }
}
