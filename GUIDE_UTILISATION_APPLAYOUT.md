# Guide d'utilisation du composant appLayout

## 📦 Composants créés

### 1. **appLayout** - Composant principal
Englobe toute la structure de navigation et d'interface :
- ✅ Sidebar de navigation (navbar)
- ✅ Section formulaires (toggle via icône Applications)
- ✅ Modal chatbot (toggle via icône chatbot)
- ✅ Modal notifications (toggle via icône notifications)
- ✅ Sidebar favoris (toggle automatique, toujours visible)
- ✅ Tous les toggles CSS (checkboxes)
- ✅ Tout le CSS pour les interactions

### 2. **favoris** - Sidebar des favoris
Composant indépendant avec :
- Liste des applications favorites (O'Buro, HeureSup, SecurSafe)
- Bouton toggle pour réduire/agrandir
- Bouton "Sélectionner tout"
- CSS complet intégré

### 3. **navbar**, **chatbotModal**, **notificationsModal**, **footer**
Composants réutilisables déjà créés.

---

## 🚀 Utilisation dans une page

### Option 1 : Utiliser appLayout (RECOMMANDÉ)

Dans votre page, ajoutez simplement :

```yaml
↓UseAppLayout [ngx.components.UIUseShared-XXXXX]: 
  sharedcomponent: EspaceUnifie_SIRH.Application.NgxApp.appLayout

↓mainContent [ngx.components.UIElement-XXXXX]: 
  tagName: main
  ↓Attr [ngx.components.UIAttribute-XXXXX]: 
    attrName: class
    attrValue: 
      - xmlizable: 
        - ↑classname: com.twinsoft.convertigo.beans.ngx.components.MobileSmartSourceType
        - MobileSmartSourceType: plain:main-content
  # Votre contenu personnalisé ici
  ↓h1 [ngx.components.UIElement-XXXXX]: 
    tagName: h1
    ↓Text [ngx.components.UIText-XXXXX]: 
      textValue: 
        - xmlizable: 
          - ↑classname: com.twinsoft.convertigo.beans.ngx.components.MobileSmartSourceType
          - MobileSmartSourceType: plain:Ma Page

↓UseFooter [ngx.components.UIUseShared-XXXXX]: 
  sharedcomponent: EspaceUnifie_SIRH.Application.NgxApp.footer
```

### CSS à ajouter dans votre page

```yaml
↓Style [ngx.components.UIStyle-XXXXX]: 
  styleContent: 
    - xmlizable: 
      - ↑classname: com.twinsoft.convertigo.beans.common.FormatedContent
      - com.twinsoft.convertigo.beans.common.FormatedContent: 
        →: |
          '.main-content {
            flex: 1;
            padding: 40px;
            overflow-y: auto;
            background: #f8f9fa;
          }
          '
```

---

## ✨ Fonctionnalités automatiques

Avec `appLayout`, vous obtenez **automatiquement** :

1. **Sidebar de navigation** à gauche
   - Logo URSSAF
   - Boutons Accueil, Applications, Demandes, Paramètres
   - Icônes Chatbot, Notifications en bas
   - Profil utilisateur

2. **Section Formulaires**
   - S'ouvre/se ferme en cliquant sur l'icône "Applications"
   - Contient 3 catégories : Badge, Parking, Heures Supp
   - Accordéons expansibles

3. **Modal Chatbot**
   - S'ouvre en cliquant sur l'icône chatbot
   - Suggestions interactives
   - Champ de saisie

4. **Modal Notifications**
   - S'ouvre en cliquant sur l'icône notifications
   - Liste des notifications
   - Tabs : Toutes / Non lues / Archivées

5. **Sidebar Favoris** (à droite)
   - Toujours visible par défaut
   - Se réduit automatiquement sur petits écrans
   - Toggle manuel via bouton chevron

---

## 🎨 Personnalisation

### Modifier le contenu des formulaires

Éditez `appLayout.yaml`, section `formulairesSection` :

```yaml
↓category1 [ngx.components.UIElement-1762700700041]: 
  tagName: details
  # Modifiez ici pour ajouter/supprimer des catégories
```

### Ajuster les couleurs

Éditez le `↓Style` dans `appLayout.yaml` et modifiez les variables CSS :

```css
.formulaires-title {
  color: #1a428a;  /* Changez cette couleur */
}
```

### Désactiver un élément

Pour masquer un élément (par exemple la sidebar favoris), ajoutez dans le CSS de votre page :

```css
.favorites-sidebar {
  display: none !important;
}
```

---

## 📝 Exemples complets

### Page simple

```yaml
comment: Ma page simple avec layout
↓UseAppLayout [ngx.components.UIUseShared-1000000]: 
  sharedcomponent: EspaceUnifie_SIRH.Application.NgxApp.appLayout
↓mainContent [ngx.components.UIElement-1000001]: 
  tagName: main
  ↓Attr [ngx.components.UIAttribute-1000002]: 
    attrName: class
    attrValue: 
      - xmlizable: 
        - ↑classname: com.twinsoft.convertigo.beans.ngx.components.MobileSmartSourceType
        - MobileSmartSourceType: plain:main-content
  ↓h1 [ngx.components.UIElement-1000003]: 
    tagName: h1
    ↓Text [ngx.components.UIText-1000004]: 
      textValue: 
        - xmlizable: 
          - ↑classname: com.twinsoft.convertigo.beans.ngx.components.MobileSmartSourceType
          - MobileSmartSourceType: plain:Bienvenue
  ↓p [ngx.components.UIElement-1000005]: 
    tagName: p
    ↓Text [ngx.components.UIText-1000006]: 
      textValue: 
        - xmlizable: 
          - ↑classname: com.twinsoft.convertigo.beans.ngx.components.MobileSmartSourceType
          - MobileSmartSourceType: plain:Ceci est le contenu principal de ma page
↓UseFooter [ngx.components.UIUseShared-1000007]: 
  sharedcomponent: EspaceUnifie_SIRH.Application.NgxApp.footer
↓Style [ngx.components.UIStyle-1000008]: 
  styleContent: 
    - xmlizable: 
      - ↑classname: com.twinsoft.convertigo.beans.common.FormatedContent
      - com.twinsoft.convertigo.beans.common.FormatedContent: 
        →: |
          '.main-content {
            flex: 1;
            padding: 40px;
            overflow-y: auto;
            background: #f8f9fa;
          }
          
          .main-content h1 {
            font-family: "Montserrat", sans-serif;
            font-size: 32px;
            color: #1a428a;
          }
          '
```

---

## 🐛 Dépannage

### Les toggles ne fonctionnent pas

✅ Vérifiez que :
1. Le composant `appLayout` est bien utilisé **avant** votre contenu principal
2. Les IDs des checkboxes correspondent aux attributs `for` des labels
3. Il n'y a pas de conflit CSS avec d'autres styles

### Le layout ne s'affiche pas correctement

✅ Vérifiez que :
1. Tous les composants référencés existent (`navbar`, `chatbotModal`, etc.)
2. Il n'y a pas d'erreurs dans la console du navigateur
3. Le CSS est bien chargé

### La sidebar favoris ne se réduit pas

✅ Vérifiez que :
1. Le checkbox `favorites-toggle` est bien présent
2. Le CSS pour `.favorites-toggle:not(:checked)` est chargé
3. L'attribut `checked` est présent sur le checkbox

---

## 📚 Structure des fichiers

```
EspaceUnifie_SIRH/
  _c8oProject/
    mobileNgxApp.yaml              (Enregistrement des composants)
    mobileSharedComponents/
      appLayout.yaml               ✨ NOUVEAU - Layout principal
      favoris.yaml                 ✨ NOUVEAU - Sidebar favoris
      navbar.yaml                  Sidebar navigation
      chatbotModal.yaml            Modal chatbot
      notificationsModal.yaml      Modal notifications
      footer.yaml                  Footer
    mobilePages/
      VotrePage.yaml               Votre page utilisant appLayout
```

---

## 🎯 Conclusion

Le composant `appLayout` simplifie énormément la création de nouvelles pages :
- **Avant** : 1800+ lignes de YAML par page
- **Après** : ~50 lignes pour une page complète

Vous pouvez maintenant vous concentrer sur le **contenu** de vos pages plutôt que sur la structure ! 🚀

