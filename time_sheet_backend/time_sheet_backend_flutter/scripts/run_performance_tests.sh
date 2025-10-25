#!/bin/bash

# Script pour exécuter tous les tests de performance pointage
# Usage: ./scripts/run_performance_tests.sh [device_id]

set -e

echo "🚀 Démarrage des tests de performance Pointage"
echo "=============================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages colorés
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "pubspec.yaml" ]; then
    print_error "Ce script doit être exécuté depuis le répertoire time_sheet_backend_flutter"
    exit 1
fi

# Device ID optionnel
DEVICE_ID=${1:-""}
DEVICE_FLAG=""
if [ ! -z "$DEVICE_ID" ]; then
    DEVICE_FLAG="--device-id=$DEVICE_ID"
    print_status "Utilisation du device: $DEVICE_ID"
fi

# Créer le répertoire de rapports s'il n'existe pas
mkdir -p reports/performance

# Timestamp pour les rapports
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="reports/performance/$TIMESTAMP"
mkdir -p "$REPORT_DIR"

print_status "Rapports sauvegardés dans: $REPORT_DIR"

# Fonction pour exécuter un test et capturer la sortie
run_test() {
    local test_file=$1
    local test_name=$2
    local output_file="$REPORT_DIR/${test_name}_output.txt"
    
    print_status "Exécution: $test_name"
    
    if flutter test "$test_file" $DEVICE_FLAG --verbose > "$output_file" 2>&1; then
        print_success "$test_name - PASSED"
        
        # Extraire les métriques de performance
        grep -E "(build time|render time|transition time|animation time|improvement)" "$output_file" > "$REPORT_DIR/${test_name}_metrics.txt" 2>/dev/null || true
        
        return 0
    else
        print_error "$test_name - FAILED"
        echo "Voir les détails dans: $output_file"
        return 1
    fi
}

# Tests à exécuter
declare -a tests=(
    "test/pointage_performance_test.dart:Performance_Principaux"
    "test/pointage_performance_benchmark_test.dart:Benchmark"
)

# Compteurs
total_tests=${#tests[@]}
passed_tests=0
failed_tests=0

print_status "Exécution de $total_tests suites de tests"
echo ""

# Exécuter chaque test
for test_info in "${tests[@]}"; do
    IFS=':' read -r test_file test_name <<< "$test_info"
    
    if [ -f "$test_file" ]; then
        if run_test "$test_file" "$test_name"; then
            ((passed_tests++))
        else
            ((failed_tests++))
        fi
    else
        print_warning "Test non trouvé: $test_file"
        ((failed_tests++))
    fi
    
    echo ""
done

# Afficher le résumé
echo "=============================================="
echo "📊 RÉSUMÉ DES TESTS DE PERFORMANCE"
echo "=============================================="
print_status "Tests exécutés: $total_tests"
print_success "Tests réussis: $passed_tests"
if [ $failed_tests -gt 0 ]; then
    print_error "Tests échoués: $failed_tests"
else
    print_success "Tests échoués: $failed_tests"
fi

# Code de sortie
if [ $failed_tests -gt 0 ]; then
    print_error "Certains tests ont échoué. Vérifiez les rapports détaillés."
    exit 1
else
    print_success "Tous les tests de performance ont réussi! 🎉"
    exit 0
fi