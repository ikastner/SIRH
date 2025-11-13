# Réunion SIRH UCN - Analyse Technique
## Espace Unifié URSSAF : Architecture Base de Données

**Date** : À définir  
**Participants** : SIRH UCN - Équipe Technique  
**Objet** : Présentation et analyse technique des deux architectures BDD proposées

---

## 1. Contexte et Objectifs du Projet

### 1.1. Problématique Actuelle

L'URSSAF dispose actuellement de **multiples outils RH éparpillés** (Canopée, GTA, différents intranets) qui génèrent :
- **Complexité de navigation** : Difficulté à trouver les formulaires et services
- **Manque de centralisation** : Informations dispersées, recherches chronophages
- **Multiplicité des outils** : Aucune interconnexion, ressaisies fréquentes
- **Manque de traçabilité** : Pas de vision consolidée des demandes RH
- **Formulaires hétérogènes** : Chaque formulaire a sa propre structure/UX

### 1.2. Objectifs de l'Espace Unifié

Créer un **point d'entrée unique** pour tous les services RH avec :
- ✅ Centralisation des demandes RH (formulaires, validations, suivi)
- ✅ Unification des formulaires avec modèle UX homogène
- ✅ Centre de notifications intégré (remplacement emails opérationnels)
- ✅ Dossier Agent consolidé (historique, documents, statuts)
- ✅ Tableaux de bord personnalisés par rôle (Agent, Manager, RH, PCS)
- ✅ Intégration avec ANAIS (authentification et rôles)
- ✅ Développement via Convertigo Low Code Studio

### 1.3. Formulaires Prioritaires

Deux formulaires complexes identifiés comme cas d'usage principaux :

#### **Badges** (15 types de demandes)
- Collaborateurs : nouveau, départ, perdu, HS, accès spécifique
- Personnel : standard, oublié, désactivation
- Prestataires : nouveau, renouvellement, départ, perdu, HS, accès spécifique
- Autre : demandes spécifiques

#### **Heures Supplémentaires**
- **Demande Préalable** : Validation Manager → RH → Approbation
- **Réalisation** : Saisie pointages → Validation Manager → RH → Pointage RH → Paiement
- **Lien Préalable ↔ Réalisation** : Traçabilité complète du cycle

### 1.4. Contraintes Techniques

- **Plateforme** : Convertigo Low Code Studio
- **Authentification** : ANAIS (recouvrement) - rôles hérités
- **Base de données** : PostgreSQL
- **Performance** : Grand volume de demandes, requêtes fréquentes
- **Extensibilité** : Déploiement progressif de nouveaux formulaires

---

## 2. Analyse Technique : Deux Architectures Proposées

Deux approches d'architecture base de données ont été analysées pour répondre aux besoins :

### Architecture 1 : Structure Unifiée (Approche Flexible)
### Architecture 2 : Structure Modulaire (Approche Relationnelle)

---

## 3. Architecture 1 : Structure Unifiée

### 3.1. Concept

**Principe** : Une seule table générique `demande` qui stocke toutes les demandes (Badges, HS, futures...) avec les données métier dans un champ JSONB flexible.

### 3.2. Structure Principale

```
agent
  └── formulaire (catalogue + schéma JSONB)
       └── demande (table générique)
            ├── donnees JSONB (données métier flexibles)
            ├── statut
            ├── etape_actuelle
            └── valideur_demande (chaîne de validation)
                 └── historique_demande (traçabilité auto)
                      └── document (pièces jointes)
                           └── notification
```

**Tables clés** :
- `demande` : Table unique avec `donnees JSONB` contenant toutes les données spécifiques
- `formulaire` : Contient `schema_formulaire JSONB` (définition des champs) et `regles JSONB` (workflow)
- `valideur_demande` : Gère les chaînes de validation multi-étapes

### 3.3. Exemple : Badge Nouveau Collaborateur

```sql
-- Table demande
INSERT INTO demande (formulaire_id, code_agent_demandeur, statut, donnees) VALUES
(1, 'AG001', 'en_validation',
 '{
   "type": "nouveau_collab",
   "nom": "Dupuis",
   "prenom": "Amélie",
   "service": "RH006",
   "zones_acces": ["Bureau", "Parking"],
   "horaires": "Standard"
 }'::jsonb);
```

### 3.4. Avantages

