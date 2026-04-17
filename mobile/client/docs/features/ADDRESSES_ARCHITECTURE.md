# Architecture Visuelle - Module Adresses

Ce document présente l'architecture du module Adresses avec des diagrammes visuels.

## 📊 Structure du Module

```mermaid
graph TB
    subgraph "Presentation Layer"
        A[addresses_list_page.dart]
        B[add_address_page.dart]
        C[edit_address_page.dart]
        D[address_card.dart]
        E[address_selector.dart]
        F[address_autocomplete_field.dart]
        G[addresses_notifier.dart]
    end
    
    subgraph "Domain Layer"
        H[address_entity.dart]
        I[address_repository.dart]
    end
    
    subgraph "Data Layer"
        J[address_repository_impl.dart]
        K[address_remote_datasource.dart]
        L[address_model.dart]
    end
    
    A --> D
    A --> G
    B --> E
    B --> F
    C --> E
    C --> F
    G --> I
    I --> J
    J --> K
    K --> L
    
    style A fill:#e1f5ff
    style D fill:#b3e5fc
    style G fill:#81d4fa
```

## 🔄 Flux de Données

### Chargement des adresses

```mermaid
sequenceDiagram
    participant UI as AddressesListPage
    participant Provider as AddressesNotifier
    participant Repo as AddressRepository
    participant API as RemoteDataSource
    
    UI->>Provider: loadAddresses()
    Provider->>Provider: state.isLoading = true
    Provider->>Repo: getAddresses()
    Repo->>API: GET /api/addresses
    API-->>Repo: List<AddressModel>
    Repo-->>Provider: List<AddressEntity>
    Provider->>Provider: state.addresses = data
    Provider->>Provider: state.isLoading = false
    Provider-->>UI: Notify listeners
    UI->>UI: Rebuild with data
```

### Suppression d'adresse (avec confirmation)

```mermaid
sequenceDiagram
    participant User
    participant Card as AddressCard
    participant Dialog as ConfirmDialog
    participant Page as AddressesListPage
    participant Provider as AddressesNotifier
    participant API as API
    
    User->>Card: Swipe left
    Card->>Dialog: Show confirm dialog
    User->>Dialog: Tap "Supprimer"
    Dialog-->>Card: Return true
    Card->>Page: onDelete()
    Page->>Provider: deleteAddress(id)
    Provider->>API: DELETE /api/addresses/:id
    API-->>Provider: Success
    Provider->>Provider: Remove from state
    Provider-->>Page: Notify
    Page->>Page: Show SnackBar
    Page->>Page: Rebuild list
```

## 🏗️ Architecture Avant vs Après

### Avant (v1.0.0)

```mermaid
graph LR
    A[AddressesListPage] --> B[_AddressCard Widget intégré]
    A --> C[Logique inline]
    A --> D[State Management basique]
    
    style A fill:#ffcdd2
    style B fill:#ffcdd2
```

**Problèmes** :
- Widget non réutilisable
- Difficile à tester
- Code dupliqué
- Pas d'animations
- UX limitée

### Après (v2.0.0)

```mermaid
graph LR
    A[AddressesListPage] --> B[AddressCard Widget réutilisable]
    A --> C[Handler methods dédiées]
    A --> D[Animation Controller]
    B --> E[Swipe-to-delete]
    B --> F[Rich UI]
    B --> G[Tests unitaires]
    
    style A fill:#c8e6c9
    style B fill:#c8e6c9
    style G fill:#81c784
```

**Avantages** :
- Widget réutilisable partout
- Hautement testable
- Code maintenable
- Animations fluides
- UX moderne

## 🎨 Composants du Widget AddressCard

```mermaid
graph TD
    A[AddressCard] --> B[Dismissible Wrapper]
    B --> C[Card Container]
    C --> D[InkWell Clickable]
    D --> E[Padding]
    E --> F[Header Section]
    E --> G[Address Details]
    E --> H[Optional Details]
    
    F --> F1[Icon Container]
    F --> F2[Label & Badge]
    F --> F3[GPS Indicator]
    F --> F4[Actions Menu]
    
    G --> G1[Address Icon + Text]
    G --> G2[City Icon + Text]
    
    H --> H1[Phone Icon + Text]
    H --> H2[Instructions Icon + Text]
    
    style A fill:#e3f2fd
    style F fill:#bbdefb
    style G fill:#90caf9
    style H fill:#64b5f6
```

## 📱 États de l'Interface

