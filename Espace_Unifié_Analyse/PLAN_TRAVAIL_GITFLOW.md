# Plan de Travail - Espace Unifié URSSAF
## Stratégie GitFlow avec Convertigo

**Projet** : Espace Unifié URSSAF  
**Plateforme** : Convertigo Low Code Studio  
**Base de données** : PostgreSQL (Architecture Modulaire)  
**Authentification** : ANAIS

---

## 1. Stratégie GitFlow

### 1.1. Branches Principales

```
main (production)
  ├── production-ready code uniquement
  ├── tags pour versions déployées
  └── protection stricte (merge uniquement via release)

develop (développement)
  ├── intégration des features
  ├── environnement de développement
  └── branche de travail principale
```

### 1.2. Branches de Support

```
feature/*          → Nouvelles fonctionnalités
hotfix/*           → Corrections urgentes production
release/*          → Préparation release
support/*          → Support maintenance
```

### 1.3. Flux GitFlow Convertigo

```
                    feature/authentification
                           │
                           ├─ develop ────────────────┐
                           │                           │
                           │                    release/v1.0.0
                           │                           │
                    feature/formulaires         ───────┤
                           │                           │
main ──────────────────────┼──────────────────────────┴─ main (v1.0.0)
     │                      │
     │                      │
     └── hotfix/critical ───┘
```

---

## 2. Structure des Branches Détailée

### 2.1. Branche `main`
- **Rôle** : Code en production
- **Protection** : Merge uniquement depuis `release/*` ou `hotfix/*`
- **Tags** : Versioning sémantique (v1.0.0, v1.1.0, etc.)
- **Deployment** : Automatique vers environnement PROD

### 2.2. Branche `develop`
- **Rôle** : Intégration continue des features
- **Source** : Toutes les `feature/*` merge ici
- **Environnement** : DEV/INT
- **Tests** : Automatiques avant merge

### 2.3. Branches `feature/*`
- **Convention** : `feature/description-courte` (kebab-case)
- **Exemples** :
  - `feature/authentification-anais`
  - `feature/formulaire-heures-sup-prealable`
  - `feature/formulaire-badge-collab`
  - `feature/dashboard-manager`
  - `feature/notifications-centre`
  - `feature/dossier-agent`
- **Durée** : Temporaire, supprimée après merge
- **Base** : Branche depuis `develop`

### 2.4. Branches `release/*`
- **Convention** : `release/v1.0.0` (versioning sémantique)
- **Exemples** :
  - `release/v1.0.0-mvp`
  - `release/v1.1.0-badges`
  - `release/v1.2.0-heures-sup`
- **Rôle** : Finalisation avant production
- **Base** : Branche depuis `develop`
- **Finalisation** : Merge dans `main` + tag + merge retour dans `develop`

### 2.5. Branches `hotfix/*`
- **Convention** : `hotfix/description-bug` ou `hotfix/v1.0.1`
- **Exemples** :
  - `hotfix/correction-export-pdf`
  - `hotfix/securite-validation`
  - `hotfix/v1.0.1`
- **Rôle** : Corrections critiques production
- **Base** : Branche depuis `main`
- **Finalisation** : Merge dans `main` + `develop`

### 2.6. Branches `support/*`
- **Convention** : `support/maintenance-v1.x`
- **Rôle** : Maintenance version spécifique
- **Base** : Branche depuis tag spécifique

---

## 3. Plan de Travail Phasé

### Phase 1 : Infrastructure et Fondations (Sprint 1-2)

#### Sprint 1 : Setup Projet
**Durée** : 2 semaines

| Tâche | Branche | Priorité | Description |
|-------|---------|----------|-------------|
| Setup projet Convertigo | `feature/setup-projet` | P0 | Initialisation projet, structure dossiers |
| Configuration BDD | `feature/config-bdd` | P0 | Création BDD, scripts SQL, connexion |
| Architecture projet | `feature/architecture-base` | P0 | Structure Convertigo (screens, sequences) |
| Authentification ANAIS | `feature/authentification-anais` | P0 | Connecteur ANAIS, gestion session |
| Gestion rôles | `feature/gestion-roles` | P0 | RBAC via ANAIS, contrôle accès |