✅ **Extensibilité maximale** : Ajouter un nouveau formulaire sans migration BDD
✅ **Souplesse** : Structure adaptée aux spécificités de chaque formulaire
✅ **Cohérence** : Un seul modèle pour tous les formulaires
✅ **Simplicité structurelle** : Moins de tables à maintenir
✅ **Évolution rapide** : Modification des formulaires sans impact BDD

### 3.5. Inconvénients

⚠️ **Requêtes JSONB** : Requiert des requêtes avec opérateurs JSONB (moins performant)
⚠️ **Indexation limitée** : Index GIN sur JSONB moins efficace que colonnes dédiées
⚠️ **Intégrité** : Validation des données JSONB côté application (pas de contraintes SQL)
⚠️ **Complexité requêtes** : Parsing JSONB pour filtres/agrégations

### 3.6. Fichier SQL
📄 `script_bdd_badges_heuresup_complet.sql`

---

## 4. Architecture 2 : Structure Modulaire

### 4.1. Concept

**Principe** : Tables dédiées par domaine métier avec colonnes typées. Structure relationnelle classique.

### 4.2. Structure Principale

```
organisation ──┐
service ───────┼── agent
statut ────────┤
                │
badge ──────────┼── validation_etape
heures_sup_prealable ─┤
heures_sup_realisation ┘
  └── traceabilite (polymorphique)
       └── piece_jointe (polymorphique)
            └── workflow_etape
                 └── notification
```

**Tables clés** :
- `badge` : Table dédiée avec colonnes typées (nom_collaborateur, societe_prestataire, zones_acces[], etc.)
- `heures_sup_prealable` : Colonnes dédiées (date_debut, date_fin, nb_heures_total, etc.)
- `heures_sup_realisation` : Lien FK vers préalable + colonnes dédiées
- `statut` : Référentiel centralisé
- `traceabilite` : Table polymorphique pour traçabilité unifiée
- `validation_etape` : Table polymorphique pour validations avec workflow

### 4.3. Exemple : Badge Nouveau Collaborateur

```sql
-- Table badge dédiée
INSERT INTO badge (
    type_badge,
    code_agent_demandeur,
    nom_collaborateur,
    prenom_collaborateur,
    service_collaborateur,
    zones_acces,
    horaires,
    statut_code
) VALUES (
    'nouveau_collab',
    'AG001',
    'Dupuis',
    'Amélie',
    'RH006',
    ARRAY['Bureau', 'Parking'],
    'Standard',
    'en_validation'
);
```

### 4.4. Avantages

✅ **Performance optimale** : Index sur colonnes réelles, requêtes SQL standards
✅ **Intégrité forte** : Contraintes SQL natives, types stricts
✅ **Requêtes simples** : Pas de parsing JSONB, SQL classique
✅ **Clarté structurelle** : Chaque domaine a sa table, schéma explicite
✅ **Maintenance facilitée** : Structure visible et documentée
✅ **Évolutivité contrôlée** : Ajout de colonnes nécessite migration (sécurisé)

### 4.5. Inconvénients

⚠️ **Migrations nécessaires** : Ajout de nouveaux formulaires = création/modification de tables
⚠️ **Structure plus complexe** : Plus de tables à gérer (badge, heures_sup_prealable, heures_sup_realisation, etc.)
⚠️ **Moins flexible** : Structure figée, adaptabilité moindre aux cas particuliers
⚠️ **Tables polymorphiques** : Requiert gestion `type_demande` + `demande_id` pour tables transverses

### 4.6. Fichier SQL
📄 `script_bdd_modulaire.sql`

---

## 5. Comparatif Détaillé

### 5.1. Tableau Comparatif

| Critère | Architecture 1 (Unifiée) | Architecture 2 (Modulaire) |
|---------|---------------------------|----------------------------|
| **Nombre de tables** | ~10 tables | ~15 tables |
| **Structure données** | JSONB flexible | Colonnes typées |
| **Performance requêtes** | Moyenne (index GIN) | Excellente (index B-tree) |
| **Intégrité référentielle** | Application | SQL native |
| **Extensibilité** | ⭐⭐⭐⭐⭐ Très facile | ⭐⭐⭐ Nécessite migration |
| **Performance** | ⭐⭐⭐ Bonne | ⭐⭐⭐⭐⭐ Excellente |
| **Maintenance** | ⭐⭐⭐ Bonne | ⭐⭐⭐⭐ Très bonne |
| **Clarté structure** | ⭐⭐⭐ Moyenne | ⭐⭐⭐⭐⭐ Excellente |
| **Adaptabilité** | ⭐⭐⭐⭐⭐ Maximum | ⭐⭐⭐ Contrôlée |
| **Complexité requêtes** | ⭐⭐ Complexe (JSONB) | ⭐⭐⭐⭐⭐ Simple (SQL) |

