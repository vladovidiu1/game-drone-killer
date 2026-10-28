# Reclame: starea versiunii 0.1.2

Pluginul nativ Poing AdMob 5.1.0 și bridge-ul exact pentru Godot 4.6.3 sunt integrate. Contul AdMob și unitatea recompensată au fost create; identificatorii furnizați de proprietar sunt acum configurați astfel:

| Setare | Valoare / stare |
| --- | --- |
| App ID (JSON și `project.godot`) | `ca-app-pub-3787873725289108~4168159841` |
| Unitatea proprie, păstrată pentru viitor | `ca-app-pub-3787873725289108/8579720139` |
| Mod | `test` |
| Unitatea folosită de loader în TEST | `ca-app-pub-3940256099942544/5224354917` (Google) |
| Activare | `enabled=false` |
| Revizuire conformitate | `compliance_reviewed=false` |
| Public de vârstă | `unreviewed` |
| Politică de confidențialitate | URL necompletat |

ID-ul unității proprii este doar stocat; nu este folosit pentru cereri în modul TEST. `android_app_test_id` este un identificator demo vechi, neutilizat pentru metadata acestei aplicații; metadata Android folosește App ID-ul propriu din `project.godot`.

**Proiectul nu este încă pregătit pentru un AAB semnat care să afișeze reclame de test.** Poate fi construit, dar reclamele rămân blocate până la completarea cerințelor de mai jos. Semnarea nu înlocuiește configurarea confidențialității și nu activează reclamele. Nu s-a generat un AAB sau o versiune de publicitate de producție pentru această modificare.

Butonul informativ și întreaga campanie rămân disponibile offline. Recompensa rămâne 50 War Credits, maximum cinci recompense pe zi UTC și cooldown de 60 de secunde. Validarea callback-ului, protecția la duplicate și salvarea atomică sunt neschimbate.

## Ce mai trebuie configurat de proprietar

1. Publică o politică de confidențialitate reală, specifică aplicației, la un URL HTTPS accesibil public. Include operatorul/contactul real, stocarea locală, Google Mobile Ads/UMP, datele SDK și opțiunile aplicabile. Trimite URL-ul real pentru `privacy_policy_url`; draftul din repository nu este o politică publicată.
2. Confirmă publicul de vârstă efectiv și declarația din Play Console. Implementarea actuală acceptă numai un public exclusiv adult, revizuit. `reviewed_adult_only` nu poate fi selectat doar pentru a debloca un test. Pentru copii sau public mixt sunt necesare implementări suplimentare pentru vârstă, tag-uri și politicile aplicabile înainte de inițializare.
3. În AdMob → **Privacy & messaging**, configurează și publică mesajele aplicabile pentru aplicația cu App ID-ul propriu de mai sus: de exemplu reglementările europene pentru distribuția în SEE/Regatul Unit/Elveția și mesajele pentru statele SUA, dacă se aplică. Verifică politica și declarațiile Play Console (Target audience, Data safety, Contains ads) pentru integrarea efectivă. ID-urile singure nu creează aceste mesaje.
4. După confirmarea configurației reale, efectuează revizuirea de conformitate; abia apoi se pot seta `compliance_reviewed=true`, publicul confirmat și `enabled=true`, păstrând `mode="test"`. În această modificare nu s-a marcat nimic ca revizuit și nu s-a presupus un public adult.
5. Construiește și semnează un AAB de test cu un `versionCode` mai mare decât orice cod deja încărcat în Play Console. Testează pe Android UMP (obligatoriu/nereușit/închis), încărcarea reclamei oficiale de test, finalizarea versus închiderea fără recompensă, exact un credit de 50 WC, restartul și limitele. O eroare UMP trebuie să blocheze inițializarea/încărcarea, nu să fie ignorată.

Modul rămâne TEST; această sarcină nu activează publicitate de producție. Nu trebuie folosit ID-ul unității proprii pentru cereri în timpul acestor teste.

