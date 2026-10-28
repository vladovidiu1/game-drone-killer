# Reclame: starea versiunii 0.1.2

Pluginul nativ Poing AdMob 5.1.0 și bridge-ul exact pentru Godot 4.6.3 sunt integrate în build. Jocul nu are încă un cont AdMob, ID-uri proprii, public de vârstă confirmat sau o politică de confidențialitate publicată. Prin urmare, `data/advertising.json` rămâne `enabled=false`, `mode="disabled"`. AAB-ul nu poate produce venituri din reclame în această configurație.

Butonul din joc deschide acum o explicație, în loc să fie dezactivat fără context. Nu afișează reclame simulate și nu acordă War Credits pentru simpla apăsare. Campania rămâne disponibilă offline.

## Ce trebuie să facă proprietarul

1. Creează un cont la https://admob.google.com/ și adaugă aplicația Android `com.vladovidiu.dronekiller`.
2. Copiază **App ID**, de forma `ca-app-pub-…~…`.
3. Creează o unitate **Rewarded** și copiază **Ad unit ID**, de forma `ca-app-pub-…/…`.
4. Publică politica reală de confidențialitate, confirmă publicul de vârstă corect și configurează mesajele aplicabile în **Privacy & messaging**. Exemplul Google App ID nu poate găzdui mesajele de consimțământ ale proprietarului.
5. Folosește întâi integrarea în modul `test`, cu App ID propriu și unitatea recompensată oficială de test Google. Testează consimțământul, închiderea fără recompensă și finalizarea pe un telefon real.
6. Pentru venituri, treci la `production` cu unitatea proprie, după verificarea configurației și a declarațiilor Play Console. Reclamele de test nu aduc venituri.

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