**Livrables Sprint 1** :
- ✅ Projet Convertigo initialisé
- ✅ BDD créée et accessible
- ✅ Authentification ANAIS fonctionnelle
- ✅ Structure base projet prête

**Merge** : Toutes les features → `develop`

#### Sprint 2 : Tables Transverses et Workflow
**Durée** : 2 semaines

| Tâche | Branche | Priorité | Description |
|-------|---------|----------|-------------|
| Tables statut/workflow | `feature/tables-transverses` | P0 | Implémentation tables statut, workflow_etape |
| Séquence traceabilité | `feature/traceabilite` | P0 | Triggers et séquences traçabilité |
| Séquence validations | `feature/validations-workflow` | P0 | Gestion workflow multi-étapes |
| Notifications base | `feature/notifications-base` | P1 | Système notifications de base |

**Livrables Sprint 2** :
- ✅ Tables transverses opérationnelles
- ✅ Workflow engine fonctionnel
- ✅ Système notifications basique

**Merge** : Toutes les features → `develop`

---

### Phase 2 : Formulaires Badges (Sprint 3-5)

#### Sprint 3 : Badges Collaborateurs (Partie 1)
**Durée** : 2 semaines

| Tâche | Branche | Priorité | Description |
|-------|---------|----------|-------------|
| Table badge | `feature/table-badge` | P0 | Création table badge avec tous champs |
| Formulaire nouveau collab | `feature/badge-nouveau-collab` | P0 | Screen + séquence création |
| Formulaire départ collab | `feature/badge-depart-collab` | P0 | Screen + séquence départ |
| Workflow badges collab | `feature/workflow-badge-collab` | P0 | Workflow Manager → PCS |
| Tests badges collab | `feature/tests-badge-collab` | P1 | Tests fonctionnels |

**Livrables Sprint 3** :
- ✅ 2 formulaires badges opérationnels
- ✅ Workflow validation complet

#### Sprint 4 : Badges Collaborateurs (Partie 2) + Personnel
**Durée** : 2 semaines

| Tâche | Branche | Priorité | Description |
|-------|---------|----------|-------------|
| Badge collab perdu | `feature/badge-collab-perdu` | P0 | Formulaire badge perdu |
| Badge collab HS | `feature/badge-collab-hs` | P0 | Formulaire badge HS |
| Badge collab accès spécifique | `feature/badge-collab-acces-spec` | P0 | Accès spécifique |
| Badge personnel | `feature/badge-perso` | P1 | Formulaires perso (standard, oublié, désactivation) |
| Dashboard badges collab | `feature/dashboard-badge-collab` | P1 | Vue collaborateur |

**Livrables Sprint 4** :
- ✅ Tous badges collaborateurs
- ✅ Badges personnel
- ✅ Dashboard collaborateur

#### Sprint 5 : Badges Prestataires + Autre
**Durée** : 2 semaines

| Tâche | Branche | Priorité | Description |
|-------|---------|----------|-------------|
| Badge prestataire nouveau | `feature/badge-presta-new` | P0 | Formulaire nouveau prestataire |
| Badge prestataire autres | `feature/badge-presta-autres` | P0 | Renew, départ, perdu, HS, accès spec |
| Badge autre spécifique | `feature/badge-autre-specifique` | P1 | Formulaires cas particuliers |
| Dashboard manager badges | `feature/dashboard-badge-manager` | P1 | Vue manager avec validations |
| Dashboard RH badges | `feature/dashboard-badge-rh` | P1 | Vue RH globale |

**Livrables Sprint 5** :
- ✅ Tous types badges (15 formulaires)
- ✅ Dashboards complets
- ✅ Release v1.0.0-badges préparée

**Release** : `release/v1.0.0-badges`
- Finalisation tests
- Documentation
- Merge → `main` + tag `v1.0.0`

---

### Phase 3 : Formulaires Heures Sup (Sprint 6-8)

