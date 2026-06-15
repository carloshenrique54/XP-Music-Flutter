import 'package:shared_preferences/shared_preferences.dart';
import '../supabase_client.dart';

class AuthService {
  static const _keyUserId = 'xp_user_id';
  static const _keyUserNome = 'xp_user_nome';
  static const _keyUserEmail = 'xp_user_email';
  static const _keyUserAvatar = 'xp_user_avatar';

  // Usuário em memória (carregado do SharedPreferences)
  static Map<String, dynamic>? _currentUser;

  static Map<String, dynamic>? get currentUser => _currentUser;

  static bool get isLoggedIn => _currentUser != null;

  /// Carrega sessão salva ao iniciar o app
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_keyUserId);
    if (id == null) return;

    _currentUser = {
      'id': id,
      'nome': prefs.getString(_keyUserNome) ?? '',
      'email': prefs.getString(_keyUserEmail) ?? '',
      'avatar_url': prefs.getString(_keyUserAvatar) ?? '',
    };
  }

  /// Login com email + senha na tabela usuarios
  static Future<Map<String, dynamic>> login(String email, String senha) async {
    final res = await supabase
        .from('usuarios')
        .select()
        .eq('email', email.trim())
        .eq('senha', senha.trim())
        .maybeSingle();

    if (res == null) {
      throw Exception('Email ou senha incorretos');
    }

    _currentUser = res;
    await _saveSession(res);
    return res;
  }

  /// Verifica se o e-mail já está cadastrado
  static Future<bool> checkEmailExists(String email) async {
    try {
      final res = await supabase
          .from('usuarios')
          .select('id')
          .eq('email', email.trim())
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  /// Cadastro de novo usuário
  static Future<Map<String, dynamic>> register({
    required String email,
    required String senha,
    required String nome,
    String cpf = '',
    String cep = '',
  }) async {
    // Verifica se email já existe
    final existing = await supabase
        .from('usuarios')
        .select('id')
        .eq('email', email.trim())
        .maybeSingle();

    if (existing != null) {
      throw Exception('Este email já está cadastrado');
    }

    final res = await supabase
        .from('usuarios')
        .insert({
          'email': email.trim(),
          'senha': senha.trim(),
          'nome': nome.trim(),
          'cpf': cpf.trim(),
          'cep': cep.trim(),
        })
        .select()
        .single();

    _currentUser = res;
    await _saveSession(res);
    return res;
  }

  /// Atualiza perfil do usuário
  static Future<void> updateProfile({
    String? nome,
    String? avatarUrl,
    String? cep,
  }) async {
    if (_currentUser == null) return;

    final updates = <String, dynamic>{};
    if (nome != null) updates['nome'] = nome;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (cep != null) updates['cep'] = cep;

    await supabase
        .from('usuarios')
        .update(updates)
        .eq('id', _currentUser!['id']);

    _currentUser = {..._currentUser!, ...updates};
    await _saveSession(_currentUser!);
  }

  /// Logout — limpa sessão
  static Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserNome);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserAvatar);
  }

  static Future<void> _saveSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, user['id'] as int);
    await prefs.setString(_keyUserNome, user['nome'] ?? '');
    await prefs.setString(_keyUserEmail, user['email'] ?? '');
    await prefs.setString(_keyUserAvatar, user['avatar_url'] ?? '');
  }
}
