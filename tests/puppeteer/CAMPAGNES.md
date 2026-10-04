# Parcours regroupés — Operation Artemis

Plans préparés le 4 octobre 2026 et installés sous `C:/Users/cyber/Zomboid/Lua/PZPuppet/scenarios/OperationArtemis/`. **Le lot passeur est terminé en jeu : 13 scénarios réussis, 1 chapitre optionnel ignoré, zéro nouvelle erreur Lua depuis son départ.** Le lot de rechargement de fin B a aussi réussi après fermeture complète. La fin A, Continuer puis référence31 sont confirmés ; le rechargement complet de cette fin A reste à faire. Les plans hélicoptère/checkpoint ne sont pas déduits des anciens scénarios individuels réussis.

**Incident historique conservé :** premier lot de rechargement échoué sur la garde `loadScenario`, puis correction et reprise individuelle. Après fermeture complète, nouveau lot `1791117606684-1` réellement `passed`, rapport/ACK confirmés. [Preuves de l’échec puis des réussites](reports/ENGINE-BATCH-20261004.md). La nouvelle campagne passeur utilise le moteur corrigé.

| Plan | Préconditions | Commande | Attendu | Observé | Preuve | Statut |
|---|---|---|---|---|---|---|
| Route passeur | Partie neuvePZPuppet_Artemis_Passeur, moteur/mod redémarrés, collecteur actif | `PZPuppet.runBatchFile("OperationArtemis/campagne_route.lua",{playerIndex=0},{route="passeur"})` | Enquête réelle, refus radio, générateur coupé, fin A puis référence | 13 scénarios passés,20 ignoré car Tikitown inactif ; rapports/ACK et lot final `passed`,0 nouvelle erreur Lua | [Bilan et13 preuves](reports/PASSEUR-20261004.md) | réussi |
| Route hélicoptère | Autre nouvelle partie dédiée, mêmes conditions | `PZPuppet.runBatchFile("OperationArtemis/campagne_route.lua",{playerIndex=0},{route="helicoptere"})` | Enquête réelle, refus radio, appel accepté, fin B puis référence | Plan contrôlé hors jeu ; anciens 09/10 réussis séparément | [Vérification de préparation](reports/inspection/batch-validation-20261004.json) | non exécuté |
| Route checkpoint | Autre nouvelle partie dédiée, sans Vaccine, mortalité non instantanée pour 26 | `PZPuppet.runBatchFile("OperationArtemis/campagne_route.lua",{playerIndex=0},{route="checkpoint"})` | Enquête, refus, quarantaine naturelle ≤ 1 h de jeu, fin C puis référence | Plan contrôlé hors jeu ; anciens 13/14 réussis séparément | [Vérification de préparation](reports/inspection/batch-validation-20261004.json) | non exécuté |
| Rechargement — tentative avant correctif moteur | Référence 31, même partie rechargée après retour au menu, collecteur actif | `PZPuppet.runBatchFile("OperationArtemis/campagne_rechargement.lua",{playerIndex=0})` | Construction puis assertions 25 | Garde moteur refuse le wrapper avant les actions ; 25 individuel réussit ensuite ses 7 assertions | [Incident réel](reports/ENGINE-BATCH-20261004.md) | échoué |
| Rechargement — moteur corrigé, fin B | Référence31, même sauvegarde après fermeture complète, nouveau PID5668, collecteur actif | `PZPuppet.runBatchFile("OperationArtemis/campagne_rechargement.lua",{playerIndex=0})` | Données conservées après arrêt complet, wrapper chargé, rapport/ACK/lot terminés | 7 assertions, 0 nouvelle erreur Lua depuis départ du lot, archive vérifiée et lot final `passed` | [Rapport et procédure réelle](reports/25_sauvegarde_rechargee.md) | réussi |

Le moteur passe automatiquement au prochain scénario après nettoyage, rapport distinct et confirmation du collecteur. Une erreur Lua, une assertion fausse ou une annulation arrête le plan. Les objectifs restent atteints par les actions du jeu ; aucun chapitre ni minuteur de quarantaine n’est terminé par debug. Les préparations locales des anciens scénarios sont conservées, avec leurs limites de couverture détaillées dans le [README](README.md).

## Terminer la vérification de la fin B en cours

Sur `PZPuppet_Artemis_Helicoptere`, où 10 a réellement réussi et Continuer a été cliqué :

```lua
PZPuppet.runFile("OperationArtemis/31_reference_rechargement.lua",{playerIndex=0})
```

Après le rapport, sauvegarder en quittant la partie par le jeu, fermer complètement Project Zomboid, puis le relancer et charger **cette même partie**. Le redémarrage charge aussi le nouveau moteur et les correctifs radio/Miller. Exécuter :

```lua
PZPuppet.runBatchFile("OperationArtemis/campagne_rechargement.lua",{playerIndex=0})
```

Ce plan contient 25 uniquement : état réel de la fin, choix Continuer, dossier, chapitre et révision après chargement. Le collecteur doit être actif avant chaque commande. Les scripts ne créent, ne remplacent et n’éditent aucun fichier de sauvegarde. La reprise de partie est humaine ; le rapport ne prouve pas à lui seul la fermeture du processus.