#### Sprint 6 : Heures Sup Préalable
**Durée** : 2 semaines

| Tâche | Branche | Priorité | Description |
|-------|---------|----------|-------------|
| Table heures_sup_prealable | `feature/table-hs-prealable` | P0 | Création table avec champs identifiés |
| Formulaire préalable | `feature/hs-prealable-formulaire` | P0 | Screen saisie préalable |
| Workflow préalable | `feature/workflow-hs-prealable` | P0 | Workflow Manager → RH |
| Séquence création préalable | `feature/sequence-hs-prealable` | P0 | CRUD préalable |
| Validations préalable | `feature/validations-hs-prealable` | P0 | Validation Manager + RH |
| Dashboard préalable collab | `feature/dashboard-hs-prealable-collab` | P1 | Vue collaborateur |

**Livrables Sprint 6** :
- ✅ Formulaire préalable complet
- ✅ Workflow validation préalable
- ✅ Dashboard collaborateur

#### Sprint 7 : Heures Sup Réalisation (Partie 1)
**Durée** : 2 semaines

| Tâche | Branche | Priorité | Description |
|-------|---------|----------|-------------|
| Table heures_sup_realisation | `feature/table-hs-realisation` | P0 | Création table avec tous champs |
| Lien préalable ↔ réalisation | `feature/lien-prealable-realisation` | P0 | FK et logique de lien |
| Formulaire réalisation | `feature/hs-realisation-formulaire` | P0 | Screen saisie réalisation |
| Saisie heures détaillées | `feature/saisie-heures-detaillees` | P0 | Interface saisie par jour |
| Pointages GTA | `feature/pointages-gta` | P0 | Intégration/saisie pointages GTA |
| Calcul écarts | `feature/calcul-ecarts-prealable` | P0 | Calcul auto écarts vs préalable |

**Livrables Sprint 7** :
- ✅ Formulaire réalisation avec lien préalable
- ✅ Saisie heures détaillées
- ✅ Gestion pointages GTA

#### Sprint 8 : Heures Sup Réalisation (Partie 2) + Pointage RH
**Durée** : 2 semaines

| Tâche | Branche | Priorité | Description |
|-------|---------|----------|-------------|
| Workflow réalisation | `feature/workflow-hs-realisation` | P0 | Workflow Manager → RH → Pointage RH |
| Validation Manager réalisation | `feature/validation-manager-hs-real` | P0 | Validation Manager avec vérifications |
| Validation RH réalisation | `feature/validation-rh-hs-real` | P0 | Validation RH |
| Pointage RH | `feature/pointage-rh` | P0 | Interface pointage RH final |
| Réconciliation GTA | `feature/reconciliation-gta` | P0 | Réconciliation pointages officiels |
| Cas sans préalable | `feature/hs-sans-prealable` | P1 | Gestion cas exceptionnel |
| Dashboard réalisation | `feature/dashboard-hs-realisation` | P1 | Dashboards complets |

**Livrables Sprint 8** :
- ✅ Workflow réalisation complet (6 étapes)
- ✅ Pointage RH opérationnel
- ✅ Dashboards réalisation

**Release** : `release/v1.1.0-heures-sup`
- Finalisation tests
- Documentation
- Merge → `main` + tag `v1.1.0`

---

### Phase 4 : Fonctionnalités Transverses (Sprint 9-10)

#### Sprint 9 : Notifications et Recherche
**Durée** : 2 semaines

| Tâche | Branche | Priorité | Description |
|-------|---------|----------|-------------|
| Centre notifications | `feature/centre-notifications` | P0 | Interface notifications complète |
| Notifications workflow | `feature/notifications-workflow` | P0 | Notifications automatiques workflow |
| Préférences notifications | `feature/preferences-notifications` | P1 | Configuration utilisateur |
| Recherche globale | `feature/recherche-globale` | P0 | Recherche agents, demandes, formulaires |
| Filtres avancés | `feature/filtres-avances` | P1 | Filtres par statut, dates, etc. |

