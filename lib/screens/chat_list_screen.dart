import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/chat_service.dart';
import '../utils/colors.dart';
import '../utils/responsive_breakpoints.dart';
import '../widgets/app_hero_header.dart';
import '../widgets/app_state_views.dart';
import '../widgets/desktop_content_scaffold.dart';
import 'chat_conversation_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

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
          final isDesktop = ResponsiveBreakpoints.isDesktop(context);
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
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const AppLoadingView(
                              label: 'Cargando contactos',
                            );
                          }
                          if (snapshot.hasError) {
                            return AppMessageCard(
                              title: 'No se pudo cargar el chat',
                              message:
                                  'Error al cargar contactos: ${snapshot.error}',
                              icon: Icons.forum_outlined,
                              iconColor: AppColors.moduleOrange,
                            );
                          }
                          final contacts = snapshot.data ?? [];
                          if (contacts.isEmpty) {
                            return const AppMessageCard(
                              title: 'Sin contactos disponibles',
                              message:
                                  'No hay contactos habilitados para tu rol por ahora.',
                              icon: Icons.people_outline,
                            );
                          }
                          if (isDesktop) {
                            return DesktopContentScaffold(
                              padding: const EdgeInsets.all(20),
                              sidePanel: _ChatListSidePanel(
                                contactsCount: contacts.length,
                              ),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: contacts.length,
                                separatorBuilder: (_, separatorIndex) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final contact = contacts[index];
                                  return _buildContactCard(context, contact);
                                },
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: sidePadding,
                              vertical: 20,
                            ),
                            itemCount: contacts.length,
                            separatorBuilder: (_, separatorIndex) =>
                                const SizedBox(height: 12),
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
    return const AppHeroHeader(
      title: 'Mensajes',
      subtitle: 'Conversaciones habilitadas segun tu rol',
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
              color: Colors.black.withValues(alpha: 0.04),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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

class _ChatListSidePanel extends StatelessWidget {
  const _ChatListSidePanel({required this.contactsCount});

  final int contactsCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conversaciones',
                style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Selecciona un contacto para abrir la conversacion.',
                style: TextStyle(color: AppColors.textOnDarkMuted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGray200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Contactos visibles',
                style: TextStyle(color: AppColors.textGray600),
              ),
              Text(
                '$contactsCount',
                style: const TextStyle(
                  color: AppColors.textGray900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