## Nouvelle partie passeur : une commande

Créer une partie dédiée neuve `PZPuppet_Artemis_Passeur`, solo `-debug`, Build 42.21, après le redémarrage complet. Activer Artemis, SignalSmoke et PZPuppeteer locaux, sans bateau ni Military Drop ni Vaccine, stérilisation désactivée, courant présent. Personnage vivant, lettré, non sourd, hors véhicule, actions instantanées désactivées. Les autres conditions figurent dans le README et sont vérifiées par les scénarios. Une ancienne partie avec Miller déjà marqué posé est refusée honnêtement.

Avant le lancement, utiliser **un seul** collecteur :

```powershell
python C:/Users/cyber/Zomboid/Workshop/OperationArtemis/tests/puppeteer/collect_results.py --watch
```

Console Lua :

```lua
PZPuppet.runBatchFile("OperationArtemis/campagne_route.lua",{playerIndex=0},{route="passeur"})
```

Fermer la console et reprendre à vitesse normale. Ordre : **01 → 02 → 03 → 04 → 05 → 20 si réellement révélé → 06 → 07 → 08 → 17 → 27 → 11 → 12 → 31**. Le 27 dépose et reprend le vrai dossier. Le 11 teste le refus sous projecteurs, coupe réellement le générateur, puis appelle ; le 12 attend la tenue du rendez-vous et la fin A. Cliquer **Continuer** au panneau final pour permettre 12 puis 31. Observer au 05 la lisibilité du texte radio ; ses assertions contrôlent désormais la présence physique de Miller avant son registre.

Les attentes de la bande et des rendez-vous restent celles du jeu. Le collecteur répond sans intervention humaine entre les scénarios ; ne pas coller plusieurs `runFile`. La tenue configurée de 30 minutes de jeu correspond environ à 75/112,5 secondes réelles à jour de 60/90 minutes. La marche et les autres actions s’ajoutent. Aucun saut de temps pendant l’objectif. L’option `manualStop=false` des fins permet au joueur d’agir pendant les attentes ; les scénarios précédents conservent la protection par défaut contre l’interruption manuelle.

Si le jeu attribue un nom automatique à la **nouvelle partie de test**, transmettre ce nom exact dans les paramètres du plan : `{route="passeur",testSave="<nom exact>"}`. Ne jamais désigner une partie personnelle. Chaque enfant reçoit ce nom ; aucune sauvegarde n’est renommée.

Après 31, sauvegarder et redémarrer entièrement, puis charger la même partie et lancer `campagne_rechargement.lua` pour la persistance de la fin A.

## Autres routes et branches

Ces commandes partent chacune d’une autre partie neuve avec les mêmes préconditions :

```lua
PZPuppet.runBatchFile("OperationArtemis/campagne_route.lua",{playerIndex=0},{route="helicoptere"})
PZPuppet.runBatchFile("OperationArtemis/campagne_route.lua",{playerIndex=0},{route="checkpoint"})
```

L’hélicoptère termine par 09/10 ; le checkpoint par 13/14. Pour le checkpoint, 26 prépare temporairement une infection corporelle, teste le vrai refus puis restaure cet état dans `finally` ; cette préparation est exclue du nominal. Les trois plans incluent 17 et 27 par défaut. `{route="checkpoint",negatives=false}` produit un parcours nominal sans ces cas négatifs ni la fixture infectée.

Le rendez-vous hélicoptère manqué reste une extension explicite : `{route="helicoptere",missedRendezvous=true}` ajoute 18 avant 10. Il attend réellement le départ et allonge le parcours ; aucun délai n’est artificiellement expiré. Les fins sont exclusives : leur regroupement dans une seule sauvegarde impliquerait de réinitialiser la progression, ce que ces plans ne font pas.

Bateaux pilotés, autorisation expirée, abandon, sans dossier, remède, stérilisation d’une journée, intégrations optionnelles et multijoueur conservent leurs scénarios/procédures distincts. Le plan nominal ne les marque pas réussis. Les paramètres et préconditions sont dans le [tableau complet](RESULTATS.md). Visuel/audio, mort et carte de Miller, virtualisation, accès naturel complet aux lieux et persistance exhaustive restent des vérifications séparées.

En cas d’arrêt, consulter le dernier rapport et les erreurs avant de poursuivre. Les cas suivants sont non exécutés. Une reprise doit tenir compte des acquisitions réelles déjà effectuées et citer les tentatives précédentes ; ne pas recommencer aveuglément le plan depuis 01 sur une partie avancée.

Pour consulter ou arrêter l’enchaînement : `PZPuppet.batchStatus()`, `PZPuppet.printStatus()`, `PZPuppet.stopBatch()`. L’[index des preuves](reports/README.md) et le [bilan des bugs](reports/BUGS.md) restent les points d’entrée. La validation hors jeu des plans et du collecteur est réalisée par `test_campaign.py` ; ce contrôle ne joue aucun objectif Artemis.
