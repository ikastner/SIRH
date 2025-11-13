# Parcours Utilisateurs – Espace Unifié URSSAF

---

## Légende
- **Entrée site** : Point d’entrée de l’agent sur l’Espace Unifié.
- **Action** : Étapes réalisées par l’agent.
- **Decision** : Point de décision binaire (Oui/Non).

---

## 1. Recherche d’une Application

### Entrée site
- L’agent arrive sur l’Espace Unifié.

### Action
1. **L’agent cherche-t-il une application ?**
   - **Oui** :
     - **Est-ce une app interne à l’Espace Unifié ?**
       - **Oui** :
         - Recherche de l’application (dashboard/favoris/searchbar).
         - Ouverture de l’application.
       - **Non** :
         - Ouverture du lien externe de l’application.

---

## 2. Gestion des Formulaires @Urssaf

### Entrée site
- L’agent arrive sur l’Espace Unifié.

### Action
1. **L’agent cherche-t-il un formulaire ?**
   - **Oui** :
     - Recherche du formulaire (navigation, searchbar, favoris).
     - **Nouvelle demande ?**
       - **Oui** :
         - **Agent concerné** : Collaborateur ou lui-même.
         - Saisie de la nouvelle demande.
         - **Autres valideurs ?**
           - **Oui** :
             - Envoi → Manager ou RH ou PCS.
             - Notification au(x) destinataire(s).
           - **Non** :
             - Envoi → Destinataire unique (Manager ou RH ou PCS).
             - Notification au destinataire.
       - **Non** :
         - (Retour à la recherche ou autre action.)

---

## 3. Dashboard des Demandes en Cours

### Entrée site
- L’agent consulte le dashboard des demandes en cours.

### Action
1. **Consultation ou saisie ?**
   - **Consultation** :
     - Consultation de l’état de la demande.
   - **Saisie** :
     - Saisie de l’action à effectuer.
     - Validation de la saisie.
     - **Autres valideurs ?**
       - **Oui** :
         - Envoi → Manager ou RH ou PCS.
         - Notification aux destinataires.
       - **Non** :
         - Validation finale.

---

## 4. Tableau de Bord des Demandes

### Entrée site
- L’agent consulte le Tableau de Bord des demandes.

### Action
1. **Demande en cours ?**
   - **Oui** :
     - Consultation du TDB.
     - **Consultation ou saisie ?**
       - **Consultation** :
         - Consultation de l’état de la demande.
       - **Saisie** :
         - Saisie de l’action à effectuer.
         - Validation de la saisie.
         - **Autres valideurs ?**
           - **Oui** :
             - Envoi → Manager ou RH ou PCS.
             - Notification aux destinataires.
           - **Non** :
             - Validation finale.

---

## 5. Dossiers / Documents

### Entrée site
- L’agent cherche un dossier ou un document.

### Action
1. **L’agent cherche-t-il une application liée aux dossiers/documents ?**
   - **Oui** :
     - **Est-ce une app interne à l’Espace Unifié ?**
       - **Oui** :
         - Recherche de l’application (dashboard/favoris/searchbar).
         - Ouverture de l’application.
       - **Non** :
         - Ouverture du lien externe de l’application.

---

## 6. Suivi par Agent

### Entrée site
- L’agent recherche un agent spécifique.

### Action
1. **Demandes en cours pour cet agent ?**
   - **Oui** :
     - Consultation de la demande.
     - **Consultation ou saisie ?**
       - **Consultation** :
         - Consultation de l’état de la demande.
       - **Saisie** :
         - Saisie de l’action à effectuer.
         - Validation de la saisie.
         - **Autres valideurs ?**
           - **Oui** :
             - Envoi → RH ou PCS ou Collaborateur.
             - Notification aux destinataires.
           - **Non** :
             - Validation finale.

---

## 7. Validation des Demandes

### Entrée site
- L’agent valide une demande (Manager, RH, PCS, etc.).

### Action
1. **Validation de la saisie.**
   - **Autres valideurs ?**
     - **Oui** :
       - Envoi → Prochain valideur (RH, PCS, Collaborateur, etc.).
       - Notification aux destinataires.
     - **Non** :
       - Validation finale et clôture de la demande.

---