```mermaid
stateDiagram-v2
    [*] --> Init
    Init --> Loading: loadAddresses()
    Loading --> Data: Success
    Loading --> Error: API Error
    Loading --> Empty: No data
    
    Data --> Loading: Pull to Refresh
    Error --> Loading: Retry
    Empty --> AddAddress: Tap "Ajouter"
    
    Data --> Searching: Tap Search (if >3 items)
    Searching --> Data: Close search
    
    Data --> Deleting: Swipe item
    Deleting --> ConfirmDialog: Show dialog
    ConfirmDialog --> Data: Cancel
    ConfirmDialog --> Deleted: Confirm
    Deleted --> Data: Remove item
    
    note right of Loading
        - Shows skeleton
        - Linear progress bar
    end note
    
    note right of Error
        - Error icon
        - Message
        - Retry button
    end note
    
    note right of Empty
        - Empty illustration
        - CTA button
    end note
    
    note right of Data
        - Animated list
        - Pull-to-refresh
        - Search available
    end note
```

## 🎬 Animation Timeline

```mermaid
gantt
    title Animation d'entrée progressive (Stagger Effect)
    dateFormat X
    axisFormat %Lms
    
    section Carte 1
    Fade In       :0, 150
    Slide In      :0, 150
    
    section Carte 2
    Fade In       :50, 200
    Slide In      :50, 200
    
    section Carte 3
    Fade In       :100, 250
    Slide In      :100, 250
    
    section Carte 4
    Fade In       :150, 300
    Slide In      :150, 300
```

**Configuration** :
```dart
Interval(
  (index / items.length) * 0.5,           // Start
  ((index + 1) / items.length) * 0.5 + 0.5, // End
  curve: Curves.easeOut,
)
```

## 🧪 Architecture de Test

```mermaid
graph TB
    subgraph "Test Files"
        A[address_card_test.dart]
        B[addresses_list_page_test.dart]
        C[addresses_notifier_test.dart]
    end
    
    subgraph "Test Types"
        D[Widget Tests]
        E[Integration Tests]
        F[Unit Tests]
    end
    
    A --> D
    B --> E
    C --> F
    
    D --> G[UI Rendering Tests]
    D --> H[Interaction Tests]
    D --> I[State Change Tests]
    
    E --> J[Page Navigation Tests]
    E --> K[Data Flow Tests]
    
    F --> L[Business Logic Tests]
    F --> M[State Management Tests]
    
    style A fill:#fff9c4
    style D fill:#fff59d
    style G fill:#ffee58
```

## 📋 Checklist de Qualité

```mermaid
graph LR
    A[Code Quality] --> B[✅ Widget Extraction]
    A --> C[✅ Separation of Concerns]
    A --> D[✅ Clean Architecture]
    
    E[UI/UX] --> F[✅ Modern Design]
    E --> G[✅ Animations]
    E --> H[✅ Feedback]
    
    I[Performance] --> J[✅ Keys]
    I --> K[✅ Dispose]
    I --> L[✅ Optimization]
    
    M[Testing] --> N[✅ Unit Tests]
    M --> O[✅ Widget Tests]
    M --> P[✅ >90% Coverage]
    
    Q[Documentation] --> R[✅ README]
    Q --> S[✅ Migration Guide]
    Q --> T[✅ Changelog]
    
    style B fill:#c8e6c9
    style C fill:#c8e6c9
    style D fill:#c8e6c9
    style F fill:#c8e6c9
    style G fill:#c8e6c9
    style H fill:#c8e6c9
    style J fill:#c8e6c9
    style K fill:#c8e6c9
    style L fill:#c8e6c9
    style N fill:#c8e6c9
    style O fill:#c8e6c9
    style P fill:#c8e6c9
    style R fill:#c8e6c9
    style S fill:#c8e6c9
    style T fill:#c8e6c9
```

## 🚀 Déploiement

### Processus de Release

```mermaid
graph LR
    A[Development] --> B[Code Review]
    B --> C[Tests CI]
    C --> D[Staging]
    D --> E[QA Testing]
    E --> F[Production]
    
    C --> |Failed| B
    E --> |Issues Found| A
    
    style F fill:#81c784
```

### Checklist de Release

- [ ] Tous les tests passent
- [ ] Code review approuvé
- [ ] Documentation à jour
- [ ] Changelog mis à jour
- [ ] Version bumpée
- [ ] Migration guide prêt
- [ ] Déployé en staging
- [ ] QA validé
- [ ] Prêt pour production

---

**Note** : Ces diagrammes sont générés avec Mermaid et peuvent être visualisés directement dans GitHub/GitLab.

Pour modifier les diagrammes :
1. Éditer ce fichier Markdown
2. Utiliser la syntaxe [Mermaid](https://mermaid.js.org/)
3. Prévisualiser dans votre éditeur Markdown

---

**Dernière mise à jour** : 9 avril 2026
**Maintenu par** : L'équipe Mobile DR-PHARMA