**Livrables Sprint 9** :
- ✅ Système notifications complet
- ✅ Recherche globale opérationnelle

#### Sprint 10 : Dossier Agent et Favoris
**Durée** : 2 semaines

| Tâche | Branche | Priorité | Description |
|-------|---------|----------|-------------|
| Dossier agent vue | `feature/dossier-agent-vue` | P0 | Table vue consolidée |
| Interface dossier agent | `feature/dossier-agent-ui` | P0 | Screen dossier agent |
| Historique complet | `feature/historique-complet` | P0 | Visualisation historique demandes |
| Favoris | `feature/favoris` | P1 | Système favoris formulaires/apps |
| Export PDF/Excel | `feature/export-donnees` | P1 | Export dossiers, tableaux |

**Livrables Sprint 10** :
- ✅ Dossier agent consolidé
- ✅ Favoris fonctionnels

**Release** : `release/v1.2.0-transversal`
- Finalisation
- Merge → `main` + tag `v1.2.0`

---

### Phase 5 : Applications Externes et Finitions (Sprint 11-12)

#### Sprint 11 : Applications Externes
**Durée** : 2 semaines

| Tâche | Branche | Priorité | Description |
|-------|---------|----------|-------------|
| Catalogue apps externes | `feature/apps-externes-catalogue` | P1 | Gestion catalogue apps |
| Intégration O'Buro | `feature/app-oburo` | P1 | Intégration O'Buro |
| Intégration autres apps | `feature/apps-autres` | P2 | ODAM, Reporting, SecurSafe |
| Suivi usage apps | `feature/suivi-usage-apps` | P2 | Statistiques usage |

**Livrables Sprint 11** :
- ✅ Catalogue apps externes
- ✅ Intégrations principales

#### Sprint 12 : Optimisations et Documentation
**Durée** : 2 semaines

| Tâche | Branche | Priorité | Description |
|-------|---------|----------|-------------|
| Optimisations performance | `feature/optimisations` | P1 | Optimisations requêtes, cache |
| Tests E2E | `feature/tests-e2e` | P1 | Tests end-to-end complets |
| Documentation utilisateur | `feature/doc-utilisateur` | P1 | Guides utilisateur |
| Documentation technique | `feature/doc-technique` | P1 | Documentation développeur |
| Formation équipe | `feature/formation` | P1 | Sessions formation |

**Livrables Sprint 12** :
- ✅ Application optimisée
- ✅ Documentation complète

**Release Finale** : `release/v1.3.0-mvp`
- Tests complets
- Documentation finale
- Merge → `main` + tag `v1.3.0`

---

## 4. Conventions de Nommage

### 4.1. Branches

**Format** : `type/description-courte`

**Types** :
- `feature/` : Nouvelles fonctionnalités
- `hotfix/` : Corrections urgentes
- `release/` : Préparation release
- `support/` : Maintenance

**Exemples valides** :
- ✅ `feature/authentification-anais`
- ✅ `feature/badge-nouveau-collab`
- ✅ `feature/hs-prealable-formulaire`
- ✅ `hotfix/correction-export-pdf`
- ✅ `release/v1.0.0-badges`

**Exemples invalides** :
- ❌ `feature/Authentification` (majuscules)
- ❌ `feature/authentification` (trop vague)
- ❌ `feature/auth_anais` (underscore)

### 4.2. Commits

**Format** : `type(scope): description courte`

**Types** :
- `feat` : Nouvelle fonctionnalité
- `fix` : Correction bug
- `docs` : Documentation
- `style` : Formatage (pas de changement logique)
- `refactor` : Refactoring code
- `test` : Ajout/modification tests
- `chore` : Maintenance (dépendances, config)

**Scopes** :
- `auth` : Authentification
- `badge` : Formulaires badges
- `hs` : Heures supplémentaires
- `db` : Base de données
- `ui` : Interface utilisateur
- `workflow` : Workflow et validations