### 5.2. Impact sur Convertigo

#### Architecture 1 (Unifiée)
- **Screens** : Génération dynamique depuis `schema_formulaire JSONB`
- **Sequences** : Requêtes JSONB avec opérateurs PostgreSQL
- **Formulaires** : Structure stockée dans JSONB, adaptable sans migration

#### Architecture 2 (Modulaire)
- **Screens** : Mapping direct colonnes ↔ champs formulaire
- **Sequences** : Requêtes SQL classiques, plus rapides
- **Formulaires** : Structure BDD = structure formulaire, explicite

### 5.3. Cas d'Usage Spécifiques

#### **Badge : Nouveau Collaborateur**

**Architecture 1** :
```sql
SELECT donnees->>'nom', donnees->>'prenom', donnees->'zones_acces'
FROM demande WHERE formulaire_id = 1 AND statut = 'en_validation';
```

**Architecture 2** :
```sql
SELECT nom_collaborateur, prenom_collaborateur, zones_acces
FROM badge WHERE type_badge = 'nouveau_collab' AND statut_code = 'en_validation';
```

#### **HS : Réalisation avec Préalable**

**Architecture 1** :
```sql
-- Lien via JSONB
SELECT d1.donnees->'reference_prealable', d2.*
FROM demande d1
JOIN demande d2 ON d2.donnees->>'demande_prealable_id' = d1.id::text;
```

**Architecture 2** :
```sql
-- Lien FK explicite
SELECT hsp.*, hsr.*
FROM heures_sup_prealable hsp
JOIN heures_sup_realisation hsr ON hsr.heures_sup_prealable_id = hsp.id;
```

### 5.4. Extensibilité : Ajout d'un Nouveau Formulaire

#### **Architecture 1** : Ajout "Temps Compensatoire"
1. Insertion dans `formulaire` avec `schema_formulaire JSONB`
2. Insertion d'une demande dans `demande` avec `donnees JSONB`
3. **Aucune migration BDD** ✅

#### **Architecture 2** : Ajout "Temps Compensatoire"
1. Création table `temps_compensatoire` avec colonnes dédiées
2. Insertion dans `formulaire`
3. Création workflow dans `workflow_etape`
4. **Migration BDD nécessaire** ⚠️

---

## 6. Recommandation

### 6.1. Analyse des Critères

**Performance** : Architecture 2 (Modulaire) ⭐⭐⭐⭐⭐
- Index sur colonnes = requêtes plus rapides
- Pas de parsing JSONB

**Extensibilité** : Architecture 1 (Unifiée) ⭐⭐⭐⭐⭐
- Nouveaux formulaires sans migration
- Flexibilité maximale

**Maintenance** : Architecture 2 (Modulaire) ⭐⭐⭐⭐
- Structure claire et documentée
- Contraintes SQL natives

**Simplicité développement** : Architecture 1 (Unifiée) ⭐⭐⭐⭐
- Moins de tables à gérer
- Modèle unique

### 6.2. Recommandation selon Contexte

#### 🟢 **Architecture 1 (Unifiée) - Recommandée si :**
- Priorité à l'extensibilité et au déploiement rapide
- Volume de formulaires très variable
- Équipe agile avec évolution fréquente
- Besoin de flexibilité maximale

#### 🟢 **Architecture 2 (Modulaire) - Recommandée si :**
- Priorité à la performance et requêtes complexes
- Volume de données important
- Formulaires bien définis et stables
- Besoin d'intégrité forte et traçabilité renforcée

### 6.3. Recommandation Finale

Pour l'Espace Unifié URSSAF, compte tenu de :

✅ **Volume prévisible de formulaires** : Badges (15 types) et HS sont identifiés, autres formulaires à venir (Parking, Mobilités, etc.)
✅ **Performance requise** : Tableaux de bord, recherches, filtres fréquents
✅ **Besoins métier complexes** : Workflows multi-étapes, validations croisées
✅ **Traçabilité essentielle** : Historique complet, audit

