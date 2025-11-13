# Workspace SIRH - Espace Unifie URSSAF

Ce workspace Convertigo regroupe l'ensemble des projets nécessaires pour construire
l'Espace Unifie SIRH destine aux agents URSSAF. Il fournit un portail web unique
permettant la gestion des demandes RH (badges, heures supplementaires, etc.) a
partir d'une interface moderne et responsive.

## Structure des projets

- `EspaceUnifie_SIRH` : application principale (shell) qui orchestre la navigation,
  le layout et l'integration des modules metier.
- `lib_component_SIRH` : bibliotheque de composants UI reutilisables servant de
  design system pour tous les projets Convertigo du workspace.
- `FRM_DemandeBadge_SIRH` : module metier dedie aux demandes de badges avec un
  tableau de bord complet fonde sur les composants de la librairie.
- `FRM_HeuresSupp_SIRH` : module metier pour la saisie et la validation des heures
  supplementaires, aujourd'hui au stade de squelette fonctionnel.
- Dossiers `Espace_Unifie_Front` et `Espace_Unifie_Analyse` : maquettes, guides et
  analyses qui documentent l'architecture cible et les choix UI/UX.

## Architecture fonctionnelle simplifiee

1. **Utilisateurs** : agents URSSAF authentifies via ANAIS (SSO + roles).
2. **Frontend Convertigo** :
   - Application chapeau `EspaceUnifie_SIRH`.
   - Modules metier (badges, heures supp., autres a venir).
   - Design system `lib_component_SIRH`.
3. **Backend Convertigo** :
   - Connecteurs SQL vers la base SIRH.
   - Sequences pour la logique metier (Badge, HeureSup, etc.).
4. **Base de donnees PostgreSQL** : tables `demande_badge`, `heures_supplementaires`,
   `agent`, `workflow`, ...
5. **Authentification ANAIS** : gestion des roles Agent, Manager, RH.

## Statut actuel (extrait)

- `EspaceUnifie_SIRH` : structure complete avec layout, navigation et modales.
- `lib_component_SIRH` : 11 composants dashboard + 5 composants formulaire
  reutilisables.
- `FRM_DemandeBadge_SIRH` : tableau de bord badge operationnel.
- `FRM_HeuresSupp_SIRH` : structure initiee, logique en cours d'implémentation.
- Connecteurs BDD et integration ANAIS : a configurer.

## Prochaines etapes recommandees

1. Configurer les connecteurs SQL vers la base SIRH.
2. Implementer/brancher les sequences Convertigo backend.
3. Integrer l'authentification ANAIS (SSO + roles).
4. Completer le module Heures Supp (formulaires + validation + dashboard).
5. Ajouter les jeux de tests (unitaires et integration).
6. Deployer en environnement de recette pour validation utilisateur.

## Documentation complementaire

- `PRESENTATION_NOTION_WORKSPACE_SIRH_SAFE.md` : synthese fonctionnelle et
  architecture globale.
- `ARCHITECTURE_MERMAID.md` : diagramme textuel de l'architecture.
- Guides locaux dans chaque dossier (`GUIDE_CREATION_PAGE.md`, `GUIDE_DASHBOARD_COMPONENTS.md`,
  etc.) pour les details d'implementation.

Ces README derivent de la presentation Notion referencee ci-dessus afin de rendre
la documentation directement accessible depuis le depot.

