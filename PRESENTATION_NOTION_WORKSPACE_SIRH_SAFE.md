# 🏢 Workspace SIRH - Espace Unifié URSSAF

**Introduction** : Ce workspace regroupe l'ensemble des projets Convertigo pour construire l'Espace Unifié SIRH de l'URSSAF. Il s'agit d'un portail centralisé permettant aux agents de gérer leurs demandes RH (badges, heures supplémentaires, etc.) via une interface web unifiée et moderne.

---

## 📦 Liste des projets

### 1. **EspaceUnifie_SIRH**

**Fonction principale** : Application principale et point d'entrée pour les utilisateurs

**Rôle** : Frontend - Application web complète

**Description** :
- C'est l'application "chapeau" qui orchestre l'ensemble
- Contient les pages principales (Accueil, Applications, Tableau de bord)
- Intègre le layout global (navigation, modales, footer)
- Référence et utilise les autres projets (FRM_DemandeBadge_SIRH, lib_component_SIRH)

**Convertigo** :
- **Pages** : TDB, Applications, Page, Page1
- **Composants** : navbar, footer, chatbotModal, notificationsModal, appLayoutComplete
- **Références** : FRM_DemandeBadge_SIRH (modules métier)

---

### 2. **lib_component_SIRH**

**Fonction principale** : Bibliothèque de composants UI réutilisables

**Rôle** : Frontend - Design System / Librairie de composants

**Description** :
- Contient tous les composants atomiques réutilisables (briques Lego)
- Permet de construire rapidement des interfaces cohérentes
- Utilisé par tous les autres projets pour garantir l'uniformité visuelle

**Convertigo** :
- **Composants Dashboard** : dashboardHeader, dashboardTable, dashboardFilters, roleTabs, statusBadge
- **Composants Form** : formHeader, formInput, recipientButtons, motifButtons, warningMessage
- **Avantage** : Un composant modifié ici = modification automatique partout où il est utilisé

---

### 3. **FRM_DemandeBadge_SIRH**

**Fonction principale** : Module de gestion des demandes de badges

**Rôle** : Frontend - Module métier Badge

**Description** :
- Contient la logique métier spécifique aux demandes de badges
- Assemble les composants de lib_component_SIRH pour créer des vues complètes
- Composant TDB (Tableau de Bord) pour visualiser toutes les demandes de badges

**Convertigo** :
- **Composants métier** : TDB (Tableau de bord complet assemblant dashboardHeader, roleTabs, dashboardFilters, dashboardTable)
- **Références** : lib_component_SIRH (pour utiliser les briques UI)
- **Connecteur SQL** : void (à remplacer par le connecteur réel vers la BDD)

---

### 4. **FRM_HeuresSupp_SIRH**

**Fonction principale** : Module de gestion des heures supplémentaires

**Rôle** : Frontend - Module métier Heures Supplémentaires

**Description** :
- Contient la logique métier pour la saisie et validation des heures supplémentaires
- Formulaire de saisie et tableau de bord des demandes
- Prêt à recevoir les composants de lib_component_SIRH

**Convertigo** :
- **Pages** : Page (formulaire de saisie des heures)
- **Connecteur SQL** : void (à remplacer)
- **Statut** : En préparation, structure de base créée

---

## 🏗️ Schéma d'architecture simplifié

**Flux de l'architecture (de haut en bas) :**

🔹 **UTILISATEURS (Agents URSSAF)**
   ⬇️

🔹 **FRONTEND - Application Web**
   - **EspaceUnifie_SIRH** → Pages (Accueil, Applications, TDB) + Layout (Navbar, Footer, Modales)
   - **Modules Métier** → FRM_DemandeBadge_SIRH, FRM_HeuresSupp_SIRH (Logique + Vues spécifiques)
   - **Design System** → lib_component_SIRH (Composants réutilisables)
   ⬇️

🔹 **BACKEND - Convertigo**
   - **Connecteurs SQL** → Connecteur BDD SIRH + Transactions SQL (CRUD)
   - **Séquences (Business Logic)** → Badge, HeureSup, User management
   ⬇️

🔹 **BASE DE DONNÉES - PostgreSQL**
   - Tables : demande_badge, heures_supplementaires, agent, workflow
   ⬇️

🔹 **AUTHENTIFICATION - ANAIS**
   - SSO + Gestion des rôles (Agent, Manager, RH) + Permissions

---

## 🎯 Résumé - Points clés

### ✅ **Architecture modulaire et scalable**
- 1 application principale (EspaceUnifie_SIRH)
- 1 bibliothèque de composants réutilisables (lib_component_SIRH)
- N modules métier indépendants (Badge, Heures Sup, Parking...)
- Chaque module peut être développé, testé et déployé séparément

### 🎨 **Design System unifié**
- Tous les projets utilisent les mêmes composants visuels
- Garantit une expérience utilisateur cohérente
- Modification centralisée : 1 changement = effet partout
- Gain de temps de développement significatif

### 🔧 **Technologie Low-Code Convertigo**
- Développement visuel sans coder (ou peu)
- Génération automatique de code Angular/Ionic
- Connecteurs natifs vers bases de données
- Séquences pour la logique métier réutilisable

### 🚀 **Prêt pour l'évolution**
- Ajout de nouveaux modules facile (copier-coller la structure)
- Composants réutilisables = développement rapide
- Architecture documentée et claire
- Stack moderne (Angular, Ionic, Responsive)

### 📊 **Statut actuel**
- ✅ EspaceUnifie_SIRH : Structure complète avec layout et navigation
- ✅ lib_component_SIRH : 11 composants dashboard + 5 composants formulaire
- ✅ FRM_DemandeBadge_SIRH : Tableau de bord badges complet et fonctionnel
- 🔄 FRM_HeuresSupp_SIRH : Structure créée, en cours de développement
- ⏳ Connexion BDD : Connecteurs SQL à configurer
- ⏳ Authentification ANAIS : À intégrer

---

## 📈 Prochaines étapes

1. **Configurer les connecteurs SQL** vers la base de données SIRH
2. **Implémenter les séquences Convertigo** (logique métier backend)
3. **Intégrer l'authentification ANAIS** (SSO + gestion des rôles)
4. **Compléter le module Heures Supplémentaires** (formulaires + validation)
5. **Ajouter les tests** (unitaires + intégration)
6. **Déployer en environnement de recette** pour validation utilisateurs

---

**Documentation technique complète disponible** dans chaque projet (fichiers README.md et guides)

**Architecture validée** : Modulaire, maintenable, évolutive ✅