**➡️ Recommandation : Architecture 2 (Modulaire)** 

**Justification** :
- Performance optimale pour les tableaux de bord et recherches
- Structure claire facilitant la maintenance à long terme
- Intégrité forte pour les données critiques RH
- Possibilité d'ajouter de nouveaux formulaires par tables dédiées (Parking, Mobilités, etc.)

---

## 7. Plan d'Implémentation

### 7.1. Phase 1 : Infrastructure (Architecture Modulaire)
- ✅ Création tables fondamentales (agent, organisation, service)
- ✅ Tables domaines métier (badge, heures_sup_prealable, heures_sup_realisation)
- ✅ Tables transverses (statut, traceabilite, piece_jointe, validation_etape, workflow_etape)
- ✅ Triggers automatiques (traceabilité, dates)

### 7.2. Phase 2 : Formulaires Prioritaires
- ✅ Badge : Tous les types (15 formulaires)
- ✅ Heures Sup : Préalable + Réalisation
- ✅ Workflows complets avec étapes numérotées

### 7.3. Phase 3 : Intégration Convertigo
- ✅ Connecteur ANAIS (authentification)
- ✅ Sequences Convertigo pour CRUD
- ✅ Screens générés depuis structure BDD

### 7.4. Phase 4 : Extensibilité
- ✅ Ajout nouveaux formulaires : création tables dédiées
- ✅ Migration script pour nouveaux domaines
- ✅ Documentation des patterns d'ajout

---

## 8. Points de Discussion pour la Réunion

### 8.1. Questions Techniques

1. **Volume de données attendu** : Combien de demandes/jour ? Impact sur choix d'architecture ?
2. **Fréquence d'ajout de formulaires** : Souhaite-t-on pouvoir ajouter sans migration ?
3. **Priorité performance vs flexibilité** : Quel est le critère le plus important ?
4. **Équipe maintenance** : Formation nécessaire pour requêtes JSONB vs SQL classique ?

### 8.2. Questions Métier

1. **Évolution prévue** : Quels formulaires additionnels au-delà de Badges et HS ?
2. **Workflows complexes** : Y aura-t-il d'autres workflows multi-étapes à gérer ?
3. **Intégrations** : Besoins d'intégration avec d'autres systèmes (GTA, Canopée) ?
4. **Reporting** : Besoins de statistiques/rapports complexes ?

### 8.3. Décisions Attendues

- ✅ Validation de l'architecture choisie (Modulaire recommandée)
- ✅ Approbation du plan d'implémentation
- ✅ Calendrier de développement
- ✅ Points d'attention et risques identifiés

---

## 9. Annexes

### 9.1. Documentation Technique

- 📄 `ARCHITECTURE_UI_UX.md` : Architecture complète application
- 📄 `ANALYSE_FORMULAIRES_BADGES_HEURESUP.md` : Analyse détaillée Badges et HS
- 📄 `ARCHITECTURE_BDD_MODULAIRE.md` : Document technique architecture modulaire

### 9.2. Scripts SQL

- 📄 `script_bdd_modulaire.sql` : Script complet Architecture Modulaire (875 lignes)
  - Tables, types, triggers, données de test
  - Badges : 5 exemples avec workflows complets
  - HS : Préalable et Réalisation avec liens
  - Toutes les validations et traçabilités

- 📄 `script_bdd_badges_heuresup_complet.sql` : Script Architecture Unifiée (1311 lignes)
  - Structure alternative avec JSONB
  - Tous les formulaires et workflows
  - Données de test comparables

### 9.3. Schémas

- Diagrammes d'architecture disponibles sur demande
- Modèles de données détaillés
- Flux de workflows (Badges et HS)

---

## 10. Conclusion

Deux architectures ont été analysées et documentées :

1. **Architecture Unifiée** : Flexible, extensible, idéale pour évolution rapide
2. **Architecture Modulaire** : Performante, robuste, idéale pour production à long terme

**Recommandation : Architecture Modulaire** pour répondre aux besoins de performance, traçabilité et maintenance de l'Espace Unifié URSSAF.

Les deux solutions sont documentées avec scripts SQL complets, données de test et workflows détaillés.

---

**Préparé par** : Équipe Architecture  
**Date** : 2024  
**Version** : 1.0

