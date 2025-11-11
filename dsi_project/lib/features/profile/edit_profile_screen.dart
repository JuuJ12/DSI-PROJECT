import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:dsi_project/data/repositories/auth_repository.dart';
import 'package:dsi_project/data/repositories/firestore_user_repository.dart';
import 'package:dsi_project/core/utils/date_input_formatter.dart';
import 'package:dsi_project/data/services/profile_image_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final FirestoreUserRepository _userRepository = FirestoreUserRepository();
  final ProfileImageService _imageService = ProfileImageService();
  final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  bool _hasUnsavedChanges = false;
  bool _isLoading = true;
  File? _selectedImage;
  String? _currentImageUrl;
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userId = _authRepository.currentUser?.uid;
    if (userId != null) {
      final user = await _userRepository.getUserById(userId);
      if (user != null && mounted) {
        setState(() {
          _nameController.text = user.displayName ?? '';
          _emailController.text = user.email;
          _currentImageUrl = user.profileImageUrl;
          if (user.dateOfBirth != null) {
            final date = user.dateOfBirth!;
            _birthDateController.text =
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
          }
          _isLoading = false;
        });
      }
    }
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Escolher foto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      _logger.i('Iniciando seleção de imagem. Source: $source');
      final image = await _imageService.pickImage(source: source);

      if (image != null) {
        _logger.i('Imagem selecionada com sucesso: ${image.path}');
        setState(() {
          _selectedImage = image;
          _markAsChanged();
        });
      } else {
        _logger.i('Seleção de imagem cancelada pelo usuário');
      }
    } catch (e, stackTrace) {
      _logger.e('Erro ao selecionar imagem', error: e, stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Descartar alterações?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: const Text(
            'Você tem alterações não salvas. Deseja descartar?',
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
                'Descartar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    return shouldDiscard ?? false;
  }

  Future<void> _saveProfile() async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return;

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('O nome não pode estar vazio'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Parse da data de nascimento
    DateTime? birthDate;
    final birthDateText = _birthDateController.text.trim();
    if (birthDateText.isNotEmpty) {
      final parts = birthDateText.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day != null &&
            month != null &&
            year != null &&
            day >= 1 &&
            day <= 31 &&
            month >= 1 &&
            month <= 12 &&
            year >= 1900 &&
            year <= DateTime.now().year) {
          try {
            birthDate = DateTime(year, month, day);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Data de nascimento inválida'),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Data de nascimento inválida. Use o formato DD/MM/AAAA',
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    }

    try {
      // Busca o usuário atual
      final currentUser = await _userRepository.getUserById(userId);
      if (currentUser == null) {
        throw Exception('Usuário não encontrado');
      }

      // Upload da imagem se selecionada
      String? newImageUrl;
      if (_selectedImage != null) {
        _logger.i('Fazendo upload da imagem...');
        newImageUrl = await _imageService.uploadProfileImage(
          userId,
          _selectedImage!,
        );
        _logger.i('URL recebida do upload: $newImageUrl');

        // Remove a imagem antiga se existir
        if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
          try {
            _logger.i('Deletando imagem antiga: $_currentImageUrl');
            await _imageService.deleteProfileImage(_currentImageUrl!);
          } catch (e) {
            _logger.w('Erro ao deletar imagem antiga', error: e);
            // Ignora erro ao deletar imagem antiga
          }
        }
      }

      // Atualiza apenas os campos editados
      final updatedUser = currentUser.copyWith(
        displayName: name,
        dateOfBirth: birthDate,
        profileImageUrl: newImageUrl ?? _currentImageUrl,
      );

      _logger.i(
        'Atualizando usuário com profileImageUrl: ${updatedUser.profileImageUrl}',
      );
      await _userRepository.updateUser(updatedUser);
      _logger.i('Usuário atualizado com sucesso');

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () async {
              if (_hasUnsavedChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Editar Perfil',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Center(
                            child: GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                      image: _selectedImage != null
                                          ? DecorationImage(
                                              image: FileImage(_selectedImage!),
                                              fit: BoxFit.cover,
                                            )
                                          : _currentImageUrl != null &&
                                                _currentImageUrl!.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                _currentImageUrl!,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child:
                                        (_selectedImage == null &&
                                            (_currentImageUrl == null ||
                                                _currentImageUrl!.isEmpty))
                                        ? Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey[400],
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A1A1A),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Nome
                          const Text(
                            'Nome',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            onChanged: (_) => _markAsChanged(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Seu nome',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              fillColor: Colors.grey[50],
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1A1A1A),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email (somente leitura)
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            enabled: false,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                            decoration: InputDecoration(
                              hintText: 'Seu email',
                              fillColor: Colors.grey[100],
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Data de Nascimento
                          const Text(
                            'Data de Nascimento',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _birthDateController,
                            onChanged: (_) => _markAsChanged(),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              DateInputFormatter(),
                              LengthLimitingTextInputFormatter(
                                10,
                              ), // DD/MM/AAAA = 10 caracteres
                            ],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'DD/MM/AAAA',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              fillColor: Colors.grey[50],
                              filled: true,
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1A1A1A),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Botão Salvar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _hasUnsavedChanges ? _saveProfile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasUnsavedChanges
                            ? const Color(0xFF1A1A1A)
                            : Colors.grey[300],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Salvar Alterações',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
