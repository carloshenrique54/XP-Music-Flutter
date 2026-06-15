import 'package:flutter/material.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = [
      _PlanData(
        name: 'Gratuito',
        price: 'R\$ 0,00',
        features: [
          'Anúncios entre faixas',
          'Qualidade de áudio padrão',
          'Preview de 30 segundos por música',
          'Apenas modo online',
        ],
        ctaText: 'Continuar no Grátis',
        isPopular: false,
        color: Colors.white60,
      ),
      _PlanData(
        name: 'Individual',
        price: 'R\$ 21,90/mês',
        features: [
          'Sem anúncios',
          'Qualidade de áudio HD',
          'Músicas completas sem limite',
          'Modo offline (Downloads)',
          'Ouça em qualquer dispositivo',
        ],
        ctaText: 'Começar Agora',
        isPopular: true,
        color: const Color(0xFFA855F7), // Primária
      ),
      _PlanData(
        name: 'Duo',
        price: 'R\$ 28,90/mês',
        features: [
          '2 contas Premium para pessoas que moram juntas',
          'Sem anúncios',
          'Qualidade de áudio HD',
          'Modo offline (Downloads)',
          'Playlists compartilhadas',
        ],
        ctaText: 'Assinar Duo',
        isPopular: false,
        color: const Color(0xFF7E22CE), // Secundária
      ),
      _PlanData(
        name: 'Universitário',
        price: 'R\$ 11,90/mês',
        features: [
          'Desconto especial para estudantes universitários',
          'Sem anúncios',
          'Qualidade de áudio HD',
          'Modo offline (Downloads)',
          'Comprovante estudantil exigido',
        ],
        ctaText: 'Validar Estudante',
        isPopular: false,
        color: const Color(0xFF3B82F6), // Azul
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Escolha seu plano',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E0B36), Color(0xFF0C0418), Color(0xFF05000C)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'XP PREMIUM',
                  style: TextStyle(
                    color: Color(0xFFA855F7),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Música ilimitada para todos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Escolha o plano ideal para o seu momento e curta sem interrupções.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 30),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: plans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return _PlanCard(plan: plan);
                  },
                ),
                const SizedBox(height: 40),
                const Text(
                  'Sujeito a termos e condições. O plano Universitário exige verificação anual.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanData {
  final String name;
  final String price;
  final List<String> features;
  final String ctaText;
  final bool isPopular;
  final Color color;

  _PlanData({
    required this.name,
    required this.price,
    required this.features,
    required this.ctaText,
    required this.isPopular,
    required this.color,
  });
}

class _PlanCard extends StatelessWidget {
  final _PlanData plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF140826),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: plan.isPopular ? const Color(0xFFA855F7) : Colors.white10,
          width: plan.isPopular ? 2 : 1,
        ),
        boxShadow: plan.isPopular
            ? [
                BoxShadow(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      plan.price,
                      style: TextStyle(
                        color: plan.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),
                ...plan.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFA855F7),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF080014),
                          content: Text(
                            'Você selecionou o plano ${plan.name}!',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.isPopular ? const Color(0xFFA855F7) : Colors.white10,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      plan.ctaText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (plan.isPopular)
            Positioned(
              top: -12,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA855F7), Color(0xFF7E22CE)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Mais Popular',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
