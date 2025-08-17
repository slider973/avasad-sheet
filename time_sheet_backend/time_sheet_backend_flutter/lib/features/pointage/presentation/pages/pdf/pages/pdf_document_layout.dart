import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/pages/share_pdf.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/pages/share_excel.dart';

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class PdfDocumentLayout extends StatelessWidget {
  final List<dynamic> pdfs;
  final VoidCallback onGenerateCurrentMonth;
  final VoidCallback onChooseMonth;
  final Function(String) onOpenPdf;
  final Function(int) onDeletePdf;
  final VoidCallback? onGenerateCurrentMonthExcel;
  final VoidCallback? onChooseMonthExcel;

  const PdfDocumentLayout({
    super.key,
    required this.pdfs,
    required this.onGenerateCurrentMonth,
    required this.onChooseMonth,
    required this.onOpenPdf,
    required this.onDeletePdf,
    this.onGenerateCurrentMonthExcel,
    this.onChooseMonthExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: const Text('Documents'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Générer des documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Si l'écran est trop petit, utiliser une disposition en colonne
                    if (constraints.maxWidth < 500) {
                      return Column(
                        children: [
                          _buildActionCard(
                            context,
                            title: 'Mois en cours',
                            subtitle: _getCurrentMonthPeriod(),
                            icon: Icons.today,
                            iconColor: Colors.blue,
                            actions: [
                              _ActionItem(
                                icon: Icons.picture_as_pdf,
                                label: 'Générer PDF',
                                color: Colors.red,
                                onTap: onGenerateCurrentMonth,
                              ),
                              if (onGenerateCurrentMonthExcel != null)
                                _ActionItem(
                                  icon: Icons.table_chart,
                                  label: 'Générer Excel',
                                  color: Colors.green,
                                  onTap: onGenerateCurrentMonthExcel!,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildActionCard(
                            context,
                            title: 'Autre période',
                            subtitle: 'Sélectionner un mois',
                            icon: Icons.calendar_month,
                            iconColor: Colors.orange,
                            actions: [
                              _ActionItem(
                                icon: Icons.picture_as_pdf,
                                label: 'PDF personnalisé',
                                color: Colors.red,
                                onTap: onChooseMonth,
                              ),
                              if (onChooseMonthExcel != null)
                                _ActionItem(
                                  icon: Icons.table_chart,
                                  label: 'Excel personnalisé',
                                  color: Colors.green,
                                  onTap: onChooseMonthExcel!,
                                ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      // Disposition en ligne pour les écrans plus larges
                      return Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              context,
                              title: 'Mois en cours',
                              subtitle: _getCurrentMonthPeriod(),
                              icon: Icons.today,
                              iconColor: Colors.blue,
                              actions: [
                                _ActionItem(
                                  icon: Icons.picture_as_pdf,
                                  label: 'Générer PDF',
                                  color: Colors.red,
                                  onTap: onGenerateCurrentMonth,
                                ),
                                if (onGenerateCurrentMonthExcel != null)
                                  _ActionItem(
                                    icon: Icons.table_chart,
                                    label: 'Générer Excel',
                                    color: Colors.green,
                                    onTap: onGenerateCurrentMonthExcel!,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionCard(
                              context,
                              title: 'Autre période',
                              subtitle: 'Sélectionner un mois',
                              icon: Icons.calendar_month,
                              iconColor: Colors.orange,
                              actions: [
                                _ActionItem(
                                  icon: Icons.picture_as_pdf,
                                  label: 'PDF personnalisé',
                                  color: Colors.red,
                                  onTap: onChooseMonth,
                                ),
                                if (onChooseMonthExcel != null)
                                  _ActionItem(
                                    icon: Icons.table_chart,
                                    label: 'Excel personnalisé',
                                    color: Colors.green,
                                    onTap: onChooseMonthExcel!,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Documents générés',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pdfs.length,
              itemBuilder: (context, index) {
                final pdf = pdfs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: pdf.fileName.endsWith('.xlsx')
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        pdf.fileName.endsWith('.xlsx') ? Icons.table_chart : Icons.picture_as_pdf,
                        color: pdf.fileName.endsWith('.xlsx') ? Colors.green : Colors.red,
                        size: 24,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            pdf.fileName.replaceAll('.pdf', '').replaceAll('.xlsx', ''),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: pdf.fileName.endsWith('.xlsx')
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pdf.fileName.endsWith('.xlsx') ? 'Excel' : 'PDF',
                            style: TextStyle(
                              fontSize: 12,
                              color: pdf.fileName.endsWith('.xlsx') ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(pdf.generatedDate),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.blue),
                            tooltip: 'Partager',
                            onPressed: () =>
                                pdf.fileName.endsWith('.xlsx') ? shareExcel(pdf.filePath) : sharePdf(pdf.filePath),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Supprimer',
                            onPressed: () => onDeletePdf(pdf.id),
                          ),
                        ],
                      ),
                    ),
                    onTap: () => onOpenPdf(pdf.filePath),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentMonthPeriod() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Déterminer la période en fonction du jour actuel
    DateTime startDate;
    DateTime endDate;

    if (now.day > 21) {
      // Si on est après le 21, la période est du 21 du mois courant au 20 du mois suivant
      startDate = DateTime(currentYear, currentMonth, 21);
      if (currentMonth == 12) {
        endDate = DateTime(currentYear + 1, 1, 20);
      } else {
        endDate = DateTime(currentYear, currentMonth + 1, 20);
      }
    } else {
      // Si on est avant ou le 21, la période est du 21 du mois précédent au 20 du mois courant
      if (currentMonth == 1) {
        startDate = DateTime(currentYear - 1, 12, 21);
      } else {
        startDate = DateTime(currentYear, currentMonth - 1, 21);
      }
      endDate = DateTime(currentYear, currentMonth, 20);
    }

    final format = DateFormat('dd MMM', 'fr_FR');
    return '${format.format(startDate)} - ${format.format(endDate)}';
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<_ActionItem> actions,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...actions.map((action) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Material(
                    color: action.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: action.onTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              action.icon,
                              color: action.color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                action.label,
                                style: TextStyle(
                                  color: action.color,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