**Exemples** :
```
feat(auth): intégration connecteur ANAIS
fix(badge): correction calcul durée badge temporaire
docs(db): ajout documentation table badge
refactor(hs): optimisation séquence création réalisation
test(workflow): ajout tests validation manager
chore(deps): mise à jour dépendances Convertigo
```

### 4.3. Tags de Version

**Format** : `vMAJOR.MINOR.PATCH[-LABEL]`

**Semantic Versioning** :
- `MAJOR` : Changements incompatibles API
- `MINOR` : Nouvelles fonctionnalités compatibles
- `PATCH` : Corrections bugs compatibles

**Labels** :
- `-alpha` : Version alpha
- `-beta` : Version beta
- `-rc1` : Release candidate
- Sans label : Version stable

**Exemples** :
- `v1.0.0` : Première version stable
- `v1.0.1` : Patch version 1.0.0
- `v1.1.0` : Nouvelle fonctionnalité (Heures Sup)
- `v1.1.0-beta` : Version beta 1.1.0
- `v2.0.0` : Version majeure (breaking changes)

---

## 5. Processus de Développement

### 5.1. Création d'une Feature

```bash
# 1. S'assurer que develop est à jour
git checkout develop
git pull origin develop

# 2. Créer et basculer sur la feature branch
git checkout -b feature/description-fonctionnalite

# 3. Développement
# ... travail sur Convertigo ...

# 4. Commit régulier
git add .
git commit -m "feat(scope): description changement"

# 5. Push vers remote
git push origin feature/description-fonctionnalite

# 6. Créer Pull Request vers develop
# Via interface Git (GitLab/GitHub) ou Convertigo
```

### 5.2. Merge dans Develop

**Conditions** :
- ✅ Code revu par au moins 1 autre développeur
- ✅ Tests passent (si configurés)
- ✅ Pas de conflits
- ✅ Build Convertigo réussi

**Processus** :
```bash
# Via Pull Request (recommandé)
# 1. Créer PR feature/xxx → develop
# 2. Review code
# 3. Approbation
# 4. Merge via interface

# Ou manuellement (si nécessaire)
git checkout develop
git pull origin develop
git merge --no-ff feature/description-fonctionnalite
git push origin develop

# Supprimer feature branch
git branch -d feature/description-fonctionnalite
git push origin --delete feature/description-fonctionnalite
```

### 5.3. Création d'une Release

```bash
# 1. Préparer release depuis develop
git checkout develop
git pull origin develop

# 2. Créer branche release
git checkout -b release/v1.0.0

# 3. Finalisation release
# - Tests finaux
# - Documentation
# - Version dans Convertigo
# - Changelog

# 4. Merge dans main
git checkout main
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "Release v1.0.0: Formulaires Badges"
git push origin main
git push origin v1.0.0

# 5. Merge retour dans develop
git checkout develop
git merge --no-ff release/v1.0.0
git push origin develop

# 6. Supprimer branche release
git branch -d release/v1.0.0
git push origin --delete release/v1.0.0
```

### 5.4. Hotfix Production

```bash
# 1. Créer hotfix depuis main
git checkout main
git pull origin main
git checkout -b hotfix/correction-bug

# 2. Correction
# ... travail ...

# 3. Commit et tag
git add .
git commit -m "fix(scope): correction bug critique"
git push origin hotfix/correction-bug

# 4. Merge dans main
git checkout main
git merge --no-ff hotfix/correction-bug
git tag -a v1.0.1 -m "Hotfix v1.0.1: correction bug"
git push origin main
git push origin v1.0.1

# 5. Merge dans develop
git checkout develop
git merge --no-ff hotfix/correction-bug
git push origin develop

# 6. Supprimer hotfix branch
git branch -d hotfix/correction-bug
```

---

## 6. Checklist par Feature

### Avant de créer une Feature
- [ ] Vérifier que `develop` est à jour
- [ ] Créer branche avec nommage conforme
- [ ] Mettre à jour le backlog/projet

### Pendant le Développement
- [ ] Commits réguliers avec messages clairs
- [ ] Code conforme aux standards
- [ ] Tests unitaires (si applicable)
- [ ] Documentation inline (si nécessaire)