Cele două ID-uri sunt identificatori publici, nu parole. Nu trimite chei de cont sau parola cheii de semnare. Activarea necesită un nou build cu setările proprii; semnarea singură nu configurează AdMob.

## Configurarea în proiect după existența contului

- `data/advertising.json`: `enabled`, `mode` (`test`/`production`), `android_app_id`, `android_rewarded_id`, `privacy_policy_url`, `compliance_reviewed` și publicul de vârstă efectiv. Implementarea actuală acceptă doar cazul revizuit `reviewed_adult_only`; nu selecta această valoare pentru un joc destinat copiilor sau publicului mixt fără implementarea suplimentară necesară.
- `project.godot`: `admob/general/android/app_id` trebuie să coincidă cu App ID din JSON. Metadata din manifest se generează din această setare.
- În `test` se folosește întotdeauna unitatea Google `ca-app-pub-3940256099942544/5224354917`. În `production`, lipsa unității proprii sau utilizarea unității demo blochează cererile.
- SDK-ul nu este inițializat și nu încarcă reclame prin manager la pornire. Numai o cerere voluntară eligibilă poate declanșa UMP → configurare → inițializare → încărcare. O eroare sau un consimțământ nerezolvat nu este ocolit.
- Callback-ul de recompensă rămâne singura sursă de credit. Închiderea, reluarea aplicației și ecranul informativ nu acordă nimic. Jurnalul, idempotenta, limita zilnică și salvarea atomică sunt păstrate; nu există încă validare SSV pe un server.

## Build repetabil și proveniență

`python3 tools/setup_android.py` include `tools/setup_admob.py`. Acesta verifică SHA-256 publicat de GitHub pentru arhiva oficială `android-template-v4.6.3.zip` a Poing 5.1.0 și instalează doar patru AAR-uri bridge (debug/release, ads/core) în directorul ignorat de Git. Nu folosește fallback-ul Godot 4.7.0 și nu descarcă iOS sau medieri.

`addons/admob/PROVENANCE.json` și `LICENSE` documentează sursa MIT. Runtime-ul GDScript este vendorizat; fabrica implicită de reclame false din editor este dezactivată. Exporterul propriu nu modifică setările proiectului și nu descarcă nimic din editor. Aplică numai configurația Gradle Next-Gen documentată de upstream în șablonul Android generat/ignorat.

Google Mobile Ads/UMP au termeni și obligații de declarare separate. Verificarea AAB și testele cu dubluri nu constituie dovada afișării unei reclame reale pe Android.

## Validarea acestei configurări

- Suita completă `./tests/run_checks.sh` a trecut, inclusiv campania completă, verificarea salvării într-un proces nou și comparațiile de luptă.
- Importul Godot și testele direcționate pentru recompense, recuperare, UMP/callback-uri și meniul informativ au trecut: 97 + 6 + 21 + 23 + 3 verificări, fără erori.
- Testul folosește adapterul real cu o dublură SDK care înregistrează argumentul efectiv al loaderului: în TEST primește doar unitatea Google, nu unitatea de producție stocată. Un test negativ setează activarea numai în memorie și confirmă că lipsa revizuirii confidențialității împiedică inițializarea și încărcarea.
- Un proiect editor izolat a executat exporterul Android și a confirmat că metadata `com.google.android.gms.ads.APPLICATION_ID` folosește App ID-ul propriu din setarea proiectului și JSON. Nu s-a construit un AAB pentru această verificare.
- AAR-urile bridge pentru Godot 4.6.3 au fost verificate prin checksum. Testele cu dubluri și verificarea metadata nu confirmă configurarea consolei AdMob, mesajele UMP de pe server sau afișarea efectivă pe un telefon.
- Nu s-au modificat gameplay-ul, economia, pachetul sau campania. `export_presets.cfg` și versiunile de build sunt neschimbate; înaintea unei noi încărcări în Play trebuie ales un `versionCode` mai mare decât ultimul încărcat.
