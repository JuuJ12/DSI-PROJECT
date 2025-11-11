import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:dsi_project/data/repositories/auth_repository.dart';
import 'package:dsi_project/data/repositories/firestore_user_repository.dart';
import 'package:dsi_project/features/profile/edit_profile_screen.dart';
import 'package:dsi_project/domain/user_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final FirestoreUserRepository _userRepository = FirestoreUserRepository();
  final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _logger.i('Carregando dados do usuário...');
    final userId = _authRepository.currentUser?.uid;
    _logger.d('userId: $userId');

    if (userId != null) {
      final user = await _userRepository.getUserById(userId);
      _logger.i('Usuário carregado: ${user?.displayName}');
      _logger.d('profileImageUrl: ${user?.profileImageUrl}');

      if (mounted) {
        setState(() {
          _userModel = user;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Mostrar diálogo de confirmação
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Sair da conta',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Tem certeza que deseja sair?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Sair',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await _authRepository.signOut();
        if (context.mounted) {
          // Navegar para a tela de login usando go_router
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao fazer logout: $e'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = _authRepository.currentUser;
    final displayName =
        _userModel?.displayName ?? authUser?.displayName ?? 'Usuário';
    final email = authUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configurações',
          style: TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 20),

                // Seção Conta
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'CONTA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Card de informações do usuário
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF6B7B5E),
                        backgroundImage:
                            _userModel?.profileImageUrl != null &&
                                _userModel!.profileImageUrl!.isNotEmpty
                            ? NetworkImage(_userModel!.profileImageUrl!)
                            : null,
                        child:
                            _userModel?.profileImageUrl == null ||
                                _userModel!.profileImageUrl!.isEmpty
                            ? Text(
                                displayName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Informações
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Seção Geral
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'GERAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Opções
                _buildSettingItem(
                  icon: Icons.person_outline,
                  title: 'Editar perfil',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                    // Recarrega os dados quando voltar da edição
                    _loadUserData();
                  },
                ),
                _buildSettingItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notificações',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Funcionalidade estará disponível em breve',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
                _buildSettingItem(
                  icon: Icons.lock_outline,
                  title: 'Privacidade',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Funcionalidade estará disponível em breve',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Seção Sobre
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'SOBRE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _buildSettingItem(
                  icon: Icons.help_outline,
                  title: 'Ajuda e suporte',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Funcionalidade estará disponível em breve',
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: 'Sobre o app',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('DSI Project - Versão 1.0.0'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Botão de Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red[200]!),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 20, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Sair da conta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 24, color: Colors.grey[700]),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