### Avant Merge dans Develop
- [ ] Tous les tests passent
- [ ] Code revu par un pair
- [ ] Pas de conflits
- [ ] Build Convertigo réussi
- [ ] Fonctionnalité testée manuellement
- [ ] Documentation mise à jour (si changement important)

### Avant Release
- [ ] Tous les tests E2E passent
- [ ] Documentation utilisateur complète
- [ ] Changelog mis à jour
- [ ] Version taggée correctement
- [ ] Validation avec stakeholders
- [ ] Plan de déploiement préparé

---

## 7. Intégration Continue (CI/CD)

### 7.1. Pipeline GitLab/GitHub (si configuré)

```yaml
# .gitlab-ci.yml exemple
stages:
  - build
  - test
  - deploy-dev
  - deploy-prod

build:
  stage: build
  script:
    - echo "Build Convertigo projet"
  
test:
  stage: test
  script:
    - echo "Tests automatiques"
  
deploy-dev:
  stage: deploy-dev
  only:
    - develop
  script:
    - echo "Déploiement DEV"
  
deploy-prod:
  stage: deploy-prod
  only:
    - main
  script:
    - echo "Déploiement PROD"
```

### 7.2. Déploiement Environnements

| Environnement | Branche | Déploiement | Accès |
|--------------|---------|-------------|-------|
| **DEV** | `develop` | Automatique (push) | Équipe dev |
| **INT** | `develop` | Automatique (merge) | Équipe dev + testeurs |
| **PRE-PROD** | `release/*` | Manuel | Équipe projet |
| **PROD** | `main` | Manuel (validation) | Production |

---

## 8. Gestion des Conflits

### 8.1. Prévention
- Pull régulier de `develop`
- Communication avec l'équipe
- Partage des zones de travail

### 8.2. Résolution
```bash
# Si conflit lors merge
git checkout feature/ma-feature
git pull origin develop

# Résoudre conflits manuellement
# ... édition fichiers ...

git add .
git commit -m "fix: résolution conflits merge develop"
git push origin feature/ma-feature
```

---

## 9. Outils et Ressources

### 9.1. Convertigo Spécifique
- **Export/Import projets** : Sauvegarde régulière
- **Versions** : Gestion via Convertigo Studio
- **Déploiement** : Export → Import environnement

### 9.2. Documentation
- Changelog : `CHANGELOG.md`
- Documentation technique : `docs/`
- Guide utilisateur : `docs/user-guide/`

---

## 10. Calendrier de Développement

### Vue d'Ensemble (12 Sprints = ~6 mois)

```
Mois 1-2  : Phase 1 (Infrastructure) + Phase 2.1-2.2 (Badges début)
Mois 3    : Phase 2.3 (Badges fin) → Release v1.0.0
Mois 4    : Phase 3.1-3.2 (HS Préalable + Réalisation début)
Mois 5    : Phase 3.3 (HS Réalisation fin) → Release v1.1.0
Mois 6    : Phase 4-5 (Transversal + Finitions) → Release v1.3.0 MVP
```

### Jalons Principaux
- **Jalon 1** (Fin Sprint 2) : Infrastructure prête
- **Jalon 2** (Fin Sprint 5) : Release v1.0.0 Badges
- **Jalon 3** (Fin Sprint 8) : Release v1.1.0 Heures Sup
- **Jalon 4** (Fin Sprint 12) : Release v1.3.0 MVP Complet

---

## 11. Responsabilités

### Développeur Feature
- Créer branche `feature/*`
- Développer fonctionnalité
- Tests et documentation
- Créer Pull Request

### Tech Lead / Review
- Review code
- Validation architecture
- Merge dans `develop`

### Release Manager
- Créer branche `release/*`
- Finalisation release
- Coordination déploiement
- Tagging versions

### Hotfix Manager
- Créer branche `hotfix/*`
- Correction urgente
- Validation et déploiement

---

**Document créé le** : 2024  
**Version** : 1.0  
**Dernière mise à jour** : À compléter

